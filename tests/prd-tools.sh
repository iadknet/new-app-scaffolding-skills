#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-prd-tools.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
project=$tmp/project
template=$root/skills/agent-project-scaffold/assets/template

cp -R "$template" "$project"
chmod +x "$project"/scripts/* "$project"/.githooks/pre-commit
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
