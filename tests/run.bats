#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
tests_run=0

pass() {
  tests_run=$((tests_run + 1))
  printf 'ok %s - %s\n' "$tests_run" "$1"
}

fail() {
  printf 'not ok %s - %s\n' "$((tests_run + 1))" "$1" >&2
  exit 1
}

assert_file() { [ -f "$1" ] || fail "missing file $1"; }
assert_fails() { "$@" >/dev/null 2>&1 && fail "command unexpectedly succeeded: $*" || :; }

mock_bin="$tmp/mock-bin"
mkdir "$mock_bin"
cat >"$mock_bin/npx" <<'EOF'
#!/bin/sh
set -eu

[ "$1" = --yes ] && [ "$2" = skills@1.5.23 ] || exit 2
[ -n "${NPM_CONFIG_BEFORE:-}" ] || exit 2
printf '%s\n' "$NPM_CONFIG_BEFORE" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' || exit 2
shift 2
[ "$1" = add ] || exit 2
source_dir=$2
shift 2
agents=
while [ "$#" -gt 0 ]; do
  case $1 in
    --skill) [ "$2" = '*' ] || exit 2; shift 2 ;;
    --copy|--yes|-y) shift ;;
    --agent) agents="$agents $2"; shift 2 ;;
    *) exit 2 ;;
  esac
done
[ -n "$agents" ] || exit 2
[ -z "${MOCK_NPX_FAIL:-}" ] || exit 70
for agent in $agents; do
  case $agent in
    codex) destination=.agents/skills ;;
    claude-code) destination=.claude/skills ;;
    *) exit 2 ;;
  esac
  mkdir -p "$destination"
  for skill_dir in "$source_dir"/*; do
    [ -d "$skill_dir" ] || continue
    cp -R "$skill_dir" "$destination/$(basename "$skill_dir")"
  done
done
EOF
chmod +x "$mock_bin/npx"

init() {
  PATH="$mock_bin:$PATH" "$root/bin/init-agent-project" --agent codex --agent claude-code "$@"
}
}

@test "initializer renders a project with selected runtime skills" {
project="$tmp/project with spaces"
init --name 'Example & Tools' "$project" >/dev/null
for expected in AGENTS.md CHANGELOG.md CLAUDE.md Makefile README.md SECURITY.md .pre-commit-config.yaml \
  scripts/changelog scripts/prd-check scripts/skill-check scripts/install-pre-commit scripts/pre-commit-hook \
  aqua.yaml aqua-checksums.json scripts/dependency-audit scripts/dependency-policy-check \
  docs/prds/active/project-foundation/master-prd.md .github/workflows/ci.yml; do
  assert_file "$project/$expected"
done
[ ! -e "$project/scripts"/aqua ] || fail 'generated project contains the obsolete Aqua adapter'
[ ! -e "$project/.tools" ] || fail 'generated project contains local tool state'
grep -Fq 'entry: make project-precommit' "$project/.pre-commit-config.yaml" || fail 'generated project hook bypasses Make'
grep -Fq 'repo_root=$(git rev-parse --show-toplevel)' "$project/scripts/pre-commit-hook" || fail 'generated pre-commit hook is not repository-relative'
grep -Fq '# Example & Tools' "$project/README.md" || fail 'project name was not rendered'
if grep -RE '__[A-Z_]+__' "$project" --exclude-dir=.git >/dev/null 2>&1; then
  fail 'unrendered project token'
fi
if find "$project" -type l -print -quit | grep -q .; then
  fail 'generated project contains a symlink'
fi
if grep -RFl "$tmp" "$project" --exclude-dir=.git >/dev/null 2>&1; then
  fail 'generated project contains its staging or test path'
fi
[ "$(git -C "$project" symbolic-ref --short HEAD)" = main ] || fail 'initial branch is not main'
assert_fails git -C "$project" rev-parse --verify HEAD
for skill in prd-create prd-review prd-implement project-workflow public-repo-readiness; do
  assert_file "$project/.agents/skills/$skill/SKILL.md"
  assert_file "$project/.claude/skills/$skill/SKILL.md"
done
[ -f "$project/.agents/skills/public-repo-readiness/references/public-repository-checklist.md" ] || fail 'missing public repository readiness reference'
grep -Fq 'five project-scoped workflow skills' "$project/README.md" || fail 'generated README has stale skill count'
grep -Fq 'public-repo-readiness' "$project/AGENTS.md" || fail 'generated agent instructions lack public repository readiness boundary'
[ ! -e "$project/.agents/skills/agent-project-scaffold" ] || fail 'bootstrap skill leaked into generated project'
pass 'initializes a rendered project with only selected runtime skills'
}

@test "initializer accepts empty and otherwise-empty Git targets" {
empty="$tmp/empty"
mkdir "$empty"
PATH="$mock_bin:$PATH" "$root/skills/agent-project-scaffold/scripts/init-agent-project" --agent codex "$empty" >/dev/null
assert_file "$empty/.agents/skills/prd-create/SKILL.md"
[ ! -e "$empty/.claude" ] || fail 'unselected Claude Code files were installed'

empty_git="$tmp/empty-git"
mkdir "$empty_git"
git -C "$empty_git" init >/dev/null 2>&1
init "$empty_git" >/dev/null
[ "$(git -C "$empty_git" symbolic-ref --short HEAD)" = main ] || fail 'empty Git branch was not normalized to main'
pass 'accepts empty and otherwise-empty Git targets'
}

@test "initializer rejects unsafe targets and rolls back failed installation" {
populated="$tmp/populated"
mkdir "$populated"
touch "$populated/.hidden"
assert_fails init "$populated"
assert_fails "$root/bin/init-agent-project" "$tmp/no-agent"
ln -s "$tmp" "$tmp/linked-target"
assert_fails "$root/bin/init-agent-project" --agent codex "$tmp/linked-target"
failed="$tmp/failed-install"
assert_fails env MOCK_NPX_FAIL=1 PATH="$mock_bin:$PATH" "$root/bin/init-agent-project" --agent codex "$failed"
[ ! -e "$failed" ] || fail 'failed installer left a target directory'
invalid="$tmp/invalid-agent"
assert_fails env PATH="$mock_bin:$PATH" "$root/bin/init-agent-project" --agent unsupported "$invalid"
[ ! -e "$invalid" ] || fail 'invalid agent left a target directory'
pass 'rejects unsafe targets and rolls back a failed install'
}

@test "pre-commit installer is repository-relative and rejects custom hook paths" {
project=$tmp/portable-hook
init "$project" >/dev/null
mkdir -p "$project/.tools/bin" "$project/nested"
printf '#!/bin/sh\nprintf "pre-commit 4.6.2\\n"\n' >"$project/.tools/bin/pre-commit"
chmod +x "$project/.tools/bin/pre-commit"

run sh -c 'cd "$1/nested" && ../scripts/install-pre-commit' _ "$project"
assert_success
cmp "$project/scripts/pre-commit-hook" "$project/.git/hooks/pre-commit"

git -C "$project" config core.hooksPath custom-hooks
run sh -c 'cd "$1/nested" && ../scripts/install-pre-commit' _ "$project"
assert_failure
[[ "$output" = *'unsupported core.hooksPath: custom-hooks'* ]]
}
