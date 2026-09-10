# shellcheck shell=bash

apt_takes_the_archive_or_stops() {
  archive=$1
  reported=$(mktemp)

  echo "deb [trusted=yes] file:$archive ./" > /etc/apt/sources.list.d/gettoken.list
  apt-get update -o APT::Update::Error-Mode=any 2>&1 | tee "$reported"

  awk -v archive="$archive" '
    /^Err/ || /Read error/ || (/^W:/ && index($0, archive)) {
      print "the archive is not clean to apt: " $0 > "/dev/stderr"
      reported = 1
    }
    END { exit reported + 0 }
  ' "$reported"
}
