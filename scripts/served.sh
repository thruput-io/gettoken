#!/bin/bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: served.sh ARCHIVE DOCKER-ARGUMENT..." >&2
  exit 1
fi
archive=$1
shift

net=gettoken-archive-$$
server=gettoken-archive-server-$$

docker network create "$net" > /dev/null
trap 'docker network rm "$net" > /dev/null' EXIT

docker run --detach --name "$server" --network "$net" --network-alias archive \
  --volume "$archive:/srv:ro" busybox httpd -f -p 80 -h /srv > /dev/null
trap 'docker rm --force "$server" > /dev/null; docker network rm "$net" > /dev/null' EXIT

docker run --rm --network "$net" "$@"
