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

@test "Go scaffold renders a neutral module foundation and selected skills" {
project=$tmp/widget
PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --name Widget --module example.com/acme/widget --agent codex --agent claude-code "$project" >/dev/null
for file in go.mod Makefile .golangci.yml AGENTS.md scripts/git-hooks/pre-commit scripts/install-go-tools scripts/policy-check .github/workflows/ci.yml; do
  [ -f "$project/$file" ] || { printf 'missing %s\n' "$file" >&2; exit 1; }
done
[ -z "$(find "$project" -type f -name '*.go' -print -quit)" ] || {
  printf 'Go scaffold generated application source\n' >&2
  exit 1
}
[ -z "$(find "$project" -type l -print -quit)" ] || {
  printf 'Go scaffold generated a symlink\n' >&2
  exit 1
}
if grep -RFl "$tmp" "$project" --exclude-dir=.git >/dev/null 2>&1; then
  printf 'Go scaffold leaked its staging or test path\n' >&2
  exit 1
fi
grep -Fq 'module example.com/acme/widget' "$project/go.mod"
grep -Fq 'go 1.27.1' "$project/go.mod"
grep -Fq 'gocyclo' "$project/.golangci.yml"
grep -Fq 'No Go packages yet; skipping lint.' "$project/Makefile"
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

@test "Go tool installer is repository-relative" {
project=$tmp/portable-tools
PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --module example.com/acme/portable --agent codex "$project" >/dev/null
go_bin=$tmp/go-bin
log=$tmp/go-install.log
mkdir "$go_bin" "$project/nested"
cat >"$go_bin/go" <<'EOF'
#!/bin/sh
set -eu
[ "$1" = install ] || exit 2
printf '%s\n' "$GOBIN" >>"$GO_INSTALL_LOG"
EOF
chmod +x "$go_bin/go"

run env PATH="$go_bin:$PATH" GO_INSTALL_LOG="$log" sh -c 'cd "$1/nested" && ../scripts/install-go-tools' _ "$project"
[ "$status" -eq 0 ]
[ "$(wc -l <"$log" | tr -d ' ')" -eq 5 ]
while IFS= read -r installed_to; do
  [ "$installed_to" = "$project/.tools/bin" ]
done <"$log"
}

@test "Go scaffold package-dependent targets accept an empty module" {
project=$tmp/empty-module
PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --module example.com/acme/empty --agent codex "$project" >/dev/null
run make -C "$project" format fmt-check lint lint-changed test test-race vuln mutation mutation-diff build verify
[ "$status" -eq 0 ]
[[ "$output" == *"No Go packages yet; skipping lint."* ]]
[[ "$output" == *"No Go packages yet; skipping tests."* ]]
[[ "$output" == *"No Go packages yet; skipping reachable-vulnerability analysis."* ]]
}

@test "Go scaffold package-dependent targets fail when package discovery fails" {
project=$tmp/invalid-packages
PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --module example.com/acme/invalid --agent codex "$project" >/dev/null
printf 'package one\n' >"$project/one.go"
printf 'package two\n' >"$project/two.go"
run make -C "$project" quick
[ "$status" -ne 0 ]
[[ "$output" == *"found packages one"* ]]
[[ "$output" != *"No Go packages yet"* ]]
}

@test "Go scaffold rejects a missing module path" {
if PATH="$mock_bin:$PATH" "$root/bin/init-go-project" --agent codex "$tmp/missing-module" >/dev/null 2>&1; then
  printf '%s\n' 'initializer accepted a missing module path' >&2
  exit 1
fi
}

@test "Go scaffold policy rejects workflow-level write permissions" {
  project=$tmp/workflow-write-policy
  cp -R "$root/skills/go-project-scaffold/assets/template" "$project"
  cat >"$project/.github/workflows/elevated.yml" <<'EOF'
name: Elevated workflow
on: push
permissions:
  contents: read
  id-token: write
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo check
EOF
  if (cd "$project" && scripts/policy-check) >/dev/null 2>&1; then
    printf 'policy-check: workflow-level write permission was accepted\n' >&2
    exit 1
  fi
}

@test "Go scaffold policy rejects job-level permission overrides" {
  project=$tmp/job-permission-policy
  cp -R "$root/skills/go-project-scaffold/assets/template" "$project"
  cat >"$project/.github/workflows/elevated.yml" <<'EOF'
name: Elevated job
on: push
permissions:
  contents: read
jobs:
  check:
    permissions: {contents: write}
    runs-on: ubuntu-latest
    steps:
      - run: echo check
EOF
  if (cd "$project" && scripts/policy-check) >/dev/null 2>&1; then
    printf 'policy-check: job-level permission override was accepted\n' >&2
    exit 1
  fi
}

@test "Go scaffold policy rejects quoted permission escalation forms" {
  project=$tmp/quoted-permission-policy
  cp -R "$root/skills/go-project-scaffold/assets/template" "$project"
  cat >"$project/.github/workflows/elevated.yml" <<'EOF'
name: Quoted elevation
on: push
permissions:
  contents: read
"jobs":
  check:
    "permissions": {contents: "write"}
    runs-on: ubuntu-latest
    steps:
      - run: echo check
EOF
  if (cd "$project" && scripts/policy-check) >/dev/null 2>&1; then
    printf 'policy-check: quoted permission escalation was accepted\n' >&2
    exit 1
  fi
}

@test "Go scaffold policy keeps comments inside the workflow permission block" {
  project=$tmp/commented-permission-policy
  cp -R "$root/skills/go-project-scaffold/assets/template" "$project"
  cat >"$project/.github/workflows/elevated.yml" <<'EOF'
name: Commented elevation
on: push
permissions:
# This comment does not end the YAML mapping.
  contents: read
  id-token: write
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo check
EOF
  if (cd "$project" && scripts/policy-check) >/dev/null 2>&1; then
    printf 'policy-check: permission after a top-level comment was accepted\n' >&2
    exit 1
  fi
}

@test "Go scaffold policy rejects alternate top-level permission keys" {
  project=$tmp/alternate-top-level-permission-policy
  cp -R "$root/skills/go-project-scaffold/assets/template" "$project"
  cat >"$project/.github/workflows/elevated.yml" <<'EOF'
name: Duplicate permission elevation
on: push
permissions:
  contents: read
"permissions": write-all
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo check
EOF
  if (cd "$project" && scripts/policy-check) >/dev/null 2>&1; then
    printf 'policy-check: alternate top-level permission key was accepted\n' >&2
    exit 1
  fi
}

@test "Go scaffold policy rejects flow-style jobs with permission overrides" {
  project=$tmp/flow-job-permission-policy
  cp -R "$root/skills/go-project-scaffold/assets/template" "$project"
  cat >"$project/.github/workflows/elevated.yml" <<'EOF'
name: Flow job elevation
on: push
permissions:
  contents: read
jobs: {check: {runs-on: ubuntu-latest, permissions: write-all, steps: [{run: "echo check"}]}}
EOF
  if (cd "$project" && scripts/policy-check) >/dev/null 2>&1; then
    printf 'policy-check: flow-style job permission override was accepted\n' >&2
    exit 1
  fi
}

@test "Go scaffold policy rejects spaced job permission keys" {
  project=$tmp/spaced-job-permission-policy
  cp -R "$root/skills/go-project-scaffold/assets/template" "$project"
  cat >"$project/.github/workflows/elevated.yml" <<'EOF'
name: Spaced key elevation
on: push
permissions:
  contents: read
jobs:
  check:
    permissions : write-all
    runs-on: ubuntu-latest
    steps:
      - run: echo check
EOF
  if (cd "$project" && scripts/policy-check) >/dev/null 2>&1; then
    printf 'policy-check: spaced job permission key was accepted\n' >&2
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
