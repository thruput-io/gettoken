#!/usr/bin/env bash
set -euo pipefail

control=${1:?apt-depends-for.sh: name the debian/control file to read}
package=${2:?apt-depends-for.sh: name the package whose Depends to print}

awk -v want="$package" '
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
      if (pkg == want && tok ~ /^(gettoken|integration-test-tool)/) print tok
    }
  }
' "$control"
