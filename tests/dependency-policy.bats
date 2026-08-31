#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
template=$root/skills/agent-project-scaffold/assets/template
mock_bin=$tmp/mock-bin
mkdir "$mock_bin"

cat >"$mock_bin/npm" <<'EOF'
#!/bin/sh
set -eu

case ${1:-} in
  --version) printf '%s\n' "${MOCK_NPM_VERSION:-11.10.0}" ;;
  config)
    [ "${2:-}" = get ] && [ "${3:-}" = min-release-age ] || exit 2
    awk -F= '/^[[:space:]]*min-release-age[[:space:]]*=/ { value = $2; sub(/[[:space:]]*(#.*)?$/, "", value) } END { if (value != "") print value; else print "null" }' .npmrc
    ;;
  *) exit 2 ;;
esac
EOF

cat >"$mock_bin/pnpm" <<'EOF'
#!/bin/sh
set -eu

case ${1:-} in
  --version) printf '%s\n' "${MOCK_PNPM_VERSION:-10.16.0}" ;;
  config)
    [ "${2:-}" = get ] || exit 2
    case ${3:-} in
      --location=project) key=${4:-} ;;
      *) key=${3:-} ;;
    esac
    awk -v key="$key" '
      $0 ~ "^[[:space:]]*" key ":[[:space:]]*" {
        value = $0
        sub("^[[:space:]]*" key ":[[:space:]]*", "", value)
        sub(/[[:space:]]*(#.*)?$/, "", value)
      }
      END { if (value != "") print value; else print "null" }
    ' pnpm-workspace.yaml
    ;;
  *) exit 2 ;;
esac
EOF

cat >"$mock_bin/yarn" <<'EOF'
#!/bin/sh
set -eu

case ${1:-} in
  --version) printf '%s\n' "${MOCK_YARN_VERSION:-4.12.0}" ;;
  config)
    [ "${2:-}" = get ] && [ "${3:-}" = npmMinimalAgeGate ] || exit 2
    awk '
      /^[[:space:]]*npmMinimalAgeGate:[[:space:]]*/ {
        value = $0
        sub(/^[[:space:]]*npmMinimalAgeGate:[[:space:]]*/, "", value)
        sub(/[[:space:]]*(#.*)?$/, "", value)
        gsub(/^[\"]|[\"]$/, "", value)
      }
      END { if (value != "") print value; else print "null" }
    ' .yarnrc.yml
    ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$mock_bin/npm" "$mock_bin/pnpm" "$mock_bin/yarn"
PATH="$mock_bin:$PATH"

create_project() {
  project=$tmp/$1
  cp -R "$template" "$project"
  chmod +x "$project"/scripts/*
  printf '%s\n' "$project"
}

fail() {
  printf 'dependency-policy test: %s\n' "$*" >&2
  exit 1
}

expect_success() {
  (cd "$1" && scripts/dependency-policy-check) >/dev/null || fail "$2"
}

expect_failure() {
  if (cd "$1" && scripts/dependency-policy-check) >/dev/null 2>&1; then
    fail "$2"
  fi
}

write_dependabot() {
  cat >"$1/.github/dependabot.yml" <<EOF
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    cooldown:
      default-days: 7
  - package-ecosystem: $2
    directory: ${3:-/}
    schedule:
      interval: weekly
    cooldown:
      default-days: 7
EOF
}
}

@test "npm dependency policy enforces versions, lockfiles, and age gates" {
npm_project=$(create_project npm)
cat >"$npm_project/package.json" <<'EOF'
{"name":"fixture","packageManager":"npm@11.10.0"}
EOF
touch "$npm_project/package-lock.json"
printf 'min-release-age=7\n' >"$npm_project/.npmrc"
write_dependabot "$npm_project" npm
expect_success "$npm_project" 'compliant npm policy was rejected'
printf 'min-release-age=0\n' >>"$npm_project/.npmrc"
expect_failure "$npm_project" 'npm policy accepted an overridden age gate'
sed -i.bak '$d' "$npm_project/.npmrc"
rm "$npm_project/.npmrc.bak"
MOCK_NPM_VERSION=11.10.1 expect_failure "$npm_project" 'npm policy accepted a different installed npm version'
unset MOCK_NPM_VERSION
rm "$npm_project/package-lock.json"
touch "$npm_project/npm-shrinkwrap.json"
expect_failure "$npm_project" 'npm policy accepted obsolete npm-shrinkwrap.json'
rm "$npm_project/npm-shrinkwrap.json"
touch "$npm_project/package-lock.json"
rm "$npm_project/.npmrc"
expect_failure "$npm_project" 'npm policy accepted a missing age gate'
}

@test "pnpm dependency policy supports projects and workspaces" {
pnpm_project=$(create_project pnpm)
cat >"$pnpm_project/package.json" <<'EOF'
{"name":"fixture","packageManager":"pnpm@10.16.0"}
EOF
touch "$pnpm_project/pnpm-lock.yaml"
cat >"$pnpm_project/pnpm-workspace.yaml" <<'EOF'
minimumReleaseAge: 10080
minimumReleaseAgeStrict: true
minimumReleaseAgeIgnoreMissingTime: false
EOF
write_dependabot "$pnpm_project" npm
expect_success "$pnpm_project" 'compliant pnpm policy was rejected'
sed -i.bak 's/minimumReleaseAgeStrict: true/minimumReleaseAgeStrict: false/' "$pnpm_project/pnpm-workspace.yaml"
rm "$pnpm_project/pnpm-workspace.yaml.bak"
expect_failure "$pnpm_project" 'pnpm policy accepted non-strict age enforcement'

pnpm_workspace_project=$(create_project pnpm-workspace)
cat >"$pnpm_workspace_project/package.json" <<'EOF'
{"name":"fixture","packageManager":"pnpm@10.16.0"}
EOF
touch "$pnpm_workspace_project/pnpm-lock.yaml"
cat >"$pnpm_workspace_project/pnpm-workspace.yaml" <<'EOF'
packages:
  - "packages/*"
minimumReleaseAge: 10080
minimumReleaseAgeStrict: true
minimumReleaseAgeIgnoreMissingTime: false
EOF
mkdir -p "$pnpm_workspace_project/packages/member"
cat >"$pnpm_workspace_project/packages/member/package.json" <<'EOF'
{"name":"member"}
EOF
write_dependabot "$pnpm_workspace_project" npm
expect_success "$pnpm_workspace_project" 'pnpm workspace with a root lockfile was rejected'
}

@test "Yarn dependency policy rejects competing lockfiles" {
yarn_project=$(create_project yarn)
cat >"$yarn_project/package.json" <<'EOF'
{"name":"fixture","packageManager":"yarn@4.12.0"}
EOF
touch "$yarn_project/yarn.lock"
printf 'npmMinimalAgeGate: 7d\n' >"$yarn_project/.yarnrc.yml"
write_dependabot "$yarn_project" npm
expect_success "$yarn_project" 'compliant Yarn policy was rejected'
touch "$yarn_project/package-lock.json"
expect_failure "$yarn_project" 'Node policy accepted competing lockfiles'
}

@test "nested npm projects are validated at their dependency root" {
nested_project=$(create_project nested)
mkdir -p "$nested_project/apps/web"
cat >"$nested_project/apps/web/package.json" <<'EOF'
{"name":"fixture","packageManager":"npm@11.10.0"}
EOF
touch "$nested_project/apps/web/package-lock.json"
printf 'min-release-age=7\n' >"$nested_project/apps/web/.npmrc"
write_dependabot "$nested_project" npm /apps/web
expect_success "$nested_project" 'nested npm project was not validated'
rm "$nested_project/apps/web/.npmrc"
expect_failure "$nested_project" 'nested npm project bypassed dependency policy'
}

@test "npm workspaces accept managed members and reject unmanaged packages" {
workspace_project=$(create_project workspace)
cat >"$workspace_project/package.json" <<'EOF'
{"name":"fixture","packageManager":"npm@11.10.0","workspaces":["packages/*"]}
EOF
touch "$workspace_project/package-lock.json"
printf 'min-release-age=7\n' >"$workspace_project/.npmrc"
mkdir -p "$workspace_project/packages/member"
cat >"$workspace_project/packages/member/package.json" <<'EOF'
{"name":"member"}
EOF
write_dependabot "$workspace_project" npm
expect_success "$workspace_project" 'npm workspace with a root lockfile was rejected'

unmanaged_nested_project=$(create_project unmanaged-nested)
cat >"$unmanaged_nested_project/package.json" <<'EOF'
{"name":"fixture","packageManager":"npm@11.10.0"}
EOF
touch "$unmanaged_nested_project/package-lock.json"
printf 'min-release-age=7\n' >"$unmanaged_nested_project/.npmrc"
mkdir -p "$unmanaged_nested_project/packages/member"
cat >"$unmanaged_nested_project/packages/member/package.json" <<'EOF'
{"name":"member"}
EOF
write_dependabot "$unmanaged_nested_project" npm
expect_failure "$unmanaged_nested_project" 'nested package without a lockfile or workspace declaration was accepted'
}

@test "uv dependency policy supports projects and workspaces" {
uv_project=$(create_project uv)
cat >"$uv_project/pyproject.toml" <<'EOF'
[project]
name = "fixture"
version = "0.1.0"

[tool.uv]
exclude-newer = "7 days"
EOF
touch "$uv_project/uv.lock"
write_dependabot "$uv_project" uv
expect_success "$uv_project" 'compliant uv policy was rejected'
printf 'exclude-newer = "0 days"\n' >"$uv_project/uv.toml"
expect_failure "$uv_project" 'uv.toml override bypassed the age gate'
rm "$uv_project/uv.toml"
rm "$uv_project/uv.lock"
expect_failure "$uv_project" 'Python policy accepted a missing uv.lock'

uv_workspace_project=$(create_project uv-workspace)
cat >"$uv_workspace_project/pyproject.toml" <<'EOF'
[project]
name = "fixture"
version = "0.1.0"

[tool.uv]
exclude-newer = "7 days"

[tool.uv.workspace]
members = ["packages/*"]
EOF
touch "$uv_workspace_project/uv.lock"
mkdir -p "$uv_workspace_project/packages/member"
cat >"$uv_workspace_project/packages/member/pyproject.toml" <<'EOF'
[project]
name = "member"
version = "0.1.0"
EOF
write_dependabot "$uv_workspace_project" uv
expect_success "$uv_workspace_project" 'uv workspace with a root lockfile was rejected'
}

@test "OSV exceptions require complete documentation" {
osv_project=$(create_project osv)
cat >"$osv_project/osv-scanner.toml" <<'EOF'
[[IgnoredVulns]]
id = "CVE-2026-0001"
reason = "Not reachable in this application"
ignoreUntil = 2026-09-01
EOF
expect_success "$osv_project" 'documented OSV exception was rejected'
sed -i.bak '/ignoreUntil/d' "$osv_project/osv-scanner.toml"
rm "$osv_project/osv-scanner.toml.bak"
expect_failure "$osv_project" 'OSV exception without an expiry was accepted'
}
