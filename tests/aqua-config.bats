#!/usr/bin/env bats

load test_helper.bash

setup() {
  bats_require_minimum_version 1.14.0
  setup_test_tmpdir
  ROOT=$(repo_root)
  TEMPLATE="$ROOT/skills/agent-project-scaffold/assets/template"
}

checksum_records() {
  awk '
    /"id":/ { id=$0; sub(/^[[:space:]]*/, "", id) }
    /"checksum":/ { checksum=$0; sub(/^[[:space:]]*/, "", checksum) }
    /"algorithm":/ { algorithm=$0; sub(/^[[:space:]]*/, "", algorithm); print id "|" checksum "|" algorithm }
  ' "$1"
}

install_mock_aqua() {
  mkdir -p "$TEST_TMPDIR/bin"
  printf '%s\n' '#!/bin/sh' 'set -eu' \
    'case ${1:-} in' \
    '  --version) printf "aqua version %s\\n" "$MOCK_AQUA_VERSION" ;;' \
    '  install) printf "install\\n" >>"$MOCK_AQUA_LOG" ;;' \
    '  *) exit 2 ;;' 'esac' >"$TEST_TMPDIR/bin/aqua"
  chmod +x "$TEST_TMPDIR/bin/aqua"
}

@test "root and generated-project Aqua configurations stay synchronized" {
  sed '/name: bats-core\/bats-core@/d' "$ROOT/aqua.yaml" >"$TEST_TMPDIR/root-aqua.yaml"
  cmp "$TEST_TMPDIR/root-aqua.yaml" "$TEMPLATE/aqua.yaml"
  cmp "$ROOT/scripts/aqua" "$TEMPLATE/scripts/aqua"

  checksum_records "$ROOT/aqua-checksums.json" | grep -v 'bats-core/bats-core' >"$TEST_TMPDIR/root-checksums"
  checksum_records "$TEMPLATE/aqua-checksums.json" >"$TEST_TMPDIR/template-checksums"
  cmp "$TEST_TMPDIR/root-checksums" "$TEST_TMPDIR/template-checksums"
  [ "$(checksum_records "$ROOT/aqua-checksums.json" | grep -c 'bats-core/bats-core')" -eq 1 ]
}

@test "Aqua packages and checksum enforcement are pinned" {
  for package in bats-core/bats-core@v1.14.0 rhysd/actionlint@v1.7.12 koalaman/shellcheck@v0.11.0 gitleaks/gitleaks@v8.30.1 google/osv-scanner@v2.4.0; do
    grep -Fq "name: $package" "$ROOT/aqua.yaml"
  done
  grep -Fq 'require_checksum: true' "$ROOT/aqua.yaml"
}

@test "Aqua wrapper rejects an unsupported version" {
  install_mock_aqua
  run env PATH="$TEST_TMPDIR/bin:$PATH" MOCK_AQUA_VERSION=2.60.0 MOCK_AQUA_LOG="$TEST_TMPDIR/log" "$ROOT/scripts/aqua" install
  assert_failure
  [ ! -e "$TEST_TMPDIR/log" ]
}

@test "Aqua wrapper invokes a supported installation" {
  install_mock_aqua
  run env PATH="$TEST_TMPDIR/bin:$PATH" MOCK_AQUA_VERSION=2.60.1 MOCK_AQUA_LOG="$TEST_TMPDIR/log" "$ROOT/scripts/aqua" install
  assert_success
  grep -Fx 'install' "$TEST_TMPDIR/log"
}
