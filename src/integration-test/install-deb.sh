#!/usr/bin/env bash
set -euo pipefail

dist=${1:?install-deb.sh: name the directory the packages were delivered into}

bash -ec "${INSTALL_COMMAND:?install-deb.sh: name the INSTALL_COMMAND} $dist/deb/*.deb"
