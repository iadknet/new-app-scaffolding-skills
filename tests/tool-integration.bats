#!/usr/bin/env bats

load test_helper.bash

setup_file() {
  export ROOT
  export BASE_PROJECT="$BATS_FILE_TMPDIR/base-project"
  ROOT=$(cd -- "$BATS_TEST_DIRNAME/.." && pwd)
  "$ROOT/bin/init-agent-project" --agent codex --agent claude-code "$BASE_PROJECT" >/dev/null
  bash -c 'exec 3>&- 4>&- 5>&- 6>&- 7>&-; make -C "$1" AQUA_ROOT_DIR="$1/.tools/aqua" setup' _ "$BASE_PROJECT" >/dev/null
}

setup() {
  bats_require_minimum_version 1.14.0
  PROJECT="$BATS_TEST_TMPDIR/project"
  cp -R "$BASE_PROJECT" "$PROJECT"
}

@test "generated project initializes for integration testing" {
  [ -f "$PROJECT/Makefile" ]
  [ -f "$PROJECT/aqua.yaml" ]
}

@test "generated project creates proxies for pinned tools" {
  for tool in node npm npx uv gitleaks actionlint shellcheck osv-scanner; do
    [ -x "$PROJECT/.tools/aqua/bin/$tool" ]
  done
}

@test "checksum enforcement rejects an incomplete lock and recovers" {
  command -v aqua >/dev/null
  for tool in node npm npx uv gitleaks actionlint shellcheck osv-scanner; do
    [ -x "$PROJECT/.tools/aqua/bin/$tool" ]
  done
  [ -x "$PROJECT/.git/hooks/pre-commit" ]
  [ -z "$(git -C "$PROJECT" config --local --get core.hooksPath 2>/dev/null || :)" ]

  mv "$PROJECT/aqua-checksums.json" "$PROJECT/aqua-checksums.json.valid"
  printf '{\n  "checksums": []\n}\n' >"$PROJECT/aqua-checksums.json"
  rm -rf "$PROJECT/.tools"
  run make -C "$PROJECT" AQUA_ROOT_DIR="$PROJECT/.tools/aqua" setup
  assert_failure
  mv "$PROJECT/aqua-checksums.json.valid" "$PROJECT/aqua-checksums.json"
  run make -C "$PROJECT" AQUA_ROOT_DIR="$PROJECT/.tools/aqua" setup
  assert_success
  run make -C "$PROJECT" AQUA_ROOT_DIR="$PROJECT/.tools/aqua" check
  assert_success
}

@test "generated npm and subprocesses use Aqua-managed Node" {
  run env AQUA_ROOT_DIR="$PROJECT/.tools/aqua" PATH="$PROJECT/.tools/aqua/bin:$PATH" \
    bash -c 'cd "$1" && command -v node && command -v npm' _ "$PROJECT"
  assert_success
  [[ "${lines[0]}" = "$PROJECT/.tools/aqua/bin/node" ]]
  [[ "${lines[1]}" = "$PROJECT/.tools/aqua/bin/npm" ]]

  run env AQUA_ROOT_DIR="$PROJECT/.tools/aqua" PATH="$PROJECT/.tools/aqua/bin:$PATH" \
    bash -c 'cd "$1" && printf "%s\n" "$(node --version)" "$(npm exec -- node --version)"' _ "$PROJECT"
  assert_success
  [[ "$output" == *$'v22.20.0\nv22.20.0' ]]
}

@test "skill scanner rejects a malicious installed skill" {
  cp -R "$ROOT/tests/fixtures/malicious-skill" "$PROJECT/.agents/skills/malicious-fixture"
  run bash -c 'cd "$1" && scripts/skill-check --require-tools' _ "$PROJECT"
  assert_failure
}

@test "quality tools reject invalid shell and workflow fixtures" {
  printf '#!/bin/sh\nvalue=$1\nprintf "%%s\\n" $value\n' >"$PROJECT/scripts/shellcheck-failure"
  run bash -c 'cd "$1" && scripts/quality-check --require-tools' _ "$PROJECT"
  assert_failure
  rm "$PROJECT/scripts/shellcheck-failure"

  printf '%s\n' 'name: Invalid workflow fixture' 'on: push' 'permissions:' \
    '  contents: read' 'jobs:' '  invalid:' '    runs-on: ubuntu-latest' \
    '    steps:' '      - run: echo "${{ github.property_that_does_not_exist }}"' \
    >"$PROJECT/.github/workflows/actionlint-failure.yml"
  run bash -c 'cd "$1" && scripts/quality-check --require-tools' _ "$PROJECT"
  assert_failure
}

@test "secret scanning rejects staged and historical credentials" {
  git -C "$PROJECT" config user.name 'Scaffold Test'
  git -C "$PROJECT" config user.email 'scaffold-test@example.invalid'
  git -C "$PROJECT" add .
  git -C "$PROJECT" commit -m foundation >/dev/null
  printf 'AWS_ACCESS_KEY_ID=%s%s\n' 'AKIA' '6RVLMJWE7T4N7Q2X' >"$PROJECT/credentials.env"
  git -C "$PROJECT" add credentials.env
  run make -C "$PROJECT" precommit
  assert_failure
  git -C "$PROJECT" commit --no-verify -m 'synthetic credential fixture' >/dev/null
  rm "$PROJECT/credentials.env"
  git -C "$PROJECT" add -u
  git -C "$PROJECT" commit --no-verify -m 'remove synthetic credential fixture' >/dev/null
  run make -C "$PROJECT" audit
  assert_failure
}
