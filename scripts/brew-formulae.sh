#!/usr/bin/env bash
set -euo pipefail

source=${1:?brew-formulae.sh: name the source tree to read the packages from}
speaks=${2:?brew-formulae.sh: name the file saying what each package speaks}
into=${3:?brew-formulae.sh: name the directory to write the formulae into}
url=${4:?brew-formulae.sh: name the url the source tarball is fetched from}
sha256=${5:?brew-formulae.sh: name the sha256 of that tarball}
version=${VERSION:?brew-formulae.sh: name the VERSION}
tap=${BREW_TAP:?brew-formulae.sh: name the BREW_TAP the formulae depend on each other through}

speaks=$(CDPATH='' cd "$(dirname "$speaks")" && pwd)/$(basename "$speaks")
mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)
cd "$source"

class_name() {
  awk -F- '{ out = ""; for (i = 1; i <= NF; i++) out = out toupper(substr($i, 1, 1)) substr($i, 2); print out }' <<< "$1"
}

depends_of() {
  awk -v want="$1" '$1 == want { for (i = 2; i <= NF; i++) print $i }' "$speaks"
}

prefix_of() {
  case "$1" in
    usr/bin) echo 'bin' ;;
    usr/lib/gettoken) echo '(lib/"gettoken")' ;;
    usr/lib/gettoken/exchangers) echo '(lib/"gettoken/exchangers")' ;;
    usr/share/gettoken/contracts) echo '(share/"gettoken/contracts")' ;;
    *)
      echo "brew-formulae.sh: no brew prefix for install destination '$1'" >&2
      exit 1
      ;;
  esac
}

roots_in() {
  while read -r root brew; do
    if grep -qF "$root" "$1"; then
      printf '    inreplace "%s", "%s", "%s"\n' "$1" "$root" "$brew"
    fi
  done <<'ROOTS'
/usr/lib/gettoken #{HOMEBREW_PREFIX}/lib/gettoken
/usr/share/gettoken #{HOMEBREW_PREFIX}/share/gettoken
/var/lib/gettoken #{var}/gettoken
ROOTS
}

sources_of() {
  if grep -q '^build/bin/' "$1"; then
    echo components/contract/contract.go
  fi
  awk '$1 !~ /^build\// { print $1 }' "$1"
}

test_of() {
  case "$1" in
    gettoken-contract-*) printf '    require "json"\n    JSON.parse((share/"gettoken/contracts/%s").read)\n' "$2" ;;
    gettoken | integration-test-tool) printf '    shell_output("#{bin}/%s 2>&1 </dev/null", 1)\n' "$2" ;;
    integration-test-tool-exchanger) printf '    assert_predicate lib/"gettoken/exchangers/%s", :executable?\n' "$2" ;;
    *) printf '    assert_predicate lib/"gettoken/%s", :executable?\n' "$2" ;;
  esac
}

rm -f -- "$into"/*.rb

for install in debian/*.install; do
  package=$(basename "$install" .install)
  first=$(awk 'NR == 1 { n = split($1, p, "/"); print p[n] }' "$install")

  {
    printf 'class %s < Formula\n' "$(class_name "$package")"
    printf '  desc "Token broker for AI agents - %s"\n' "$package"
    printf '  homepage "https://github.com/thruput-io/gettoken"\n'
    printf '  url "%s"\n' "$url"
    printf '  sha256 "%s"\n' "$sha256"
    printf '  license "Apache-2.0"\n'

    depends=$(
      if grep -q '^build/bin/' "$install"; then
        printf '  depends_on "go" => :build\n'
      fi
      depends_of "$package" | while read -r dep; do
        printf '  depends_on "%s/%s"\n' "$tap" "$dep"
      done
    )
    if [ -n "$depends" ]; then
      printf '\n%s\n' "$depends"
    fi

    printf '\n  def install\n'
    sources_of "$install" | while read -r file; do
      roots_in "$file"
    done
    if grep -q '^build/bin/' "$install"; then
      printf '    system "bash", "components/contract/build.sh", "build/bin"\n'
    fi
    while read -r file destination; do
      printf '    %s.install "%s"\n' "$(prefix_of "$destination")" "$file"
    done < "$install"
    printf '  end\n\n'

    printf '  test do\n'
    test_of "$package" "$first"
    printf '  end\nend\n'
  } > "$into/$package.rb"
done
