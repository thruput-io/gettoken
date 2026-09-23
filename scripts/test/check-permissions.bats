setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  tmp_dir=$(mktemp -d)
}

teardown() {
  rm -rf "$tmp_dir"
}

@test "check-permissions passes for valid permissions" {
  mkdir -p "$tmp_dir/dir"
  printf '#!/bin/bash\necho ok\n' > "$tmp_dir/dir/script.sh"
  chmod 775 "$tmp_dir/dir/script.sh"
  printf 'data\n' > "$tmp_dir/dir/file.txt"
  chmod 664 "$tmp_dir/dir/file.txt"

  run bash "$root/scripts/check-permissions.sh" "$tmp_dir/dir"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "check-permissions: 0 issues" ]]
}

@test "check-permissions fails when shebang script is not executable" {
  mkdir -p "$tmp_dir/dir"
  printf '#!/bin/bash\necho ok\n' > "$tmp_dir/dir/script.sh"
  chmod 664 "$tmp_dir/dir/script.sh"

  run bash "$root/scripts/check-permissions.sh" "$tmp_dir/dir"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "check-permissions: $tmp_dir/dir/script.sh has shebang but is not executable" ]]
}
