#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-policy.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
project=$tmp/project
template=$root/skills/agent-project-scaffold/assets/template

cp -R "$template" "$project"
chmod +x "$project"/scripts/* "$project"/.githooks/pre-commit
cd "$project"

scripts/policy-check

cat >.github/workflows/elevated-permissions.yml <<'EOF'
name: Elevated permissions
on: push
permissions:
  contents: read
jobs:
  elevated:
    permissions:
      contents: write
    runs-on: ubuntu-latest
    steps:
      - run: echo elevated
EOF
if scripts/policy-check >/dev/null 2>&1; then
  printf 'policy-check: job-level write permission was accepted\n' >&2
  exit 1
fi
rm .github/workflows/elevated-permissions.yml

cat >.github/workflows/unpinned-reusable.yml <<'EOF'
name: Unpinned reusable workflow
on: push
permissions:
  contents: read
jobs:
  reusable:
    uses: example/example/.github/workflows/reusable.yml@main
EOF
if scripts/policy-check >/dev/null 2>&1; then
  printf 'policy-check: unpinned reusable workflow was accepted\n' >&2
  exit 1
fi
sed 's/@main/@0123456789abcdef0123456789abcdef01234567/' .github/workflows/unpinned-reusable.yml >.github/workflows/reusable.tmp
mv .github/workflows/reusable.tmp .github/workflows/unpinned-reusable.yml
scripts/policy-check

printf 'Repository policy validation smoke test passed.\n'
