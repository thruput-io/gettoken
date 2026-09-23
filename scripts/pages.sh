#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

pages_branch=gh-pages
pages_served_from=docs

pages_open() {
  git ls-remote --exit-code --heads origin "$pages_branch" > /dev/null
  git fetch --quiet origin "$pages_branch"
  pages_work=$(mktemp -d)
  pages_root=$pages_work/site
  git worktree add --quiet --detach "$pages_root" "origin/$pages_branch"
  pages=$pages_root/$pages_served_from
  mkdir -p "$pages"
}

pages_close() {
  git worktree remove --force "$pages_root"
  rm -rf "$pages_work"
}

pages_push() {
  git -C "$pages_root" add --all
  git -C "$pages_root" -c user.name='gettoken archive' \
      -c user.email='johan.granlund@thruput.se' \
      commit --quiet --message "$1"
  local i=0
  until git -C "$pages_root" push --quiet origin "HEAD:$pages_branch"; do
    i=$((i + 1))
    if [ "$i" -ge 5 ]; then
      echo "Error: failed to push gh-pages after 5 attempts" >&2
      return 1
    fi
    sleep 3
  done
  echo "$1"
}
