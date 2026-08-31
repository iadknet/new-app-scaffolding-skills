#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
project=$tmp/project
mkdir -p "$project/scripts" "$project/.tools/aqua/bin" "$project/mock-bin"
cp "$root/skills/agent-project-scaffold/assets/template/scripts/dependency-audit" \
  "$project/scripts/dependency-audit"
cp "$root/skills/agent-project-scaffold/assets/template/scripts/aqua" "$project/scripts/aqua"
chmod +x "$project/scripts/dependency-audit" "$project/scripts/aqua"

cat >"$project/mock-bin/aqua" <<'EOF'
#!/bin/sh
set -eu
[ "${1:-}" = --version ] && {
  printf 'aqua version 2.62.2\n'
  exit 0
}
[ "$1" = exec ] && [ "$2" = -- ] || exit 2
shift 2
tool=$1
shift
exec "$AQUA_ROOT_DIR/bin/$tool" "$@"
EOF
chmod +x "$project/mock-bin/aqua"
}

@test "dependency audit succeeds when no dependency roots exist" {
(cd "$project" && scripts/dependency-audit --require-tools >/dev/null)
}

@test "dependency audit requires a scanner for a detected lockfile" {
touch "$project/package-lock.json"
if (cd "$project" && PATH="$project/mock-bin:$PATH" scripts/dependency-audit --require-tools >/dev/null 2>&1); then
  printf 'dependency-audit: required scanner absence was accepted\n' >&2
  exit 1
fi
}

@test "dependency audit invokes OSV scanner for a detected lockfile" {
touch "$project/package-lock.json"
cat >"$project/.tools/aqua/bin/osv-scanner" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$OSV_SCANNER_LOG"
EOF
chmod +x "$project/.tools/aqua/bin/osv-scanner"
log=$tmp/invocations
(cd "$project" && PATH="$project/mock-bin:$PATH" OSV_SCANNER_LOG=$log scripts/dependency-audit --require-tools)
grep -Fx 'scan source --recursive .' "$log" >/dev/null || {
  printf 'dependency-audit: scanner did not receive the expected source scan command\n' >&2
  exit 1
}
}
