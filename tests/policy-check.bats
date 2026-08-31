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
}

@test "repository policy accepts the generated template" {
scripts/policy-check
}

@test "repository policy rejects job-level write permissions" {
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
}

@test "repository policy requires pinned reusable workflows" {
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
}
