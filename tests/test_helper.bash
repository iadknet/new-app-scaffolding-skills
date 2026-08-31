#!/usr/bin/env bash

repo_root() {
  cd -- "$BATS_TEST_DIRNAME/.." && pwd
}

setup_test_tmpdir() {
  TEST_TMPDIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TEST_TMPDIR"
}

assert_file() {
  [ -f "$1" ] || {
    printf 'expected file: %s\n' "$1" >&3
    return 1
  }
}

assert_success() {
  [ "$status" -eq 0 ] || {
    printf 'expected success, got status %s\n%s\n' "$status" "$output" >&3
    return 1
  }
}

assert_failure() {
  [ "$status" -ne 0 ] || {
    printf 'expected failure\n%s\n' "$output" >&3
    return 1
  }
}
