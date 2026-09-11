# shellcheck shell=bash

# Sourced by whatever puts the archive in front of apt. The caller writes
# /etc/apt/sources.list.d/gettoken.sources first; this is the update that
# reads it, and it fails on anything apt reports about the archive rather
# than on the exit status alone, which apt keeps at zero for a warning.
apt_takes_the_archive_or_stops() {
  archive=$1
  reported=$(mktemp)

  apt-get update -o APT::Update::Error-Mode=any 2>&1 | tee "$reported"

  awk -v archive="$archive" '
    /^Err/ || /Read error/ || (/^W:/ && index($0, archive)) {
      print "the archive is not clean to apt: " $0 > "/dev/stderr"
      reported = 1
    }
    END { exit reported + 0 }
  ' "$reported"
}
