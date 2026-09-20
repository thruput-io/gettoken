#!/bin/bash
set -euo pipefail

install_command=$(sed -n 's/^export INSTALL_COMMAND = //p' config.sh)

sh -ec "$install_command make"

echo "ok: make is here, and can read the rest of config.sh"
