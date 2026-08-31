#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
project=$tmp/project

mkdir -p "$project/scripts" "$project/.tools/bin" "$project/skills/example" \
  "$project/.agents/skills/example"
cp "$root/skills/agent-project-scaffold/assets/template/scripts/skill-check" \
  "$project/scripts/skill-check"
chmod +x "$project/scripts/skill-check"
}

@test "skill check distinguishes required and optional missing tools" {
if (cd "$project" && scripts/skill-check --require-tools >/dev/null 2>&1); then
  printf 'skill-check: required scanner absence was accepted\n' >&2
  exit 1
fi
(cd "$project" && scripts/skill-check >/dev/null)
}

@test "skill check scans each project skill root with deterministic settings" {
cat >"$project/.tools/bin/skill-scanner" <<'EOF'
#!/bin/sh
set -eu
printf '%s|%s|%s\n' "$LITELLM_LOCAL_MODEL_COST_MAP" "$ORT_DISABLE_TELEMETRY" "$*" >>"$SKILL_CHECK_LOG"
EOF
chmod +x "$project/.tools/bin/skill-scanner"

log=$tmp/invocations
(cd "$project" && SKILL_CHECK_LOG=$log scripts/skill-check --require-tools)
[ "$(wc -l <"$log" | tr -d ' ')" -eq 2 ] || {
  printf 'skill-check: expected one scan per project skill root\n' >&2
  exit 1
}
grep -Fq 'True|1|scan-all skills --recursive --check-overlap --use-behavioral --use-trigger --policy balanced --fail-on-severity high' "$log"
grep -Fq 'True|1|scan-all .agents/skills --recursive --check-overlap --use-behavioral --use-trigger --policy balanced --fail-on-severity high' "$log"
}

@test "skill check never scans the repository root" {
cat >"$project/.tools/bin/skill-scanner" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$SKILL_CHECK_LOG"
EOF
chmod +x "$project/.tools/bin/skill-scanner"
log=$tmp/invocations
(cd "$project" && SKILL_CHECK_LOG=$log scripts/skill-check --require-tools)
if grep -Fq 'scan-all . ' "$log"; then
  printf 'skill-check: repository root was scanned instead of project skill roots\n' >&2
  exit 1
fi
}
