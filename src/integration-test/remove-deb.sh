#!/usr/bin/env bash
set -euo pipefail

apt-get purge -y gettoken-secret-manager
test ! -e /var/lib/gettoken
