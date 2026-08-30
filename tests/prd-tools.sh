#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-prd-tools.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
project=$tmp/project
template=$root/skills/agent-project-scaffold/assets/template

cp -R "$template" "$project"
chmod +x "$project"/scripts/*
cd "$project"

scripts/prd-check
scripts/prd-new ship-feature design-api implement-api >/dev/null
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

cp docs/prds/active/ship-feature/stage-01-design-api.md "$tmp/stage-backup.md"
sed '/^## Documentation Impact and Synchronization$/d' "$tmp/stage-backup.md" >docs/prds/active/ship-feature/stage-01-design-api.md
if scripts/prd-check >/dev/null 2>&1; then
  printf 'prd-tools: missing documentation section was accepted\n' >&2
  exit 1
fi
cp "$tmp/stage-backup.md" docs/prds/active/ship-feature/stage-01-design-api.md

sed '/^- \[ \] Affected durable documentation is created, updated, or synchronized, or a no-change rationale is recorded\.$/d' "$tmp/stage-backup.md" >docs/prds/active/ship-feature/stage-01-design-api.md
if scripts/prd-check >/dev/null 2>&1; then
  printf 'prd-tools: missing documentation gate was accepted\n' >&2
  exit 1
fi
cp "$tmp/stage-backup.md" docs/prds/active/ship-feature/stage-01-design-api.md
scripts/prd-check

if scripts/prd-new duplicate-stages repeated repeated >/dev/null 2>&1; then
  printf 'prd-tools: duplicate stage names were accepted\n' >&2
  exit 1
fi
[ ! -e docs/prds/active/duplicate-stages ] || {
  printf 'prd-tools: duplicate stages left partial output\n' >&2
  exit 1
}

printf 'PRD template validation and generation smoke test passed.\n'
