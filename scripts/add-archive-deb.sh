#!/usr/bin/env bash
set -euo pipefail

archive=${1:?add-archive-deb.sh: name the directory holding the apt archive}

printf 'Types: deb\nURIs: file:%s\nSuites: ./\nTrusted: yes\n' "$archive" > /etc/apt/sources.list.d/gettoken-dist.sources
