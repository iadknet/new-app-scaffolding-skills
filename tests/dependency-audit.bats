#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
project=$tmp/project
mkdir -p "$project/scripts" "$project/.tools/aqua/bin"
cp "$root/skills/agent-project-scaffold/assets/template/scripts/dependency-audit" \
  "$project/scripts/dependency-audit"
chmod +x "$project/scripts/dependency-audit"
}

@test "dependency audit succeeds when no dependency roots exist" {
(cd "$project" && scripts/dependency-audit --require-tools >/dev/null)
}

@test "dependency audit requires a scanner for a detected lockfile" {
touch "$project/package-lock.json"
if (cd "$project" && AQUA_ROOT_DIR="$project/.tools/aqua" PATH="$project/.tools/aqua/bin:$PATH" scripts/dependency-audit --require-tools >/dev/null 2>&1); then
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
(cd "$project" && AQUA_ROOT_DIR="$project/.tools/aqua" PATH="$project/.tools/aqua/bin:$PATH" OSV_SCANNER_LOG=$log scripts/dependency-audit --require-tools)
grep -Fx 'scan source --recursive .' "$log" >/dev/null || {
  printf 'dependency-audit: scanner did not receive the expected source scan command\n' >&2
  exit 1
}
}
