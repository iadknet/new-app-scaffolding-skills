#!/bin/sh
set -eu

require_tools=0
if [ "${1:-}" = --require-tools ]; then
  require_tools=1
  shift
fi
[ "$#" -eq 0 ] || { printf 'Usage: tests/distribution-quality.sh [--require-tools]\n' >&2; exit 2; }

if git rev-parse --git-dir >/dev/null 2>&1; then
  git diff --check
  git diff --cached --check
fi

actionlint=.tools/bin/actionlint
shellcheck=.tools/bin/shellcheck
if [ ! -x "$actionlint" ] || [ ! -x "$shellcheck" ]; then
  if [ "$require_tools" -eq 1 ]; then
    printf 'distribution-quality: pinned quality tools are missing; run make setup\n' >&2
    exit 1
  fi
  printf 'distribution-quality: pinned tools are not installed; using reduced checks. Run make setup for ShellCheck and actionlint.\n'
  exit 0
fi

find bin scripts tests skills/agent-project-scaffold/scripts skills/agent-project-scaffold/assets/template/scripts \
  -type f -perm -111 -exec "$shellcheck" --shell=sh --external-sources {} +
"$actionlint" -shellcheck="$shellcheck" .github/workflows/*.yml skills/agent-project-scaffold/assets/template/.github/workflows/*.yml
printf 'Distribution quality validation passed.\n'
