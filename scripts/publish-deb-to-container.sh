#!/bin/bash
set -euo pipefail

container=$1
archive=$2

running=$(docker inspect -f '{{.State.Running}}' "$container")
test "$running" = true

docker exec "$container" mkdir -p /usr/share/nginx/html/deb
docker cp "$archive/." "$container:/usr/share/nginx/html/deb"

echo "deb: $(find "$archive" -name '*.deb' | wc -l | tr -d ' ') packages published to $container"
