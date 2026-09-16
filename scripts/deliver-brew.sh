#!/bin/bash
set -euo pipefail

into=$1

if [ -z "$into" ]; then
  echo "deliver-brew.sh: no directory to deliver the formula into" >&2
  exit 1
fi

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

version=$(sed -n '1s/.*(\(.*\)).*/\1/p' src/debian/changelog)

cat > "$into/gettoken.rb" <<FORMULA
class Gettoken < Formula
  desc "Token broker for AI agents"
  homepage "https://github.com/thruput-io/gettoken"
  version "$version"
  url "https://github.com/thruput-io/gettoken/archive/refs/tags/$version.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"src/tools/gettoken/bin/gettoken"
  end

  test do
    system bin/"gettoken"
  end
end
FORMULA

echo "TODO: this formula is a placeholder. The url and sha256 name no release," \
     "nothing is built from source, and the bottle is never produced." \
     > "$into/gettoken.rb.todo"

echo "wrote a placeholder formula for $version in $into, see gettoken.rb.todo"
