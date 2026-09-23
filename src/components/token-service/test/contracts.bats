bats_require_minimum_version 1.5.0

setup() {
  export BATS_LIB_PATH="/opt/homebrew/lib:/usr/local/lib:/usr/lib"
  bats_load_library bats-support 2>/dev/null || true
  bats_load_library bats-assert 2>/dev/null || true
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

assert_stderr_contains() {
  assert_regex "$stderr" "$1"
}

refute_stderr_contains() {
  refute_regex "$stderr" "$1"
}

admits() { printf '%s' "$2" | parse "$1"; }

requesting() {
  jq -nc --arg signed "$1" \
    '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}'
}

@test "a request whose signature is ordinary text is admitted" {
  run -0 --separate-stderr admits token-request.schema.json "$(requesting host-privileged)"
  refute_stderr_contains "does not satisfy"
}

@test "a request whose signature carries a control character is refused" {
  run -1 --separate-stderr admits token-request.schema.json "$(requesting "host$(printf '\001')privileged")"
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-request.schema.json"
}

@test "a request whose signature carries a delete character is refused" {
  run -1 --separate-stderr admits token-request.schema.json "$(requesting "host$(printf '\177')privileged")"
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-request.schema.json"
}

@test "a request whose signature ends in a newline is refused" {
  run -1 --separate-stderr admits token-request.schema.json \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:"host-privileged\n"}')"
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-request.schema.json"
}

@test "a capability ending in a newline is refused" {
  run -1 --separate-stderr admits token-request.schema.json \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run\n",signed:"host-privileged"}')"
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-request.schema.json"
}

@test "an agent name ending in a newline is refused" {
  run -1 --separate-stderr admits token-request.schema.json \
    "$(jq -nc '{who:"tore\n",doing:"mac.lan",wants:"integrationtest/ci/run",signed:"host-privileged"}')"
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-request.schema.json"
}

@test "a minute and a day are both admitted as lifetimes" {
  run -0 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":60}'
  refute_stderr_contains "does not satisfy"
  run -0 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":86400}'
  refute_stderr_contains "does not satisfy"
}

@test "a lifetime shorter than a minute is refused" {
  run -1 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":59}'
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-response.schema.json"
}

@test "a lifetime longer than a day is refused" {
  run -1 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":86401}'
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-response.schema.json"
}

@test "a response carrying a field the contract does not govern is refused" {
  run -1 --separate-stderr admits token-response.schema.json \
    '{"access_token":"narrow","expires_in":120,"wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy token-response.schema.json"
}

@test "an exchange request naming who is asking and what for is admitted" {
  run -0 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run"}'
  refute_stderr_contains "does not satisfy"
}

@test "an exchange request naming no agent is refused" {
  run -1 --separate-stderr admits exchange-request.schema.json '{"wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy exchange-request.schema.json"
}

@test "an exchange request does not carry the signature the request was signed with" {
  run -1 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run","signed":"host-privileged"}'
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy exchange-request.schema.json"
}

@test "an exchange request does not carry what the agent was doing" {
  run -1 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run","doing":"mac.lan"}'
  [ "$output" = "" ]
  assert_stderr_contains "does not satisfy exchange-request.schema.json"
}
