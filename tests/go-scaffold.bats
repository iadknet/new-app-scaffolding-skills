#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"

mock_bin=$tmp/mock-bin
mkdir "$mock_bin"
cat >"$mock_bin/npx" <<'EOF'
#!/bin/sh
set -eu
[ -n "${NPM_CONFIG_BEFORE:-}" ] || exit 2
shift 2
[ "$1" = add ] || exit 2
source_dir=$2
shift 2
while [ "$#" -gt 0 ]; do
  case $1 in
    --skill) shift 2 ;;
    --copy|--yes) shift ;;
    --agent)
      case $2 in codex) dest=.agents/skills ;; claude-code) dest=.claude/skills ;; *) exit 2 ;; esac
      mkdir -p "$dest"
      for item in "$source_dir"/*; do cp -R "$item" "$dest/"; done
      shift 2
      ;;
    *) exit 2 ;;
  esac
done
EOF
chmod +x "$mock_bin/npx"
}

@test "Go scaffold renders a valid project and selected skills" {
project=$tmp/widget
PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --name Widget --module example.com/acme/widget --agent codex --agent claude-code "$project" >/dev/null
for file in go.mod Makefile .golangci.yml AGENTS.md .githooks/pre-commit scripts/install-go-tools scripts/policy-check .github/workflows/ci.yml cmd/widget/main.go; do
  [ -f "$project/$file" ] || { printf 'missing %s\n' "$file" >&2; exit 1; }
done
grep -Fq 'module example.com/acme/widget' "$project/go.mod"
grep -Fq 'go 1.26.5' "$project/go.mod"
grep -Fq 'gocyclo' "$project/.golangci.yml"
(
  cd "$project"
  scripts/policy-check
)
[ -f "$project/.agents/skills/golang-testing/SKILL.md" ]
[ -f "$project/.claude/skills/golang-security/SKILL.md" ]
}

@test "Go scaffold accepts an otherwise-empty Git repository" {
existing_project=$tmp/existing-widget
mkdir "$existing_project"
git -C "$existing_project" init >/dev/null
PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --module example.com/acme/existing-widget --agent codex "$existing_project" >/dev/null
[ "$(git -C "$existing_project" symbolic-ref --short HEAD)" = main ]
[ -f "$existing_project/.git/HEAD" ]
}

@test "Go scaffold rejects a missing module path" {
if PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --agent codex "$tmp/missing-module" >/dev/null 2>&1; then
  printf '%s\n' 'initializer accepted a missing module path' >&2
  exit 1
fi
}

@test "Go scaffold rolls back an unsupported agent" {
  target=$tmp/unsupported-agent
  if PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --module example.com/acme/widget --agent unsupported "$target" >/dev/null 2>&1; then
    printf '%s\n' 'initializer accepted an unsupported agent' >&2
    exit 1
  fi
  [ ! -e "$target" ]
}
