#!/usr/bin/env bash
set -euo pipefail

source=${1:?brew-formulae.sh: name the resolved source tree to generate formulae from}
cd "$source"

version=${VERSION:?brew-formulae.sh: VERSION must be set}

class_name() {
  awk -F- '{ out=""; for (i=1;i<=NF;i++) { s=$i; out = out toupper(substr(s,1,1)) substr(s,2) }; print out }' <<< "$1"
}

root=$(pwd)
top=$(basename "$root")
tarball_dir=$(mktemp -d)
tarball="$tarball_dir/gettoken-$version.tar.gz"
tar czf "$tarball" -C "$(dirname "$root")" "$top"
sha256=$(sha256sum < "$tarball" | cut -d' ' -f1)
url="file://$tarball"

mkdir -p Formula

depgraph=$(mktemp)
trap 'rm -f "$depgraph"' EXIT
awk '
  /^Package: / { pkg = $2 }
  /^Depends:/ {
    indep = 1
    line = $0
    sub(/^Depends: */, "", line)
    collect(line)
    next
  }
  indep && /^(Architecture|Description): / { indep = 0 }
  indep { collect($0) }
  function collect(s,    n, parts, i, tok) {
    n = split(s, parts, ",")
    for (i = 1; i <= n; i++) {
      tok = parts[i]
      gsub(/^[ \t]+|[ \t]+$/, "", tok)
      if (tok ~ /^(gettoken|integration-test-tool)/) print pkg, tok
    }
  }
' debian/control > "$depgraph"

package_depends() {
  awk -v p="$1" '$1 == p { print $2 }' "$depgraph"
}

install_line() {
  case "$2" in
    usr/bin)
      echo "    bin.install \"$1\""
      ;;
    usr/lib/gettoken)
      echo "    (lib/\"gettoken\").install \"$1\""
      ;;
    usr/lib/gettoken/exchangers)
      echo "    (lib/\"gettoken/exchangers\").install \"$1\""
      ;;
    usr/share/gettoken/contracts)
      echo "    (share/\"gettoken/contracts\").install \"$1\""
      ;;
    *)
      echo "brew-formulae.sh: unrecognized install destination '$2'" >&2
      exit 1
      ;;
  esac
}

for install in debian/*.install; do
  package=$(basename "$install" .install)
  class=$(class_name "$package")
  formula="Formula/$package.rb"

  {
    echo "class $class < Formula"
    echo "  desc \"Token broker for AI agents - $package\""
    echo "  homepage \"https://github.com/thruput-io/gettoken\""
    echo "  url \"$url\""
    echo "  version \"$version\""
    echo "  sha256 \"$sha256\""
    echo

    deps=$(package_depends "$package")
    if [ -n "$deps" ]; then
      echo "$deps" | while read -r dep; do
        echo "  depends_on \"$dep\""
      done
      echo
    fi

    echo "  def install"

    if grep -q '^build/bin/' "$install"; then
      echo "    system \"bash\", \"components/contract/build.sh\", \"build/bin\""
    fi

    while read -r src dest; do
      [ -n "$src" ] || continue
      install_line "$src" "$dest"
    done < "$install"

    echo "  end"
    echo
    echo "  test do"

    first_src=$(awk 'NR==1{print $1}' "$install")
    first_base=$(basename "$first_src")

    case "$package" in
      gettoken)
        echo "    system bin/\"gettoken\", \"--list\""
        ;;
      integration-test-tool)
        echo "    shell_output(\"#{bin}/integration-test-tool 2>&1\", 1)"
        ;;
      gettoken-contract-*)
        echo "    require \"json\""
        echo "    JSON.parse((share/\"gettoken/contracts/$first_base\").read)"
        ;;
      gettoken-parse | gettoken-format)
        echo "    shell_output(\"#{lib}/gettoken/$first_base nonexistent.schema.json 2>&1 </dev/null\", 1)"
        ;;
      *)
        echo "    shell_output(\"#{lib}/gettoken/$first_base 2>&1 </dev/null\", 1)"
        ;;
    esac

    echo "  end"
    echo "end"
  } > "$formula"
done

echo "generated $(find Formula -name '*.rb' | wc -l | tr -d ' ') formulae in Formula/"
