#!/usr/bin/env bash
set -euo pipefail

tag=${1:?tag-release.sh: name the tag to cut and push}
repo=${2:?tag-release.sh: name the GitHub repo as owner/name that the archive is fetched from}
sha_out=${3:?tag-release.sh: name the file to write the fetched archive sha256 into}

git tag "$tag"
git push origin "$tag"

archive_url="https://github.com/$repo/archive/refs/tags/$tag.tar.gz"
archive=$(mktemp)
trap 'rm -f "$archive"' EXIT

attempt=0
max_attempts=6
until curl --fail --silent --show-error --location "$archive_url" --output "$archive"; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "tag-release.sh: $archive_url did not become fetchable after $max_attempts attempts" >&2
    exit 1
  fi
  sleep 5
done

mkdir -p "$(dirname "$sha_out")"
sha256sum < "$archive" | cut -d' ' -f1 > "$sha_out"

echo "tagged $tag, archive sha256 $(cat "$sha_out") written to $sha_out"
