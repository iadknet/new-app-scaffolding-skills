#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-distribution.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
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

for skill in prd-create prd-review prd-implement project-workflow; do
  [ -f "$project/.agents/skills/$skill/SKILL.md" ] || {
    printf 'distribution-install: missing Codex skill %s\n' "$skill" >&2
    exit 1
  }
  [ -f "$project/.claude/skills/$skill/SKILL.md" ] || {
    printf 'distribution-install: missing Claude Code skill %s\n' "$skill" >&2
    exit 1
  }
done

[ ! -e "$project/.agents/skills/agent-project-scaffold" ] || {
  printf 'distribution-install: bootstrap skill leaked into generated project\n' >&2
  exit 1
}

(
  cd "$project"
  scripts/prd-check
  scripts/policy-check
)

printf 'Installed bootstrap and selected agent runtime skills passed.\n'
