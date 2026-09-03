#!/usr/bin/env bats

load test_helper.bash

@test "distribution quality" {
bats_require_minimum_version 1.14.0
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null || :)" = true ]; then
  git diff --check
  git diff --cached --check
  repository_root=$(git rev-parse --show-toplevel)
  if git grep --untracked -F "$repository_root" -- .; then
    printf 'distribution-quality: repository path leaked into a project file\n' >&2
    exit 1
  fi
fi

actionlint=${AQUA_ROOT_DIR:-.tools/aqua}/bin/actionlint
shellcheck=${AQUA_ROOT_DIR:-.tools/aqua}/bin/shellcheck
if [ ! -x "$actionlint" ] || [ ! -x "$shellcheck" ]; then
  printf 'distribution-quality: pinned quality tools are missing; run make setup\n' >&2
  exit 1
fi

find bin scripts skills/agent-project-scaffold/scripts skills/agent-project-scaffold/assets/template/scripts skills/go-project-scaffold/scripts skills/go-project-scaffold/assets/template/scripts skills/docker-bootstrap/assets/scripts tests/fixtures/docker-bootstrap \
  -type f -perm -111 -print |
  while IFS= read -r script; do
    "$shellcheck" --shell=sh --external-sources "$script"
  done
"$actionlint" -shellcheck="$shellcheck" .github/workflows/*.yml skills/agent-project-scaffold/assets/template/.github/workflows/*.yml skills/go-project-scaffold/assets/template/.github/workflows/*.yml
printf 'Distribution quality validation passed.\n'
}
