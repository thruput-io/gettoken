# shellcheck shell=bash

the_site_path_of() {
  printf '%s\n' "$1" | sed -E 's#^https://[^/]+/[^/]+##; s#^/##; s#/$##'
}

the_key_this_run_signs_with() {
  GNUPGHOME=$(mktemp -d)
  export GNUPGHOME
  chmod 700 "$GNUPGHOME"
  printf '%s\n' "$ARCHIVE_SIGNING_KEY" | gpg --batch --quiet --import
  gpg --list-secret-keys --with-colons | awk -F: '/^fpr/ { print $10; exit }'
}

a_checkout_of_the_published_site() {
  site=$(mktemp -d)
  git clone --quiet --depth 1 --branch "$PAGES_BRANCH" \
    "$(git config --get remote.origin.url)" "$site"
  printf '%s\n' "$site"
}

the_site_keeps_what_jekyll_would_drop() {
  touch "$1/.nojekyll"
}

the_published_site_takes_it() {
  site=$1
  said=$2

  git -C "$site" add --all
  git -C "$site" \
    -c user.name="$PAGES_AUTHOR_NAME" \
    -c user.email="$PAGES_AUTHOR_EMAIL" \
    commit --quiet --message "$said"
  git -C "$site" \
    -c http.extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$PAGES_TOKEN" | base64 | tr -d '\n')" \
    push --quiet origin "HEAD:$PAGES_BRANCH" 2>&1 \
    | sed 's/[A-Za-z0-9+/=]\{40,\}/REDACTED/g'
}
