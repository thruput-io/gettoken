#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  tmp_dir=$(mktemp -d)
}

teardown() {
  rm -rf "$tmp_dir"
}

@test "check-coverage succeeds when measured meets or exceeds threshold" {
  cat <<'EOF' > "$tmp_dir/report.json"
{"percent": 50}
EOF
  cat <<'EOF' > "$tmp_dir/thresholds.json"
{"test-cov": {"percent": 20}}
EOF

  run bash "$root/scripts/check-coverage.sh" "$tmp_dir/report.json" "$tmp_dir/thresholds.json" "test-cov"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "test-cov: 50% covered, floor 20%" ]]
}

@test "check-coverage fails when measured is below threshold" {
  cat <<'EOF' > "$tmp_dir/report.json"
{"percent": 10}
EOF
  cat <<'EOF' > "$tmp_dir/thresholds.json"
{"test-cov": {"percent": 20}}
EOF

  run bash "$root/scripts/check-coverage.sh" "$tmp_dir/report.json" "$tmp_dir/thresholds.json" "test-cov"
  [ "$status" -ne 0 ]
}
