#!/bin/bash
set -euo pipefail

container=$1
formulae=$2

running=$(docker inspect -f '{{.State.Running}}' "$container")
test "$running" = true

docker exec "$container" mkdir -p /usr/share/nginx/html/brew
docker cp "$formulae/." "$container:/usr/share/nginx/html/brew"

echo "brew: $(find "$formulae" -name '*.rb' | wc -l | tr -d ' ') formulae published to $container"
