#!/usr/bin/env bash
set -euo pipefail

site_apt=${1:?package.sh: name the apt site dir}
branch=${2:?package.sh: name the branch}
site_url=${3:?package.sh: name the site url}
key_asc=${4:?package.sh: name the signing key asc}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

for fmt in ${PACKAGE_FORMATS:?package.sh: name the PACKAGE_FORMATS to build}; do
  case "$fmt" in
    deb)
      bash "$root/scripts/deliver-deb.sh" "$root/build/dist/deb"
      bash "$root/scripts/archive.sh" "$root/build/dist/deb" "$site_apt" "$branch" "$key_asc"
      bash "$root/scripts/sources.sh" "$site_apt" "$branch" "$site_url/apt"
      ;;
    brew)
      site_brew="$(dirname "$site_apt")/brew"
      bash "$root/scripts/deliver-brew.sh" "$root/build/dist/brew"
      bash "$root/scripts/archive-brew.sh" "$root/build/dist/brew" "$site_brew"
      ;;
    *)
      echo "package.sh: no packaging for format '$fmt'" >&2
      exit 1
      ;;
  esac
done
