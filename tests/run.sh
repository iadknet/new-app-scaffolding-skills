#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-tests.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
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

project="$tmp/project with spaces"
init --name 'Example & Tools' "$project" >/dev/null
for expected in AGENTS.md CHANGELOG.md CLAUDE.md Makefile README.md SECURITY.md scripts/changelog scripts/prd-check \
  docs/prds/active/project-foundation/master-prd.md .github/workflows/ci.yml; do
  assert_file "$project/$expected"
done
grep -Fq '# Example & Tools' "$project/README.md" || fail 'project name was not rendered'
if grep -RE '__[A-Z_]+__' "$project" --exclude-dir=.git >/dev/null 2>&1; then
  fail 'unrendered project token'
fi
[ "$(git -C "$project" symbolic-ref --short HEAD)" = main ] || fail 'initial branch is not main'
assert_fails git -C "$project" rev-parse --verify HEAD
for skill in prd-create prd-review prd-implement project-workflow; do
  assert_file "$project/.agents/skills/$skill/SKILL.md"
  assert_file "$project/.claude/skills/$skill/SKILL.md"
done
[ ! -e "$project/.agents/skills/agent-project-scaffold" ] || fail 'bootstrap skill leaked into generated project'
pass 'initializes a rendered project with only selected runtime skills'

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
pass 'rejects unsafe targets and rolls back a failed install'

printf '1..%s\n' "$tests_run"
