#!/bin/sh
set -eu

packages=$1
tag=$2

echo "deb [trusted=yes] file:$packages ./" > /etc/apt/sources.list.d/gettoken.list
apt-get update -qq
apt-get install -y --no-install-recommends integration-test-tool > /dev/null

echo "# does the official $tag image carry sudo?"
command -v sudo || echo "no"

echo
echo "# what installing sudo costs, in packages"
apt-get install -y --no-install-recommends sudo 2>&1 | sed -n 's/^\(0 upgraded.*\)$/\1/p'

echo
echo "# sudo secret-put, with the default sudoers and no PATH help"
printf '%s' '{"key":"host-privileged/integrationtest","value":"super-4f2a9c"}' \
  | sudo /usr/lib/gettoken/secret-put > /dev/null 2>&1 \
  && echo "worked" || echo "failed, exit $?"

echo
echo "# why: sudo resets the environment, so secret-put cannot find parse"
printf '%s' '{"key":"host-privileged/integrationtest","value":"super-4f2a9c"}' \
  | sudo /usr/lib/gettoken/secret-put 2>&1 >/dev/null | head -2

echo
echo "# with PATH carried across explicitly"
printf '%s' '{"key":"host-privileged/integrationtest","value":"super-4f2a9c"}' \
  | sudo PATH=/usr/lib/gettoken:/usr/bin:/bin /usr/lib/gettoken/secret-put > /dev/null 2>&1 \
  && echo "worked" || echo "failed, exit $?"

echo
echo "# and who sudo made us, on a base where the agent is already root"
sudo id -un
id -un
