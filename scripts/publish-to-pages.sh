#!/bin/bash
set -euo pipefail

branch=${1:?publish-to-pages.sh: name the branch the site is served from}
at=${2:?publish-to-pages.sh: name the path under the site to publish at}
what=${3:?publish-to-pages.sh: name the directory to publish}

what=$(CDPATH='' cd "$what" && pwd)

site=$(mktemp -d)
rmdir "$site"
trap 'git worktree remove --force "$site"' EXIT

git fetch --quiet origin "$branch"
git worktree add --quiet "$site" "origin/$branch" --detach

mkdir -p "$site/$at"
cp -a "$what/." "$site/$at"
touch "$site/.nojekyll"

git -C "$site" add --all
git -C "$site" commit --quiet --message "publish $at"
git -C "$site" push --quiet origin "HEAD:$branch"

echo "published $(find "$what" -type f | wc -l | tr -d ' ') files to $branch at $at"
