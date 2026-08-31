#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
project=$tmp/project
template=$root/skills/agent-project-scaffold/assets/template

cp -R "$template" "$project"
chmod +x "$project"/scripts/*
cd "$project"

create_prd() {
  scripts/prd-new ship-feature design-api implement-api >/dev/null
}
}

@test "PRD tools create a valid ordered project" {
scripts/prd-check
create_prd
[ -f docs/prds/active/ship-feature/stage-01-design-api.md ] || {
  printf 'prd-tools: first stage was not created\n' >&2
  exit 1
}
grep -Fq 'stage-02-implement-api.md' docs/prds/active/ship-feature/master-prd.md || {
  printf 'prd-tools: stage ordering was not recorded\n' >&2
  exit 1
}
grep -Fq '## Documentation Impact and Synchronization' docs/prds/active/ship-feature/master-prd.md || {
  printf 'prd-tools: master documentation section was not generated\n' >&2
  exit 1
}
grep -Fq '## Documentation Impact and Synchronization' docs/prds/active/ship-feature/stage-01-design-api.md || {
  printf 'prd-tools: stage documentation section was not generated\n' >&2
  exit 1
}
grep -Fq 'Affected durable documentation is created, updated, or synchronized, or a no-change rationale is recorded.' docs/prds/active/ship-feature/stage-01-design-api.md || {
  printf 'prd-tools: stage documentation gate was not generated\n' >&2
  exit 1
}
scripts/prd-check
}

@test "PRD validation rejects a missing documentation section" {
create_prd
cp docs/prds/active/ship-feature/stage-01-design-api.md "$tmp/stage-backup.md"
sed '/^## Documentation Impact and Synchronization$/d' "$tmp/stage-backup.md" >docs/prds/active/ship-feature/stage-01-design-api.md
if scripts/prd-check >/dev/null 2>&1; then
  printf 'prd-tools: missing documentation section was accepted\n' >&2
  exit 1
fi
}

@test "PRD validation rejects a missing documentation gate" {
create_prd
cp docs/prds/active/ship-feature/stage-01-design-api.md "$tmp/stage-backup.md"
sed '/^- \[ \] Affected durable documentation is created, updated, or synchronized, or a no-change rationale is recorded\.$/d' "$tmp/stage-backup.md" >docs/prds/active/ship-feature/stage-01-design-api.md
if scripts/prd-check >/dev/null 2>&1; then
  printf 'prd-tools: missing documentation gate was accepted\n' >&2
  exit 1
fi
}

@test "PRD creation rejects duplicate stage names without partial output" {
if scripts/prd-new duplicate-stages repeated repeated >/dev/null 2>&1; then
  printf 'prd-tools: duplicate stage names were accepted\n' >&2
  exit 1
fi
[ ! -e docs/prds/active/duplicate-stages ] || {
  printf 'prd-tools: duplicate stages left partial output\n' >&2
  exit 1
}
}
