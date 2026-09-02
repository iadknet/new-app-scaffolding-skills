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

@test "root and generated-project Aqua configurations stay synchronized" {
  sed '/name: bats-core\/bats-core@/d' "$ROOT/aqua.yaml" >"$TEST_TMPDIR/root-aqua.yaml"
  cmp "$TEST_TMPDIR/root-aqua.yaml" "$TEMPLATE/aqua.yaml"
  [ ! -e "$ROOT/scripts"/aqua ]
  [ ! -e "$TEMPLATE/scripts"/aqua ]

  checksum_records "$ROOT/aqua-checksums.json" | grep -v 'bats-core/bats-core' >"$TEST_TMPDIR/root-checksums"
  checksum_records "$TEMPLATE/aqua-checksums.json" >"$TEST_TMPDIR/template-checksums"
  cmp "$TEST_TMPDIR/root-checksums" "$TEST_TMPDIR/template-checksums"
  [ "$(checksum_records "$ROOT/aqua-checksums.json" | grep -c 'bats-core/bats-core')" -eq 1 ]
}

@test "Aqua packages and checksum enforcement are pinned" {
  for package in nodejs/node@v22.20.0 astral-sh/uv@0.12.3 bats-core/bats-core@v1.14.0 rhysd/actionlint@v1.7.12 koalaman/shellcheck@v0.11.0 gitleaks/gitleaks@v8.30.1 google/osv-scanner@v2.4.0; do
    grep -Fq "name: $package" "$ROOT/aqua.yaml"
  done
  grep -Fq 'require_checksum: true' "$ROOT/aqua.yaml"
}

@test "Make exports the default Aqua proxy environment" {
  cat >"$TEST_TMPDIR/probe.mk" <<'EOF'
aqua-environment-probe:
	@printf 'root=%s\n' "$$AQUA_ROOT_DIR"
	@printf 'checksum=%s\n' "$$AQUA_ENFORCE_CHECKSUM"
	@printf 'require-checksum=%s\n' "$$AQUA_ENFORCE_REQUIRE_CHECKSUM"
	@printf 'path=%s\n' "$$PATH"
EOF
  run make -C "$ROOT" --no-print-directory -f Makefile -f "$TEST_TMPDIR/probe.mk" aqua-environment-probe
  assert_success
  [[ "${lines[0]}" = "root=$ROOT/.tools/aqua" ]]
  [[ "${lines[1]}" = 'checksum=true' ]]
  [[ "${lines[2]}" = 'require-checksum=true' ]]
  [[ "${lines[3]}" = "path=$ROOT/.tools/aqua/bin:"* ]]
}

@test "Make preserves an explicit Aqua root override" {
  cat >"$TEST_TMPDIR/probe.mk" <<'EOF'
aqua-root-probe:
	@printf '%s\n' "$$AQUA_ROOT_DIR"
	@printf '%s\n' "$$PATH"
EOF
  custom_root=$TEST_TMPDIR/custom-aqua
  run env AQUA_ROOT_DIR="$custom_root" make -C "$ROOT" --no-print-directory -f Makefile -f "$TEST_TMPDIR/probe.mk" aqua-root-probe
  assert_success
  [[ "${lines[0]}" = "$custom_root" ]]
  [[ "${lines[1]}" = "$custom_root/bin:"* ]]
}

@test "setup creates Aqua proxy links before installing local tools" {
  run make -C "$ROOT" --no-print-directory --dry-run setup
  assert_success
  [[ "${lines[0]}" = 'aqua install -l' ]]
  [[ "$output" = *'scripts/install-skill-scanner'* ]]
  [[ "$output" = *'scripts/install-pre-commit'* ]]
}

@test "CI uses Aqua installer proxy links without redundant runtime setup" {
  adapter=scripts/aqu'a'
  setup_node=actions/setup-'node'
  setup_uv=astral-sh/setup-'uv'
  for workflow in "$ROOT/.github/workflows/test.yml" "$TEMPLATE/.github/workflows/ci.yml"; do
    grep -Fq 'AQUA_ROOT_DIR: ${{ github.workspace }}/.tools/aqua' "$workflow"
    grep -Fq 'AQUA_ENFORCE_CHECKSUM: "true"' "$workflow"
    grep -Fq 'AQUA_ENFORCE_REQUIRE_CHECKSUM: "true"' "$workflow"
    if grep -Eq "$adapter|$setup_node|$setup_uv" "$workflow"; then
      printf 'aqua-config: workflow contains redundant Aqua or runtime setup: %s\n' "$workflow" >&2
      exit 1
    fi
  done
}
