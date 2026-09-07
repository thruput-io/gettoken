#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/../.." && pwd)
contracts="$root/contracts"
fixtures="$root/exploratory/validators/fixtures"
request="$contracts/request.schema.json"

validate_jv()      { jv -m "https://thruput.io/gettoken/=$contracts" "$request" "$1" > /dev/null 2>&1; }
validate_perl()    { json-schema-eval --add-schema "$contracts/defs.schema.json" --schema "$request" --data "$1" > /dev/null 2>&1; }
validate_php()     { validate-json "$1" "$request" > /dev/null 2>&1; }
validate_python()  { jsonschema -i "$1" "$request" > /dev/null 2>&1; }

validate_jv_stdin()     { jv -m "https://thruput.io/gettoken/=$contracts" "$request" /dev/stdin < "$1" > /dev/null 2>&1; }
validate_perl_stdin()   { json-schema-eval --add-schema "$contracts/defs.schema.json" --schema "$request" --data /dev/stdin < "$1" > /dev/null 2>&1; }
validate_php_stdin()    { validate-json /dev/stdin "$request" < "$1" > /dev/null 2>&1; }
validate_python_stdin() { jsonschema "$request" < "$1" > /dev/null 2>&1; }

dialect_jv()     { jv "$fixtures/dialect.schema.json" "$fixtures/wrong-dialect.json" > /dev/null 2>&1; }
dialect_perl()   { json-schema-eval --schema "$fixtures/dialect.schema.json" --data "$fixtures/wrong-dialect.json" > /dev/null 2>&1; }
dialect_php()    { validate-json "$fixtures/wrong-dialect.json" "$fixtures/dialect.schema.json" > /dev/null 2>&1; }
dialect_python() { jsonschema -i "$fixtures/wrong-dialect.json" "$fixtures/dialect.schema.json" > /dev/null 2>&1; }

bin_for() {
  case $1 in
    jv) echo jv ;; perl) echo json-schema-eval ;;
    php) echo validate-json ;; python) echo jsonschema ;;
  esac
}

package_for() {
  case $1 in
    jv) echo jsonschema-jv ;; perl) echo libjson-schema-modern-perl ;;
    php) echo php-json-schema ;; python) echo python3-jsonschema ;;
  esac
}

candidates="jv perl php python"
cases="valid:accept missing-wants:reject bad-capability:reject extra-field:reject malformed:reject empty:reject"

. /etc/os-release
echo "# $PRETTY_NAME"
echo "#"
echo "# Every candidate is installed with apt from this base, which is the criterion"
echo "# that put this comparison back on the table. The contracts are read as they"
echo "# are written: a candidate that cannot resolve the reference into"
echo "# defs.schema.json by itself is caught by bad-capability, which is malformed"
echo "# only according to a constraint that lives behind that reference."
echo

for v in $candidates; do
  echo "## $v — $(package_for "$v") — $(dpkg-query -W -f='${Version}' "$(package_for "$v")" 2>/dev/null || echo NOT INSTALLED)"

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

echo "# does it implement the dialect the contracts declare?"
echo "# wrong-dialect.json breaks dependentRequired, which is 2020-12 and nothing"
echo "# earlier. A candidate that accepts it is reading our contracts in a dialect"
echo "# they do not claim, and what else it silently ignores is unknown."
echo
for v in $candidates; do
  printf '  %-12s ' "$v"
  "dialect_$v" && got=0 || got=$?
  [ "$got" -eq 0 ] && echo "ACCEPTS IT — does not implement 2020-12" || echo "refuses it (exit $got)"
done

echo
echo "# can the document arrive on stdin?"
echo "# token-service reads its request from stdin; a validator that cannot forces"
echo "# the wrapper to write the document — token and all — to a file."
echo
for v in $candidates; do
  printf '  %-12s ' "$v"
  "validate_${v}_stdin" "$fixtures/valid.json" && ok=0 || ok=$?
  "validate_${v}_stdin" "$fixtures/malformed.json" && bad=0 || bad=$?
  if [ "$ok" -ne 0 ]; then echo "no stdin support"
  elif [ "$bad" -eq 0 ]; then echo "READS STDIN BUT FAILS OPEN — accepted malformed input, exit 0"
  else echo "reads stdin and fails closed"
  fi
done

echo
echo "# is a rejection told apart from a failure to read?"
echo "# a caller that cannot tell them apart cannot report which one happened."
echo
for v in $candidates; do
  printf '  %-12s ' "$v"
  "validate_$v" "$fixtures/missing-wants.json" && invalid=0 || invalid=$?
  "validate_$v" "$fixtures/malformed.json" && unreadable=0 || unreadable=$?
  printf 'invalid=%-4s unreadable=%-4s ' "$invalid" "$unreadable"
  [ "$invalid" = "$unreadable" ] && echo "SAME STATUS — cannot be told apart" || echo "told apart"
done
