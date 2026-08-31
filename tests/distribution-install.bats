#!/usr/bin/env bats

load test_helper.bash

@test "distribution installation produces a usable project without bootstrap leakage" {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
installed=$tmp/installed
project=$tmp/project

mkdir "$installed"
(
  cd "$installed"
  npx --yes skills@1.5.23 add "$root" \
    --skill agent-project-scaffold \
    --agent codex \
    --copy \
    --yes
)

initializer=$installed/.agents/skills/agent-project-scaffold/scripts/init-agent-project
[ -x "$initializer" ] || { printf 'distribution-install: bootstrap skill was not installed\n' >&2; exit 1; }

"$initializer" --agent codex --agent claude-code "$project" >/dev/null

for skill in prd-create prd-review prd-implement project-workflow public-repo-readiness; do
  [ -f "$project/.agents/skills/$skill/SKILL.md" ] || {
    printf 'distribution-install: missing Codex skill %s\n' "$skill" >&2
    exit 1
  }
  [ -f "$project/.claude/skills/$skill/SKILL.md" ] || {
    printf 'distribution-install: missing Claude Code skill %s\n' "$skill" >&2
    exit 1
  }
done

[ -f "$project/.agents/skills/public-repo-readiness/references/public-repository-checklist.md" ] || {
  printf 'distribution-install: missing public repository readiness reference\n' >&2
  exit 1
}

[ ! -e "$project/.agents/skills/agent-project-scaffold" ] || {
  printf 'distribution-install: bootstrap skill leaked into generated project\n' >&2
  exit 1
}

(
  cd "$project"
  scripts/prd-check
  scripts/policy-check
)

}
