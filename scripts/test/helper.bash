# shellcheck shell=bash
bats_load_library bats-support
bats_load_library bats-assert

without_kcov_trace() {
  printf '%s' "$1" | sed -E '/(k+cov@|^(wants|key|value|fields|asked|version|who|doing|signed)=)/d'
}
