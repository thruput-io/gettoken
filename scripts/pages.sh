# shellcheck shell=bash

pages_branch=gh-pages

pages_open() {
  if ! git ls-remote --exit-code --heads origin "$pages_branch" > /dev/null; then
    echo "pages.sh: origin has no $pages_branch branch, and that is what the site serves" >&2
    exit 1
  fi

  git fetch --quiet origin "$pages_branch"
  pages_work=$(mktemp -d)
  pages=$pages_work/site
  git worktree add --quiet --detach "$pages" "origin/$pages_branch"
}

pages_close() {
  git worktree remove --force "$pages"
  rm -rf "$pages_work"
}

pages_push() {
  git -C "$pages" add --all
  git -C "$pages" -c user.name='gettoken archive' \
      -c user.email='johan.granlund@thruput.se' \
      commit --quiet --message "$1"
  git -C "$pages" push --quiet origin "HEAD:$pages_branch"
  echo "$1"
}
