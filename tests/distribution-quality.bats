#!/usr/bin/env bats

load test_helper.bash

@test "distribution quality" {
bats_require_minimum_version 1.14.0
if git rev-parse --git-dir >/dev/null 2>&1; then
  git diff --check
  git diff --cached --check
fi

actionlint=${AQUA_ROOT_DIR:-.tools/aqua}/bin/actionlint
shellcheck=${AQUA_ROOT_DIR:-.tools/aqua}/bin/shellcheck
if [ ! -x "$actionlint" ] || [ ! -x "$shellcheck" ]; then
  printf 'distribution-quality: pinned quality tools are missing; run make setup\n' >&2
  exit 1
fi

find bin scripts skills/agent-project-scaffold/scripts skills/agent-project-scaffold/assets/template/scripts skills/go-project-scaffold/scripts skills/go-project-scaffold/assets/template/scripts skills/go-project-scaffold/assets/template/.githooks \
  -type f -perm -111 -exec shellcheck --shell=sh --external-sources {} +
actionlint -shellcheck="$shellcheck" .github/workflows/*.yml skills/agent-project-scaffold/assets/template/.github/workflows/*.yml skills/go-project-scaffold/assets/template/.github/workflows/*.yml
printf 'Distribution quality validation passed.\n'
}
