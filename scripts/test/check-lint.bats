#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  tmp_dir=$(mktemp -d)
}

teardown() {
  rm -rf "$tmp_dir"
}

@test "check-lint passes for valid XML report matching thresholds" {
  cat <<'EOF' > "$tmp_dir/report.xml"
<?xml version="1.0" encoding="UTF-8"?>
<checkstyle version="4.3">
  <file name="foo.sh"></file>
</checkstyle>
EOF
  cat <<'EOF' > "$tmp_dir/thresholds.json"
{"lint": {"errors": 0, "warnings": 0}}
EOF

  run bash "$root/scripts/check-lint.sh" "$tmp_dir/report.xml" "$tmp_dir/thresholds.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "lint: 1 files, 0 errors" ]]
}
