#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/../.." && pwd)
defs="$root/contracts/defs.schema.json"
fixtures="$root/exploratory/validators/fixtures"
bundle=/tmp/request.bundled.json

sourcemeta-jsonschema bundle -r "$defs" "$root/contracts/request.schema.json" > "$bundle"

validate_sourcemeta() { sourcemeta-jsonschema validate "$bundle" "$1" > /dev/null 2>&1; }
validate_stranger()   { stranger-jsonschema validate "$bundle" -i "$1" > /dev/null 2>&1; }
validate_ajv()        { ajv validate --spec=draft2020 -s "$bundle" -d "$1" > /dev/null 2>&1; }
validate_python()     { python-jsonschema -i "$1" "$bundle" > /dev/null 2>&1; }
validate_check()      { check-jsonschema --schemafile "$bundle" "$1" > /dev/null 2>&1; }

validate_sourcemeta_stdin() { sourcemeta-jsonschema validate "$bundle" - < "$1" > /dev/null 2>&1; }
validate_stranger_stdin()   { stranger-jsonschema validate "$bundle" -i - < "$1" > /dev/null 2>&1; }
validate_ajv_stdin()        { ajv validate --spec=draft2020 -s "$bundle" -d - < "$1" > /dev/null 2>&1; }
validate_python_stdin()     { python-jsonschema "$bundle" < "$1" > /dev/null 2>&1; }
validate_check_stdin()      { check-jsonschema --schemafile "$bundle" - < "$1" > /dev/null 2>&1; }

bin_for() {
  case $1 in
    sourcemeta) echo sourcemeta-jsonschema ;; stranger) echo stranger-jsonschema ;;
    ajv) echo ajv ;; python) echo python-jsonschema ;; check) echo check-jsonschema ;;
  esac
}

cases="valid:accept missing-wants:reject bad-capability:reject extra-field:reject malformed:reject empty:reject"

. /etc/os-release
echo "# $PRETTY_NAME"
echo

for v in sourcemeta stranger ajv python check; do
  echo "## $v"
  command -v "$(bin_for $v)" > /dev/null 2>&1 || { echo "  NOT INSTALLED"; echo; continue; }

  control_ok=no
  failopen=""
  for c in $cases; do
    name=${c%:*}; want=${c#*:}
    "validate_$v" "$fixtures/$name.json" && got=0 || got=$?
    case "$want:$got" in
      accept:0) verdict=ok; control_ok=yes ;;
      accept:*) verdict="CONTROL REJECTED" ;;
      reject:0) verdict="FAIL-OPEN"; failopen="$failopen $name" ;;
      reject:*) verdict="ok (exit $got)" ;;
    esac
    printf '  %-16s want=%-6s exit=%-3s %s\n' "$name" "$want" "$got" "$verdict"
  done

  if [ "$control_ok" = no ]; then
    echo "  VERDICT: invocation not established — rejects a valid document, so its other results mean nothing"
  elif [ -n "$failopen" ]; then
    echo "  VERDICT: DISQUALIFIED — accepted documents it must reject:$failopen"
  else
    echo "  VERDICT: fails closed on every case"
  fi
  echo
done

echo "# can the document arrive on stdin?"
echo "# token-service reads its request from stdin; a validator that cannot forces"
echo "# the wrapper to write the document — token and all — to a file."
echo
for v in sourcemeta stranger ajv python check; do
  printf '  %-12s ' "$v"
  command -v "$(bin_for $v)" > /dev/null 2>&1 || { echo "not installed"; continue; }
  "validate_${v}_stdin" "$fixtures/valid.json" && ok=0 || ok=$?
  "validate_${v}_stdin" "$fixtures/malformed.json" && bad=0 || bad=$?
  if [ "$ok" -ne 0 ]; then echo "no stdin support"
  elif [ "$bad" -eq 0 ]; then echo "READS STDIN BUT FAILS OPEN — accepted malformed input, exit 0"
  else echo "reads stdin and fails closed"
  fi
done
