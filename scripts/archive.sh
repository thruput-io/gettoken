# shellcheck shell=bash

apt_takes_this_source_or_stops() {
  source_line=$1
  archive=$2
  reported=$(mktemp)

  echo "$source_line" > /etc/apt/sources.list.d/gettoken.list
  apt-get update -o APT::Update::Error-Mode=any 2>&1 | tee "$reported"

  awk -v archive="$archive" '
    /^Err/ || /Read error/ || (/^W:/ && index($0, archive)) {
      print "the archive is not clean to apt: " $0 > "/dev/stderr"
      reported = 1
    }
    END { exit reported + 0 }
  ' "$reported"
}

apt_takes_the_archive_or_stops() {
  apt_takes_this_source_or_stops "deb [trusted=yes] file:$1 ./" "$1"
}

apt_takes_the_published_archive_or_stops() {
  keyring=/etc/apt/keyrings/gettoken-archive-keyring.gpg

  apt-get update
  apt-get install -y --no-install-recommends ca-certificates curl
  mkdir -p /etc/apt/keyrings
  curl --fail --silent --show-error --location \
    "$1/gettoken-archive-keyring.gpg" --output "$keyring"

  apt_takes_this_source_or_stops "deb [signed-by=$keyring] $1 ./" "$1"
}
