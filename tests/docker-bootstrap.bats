#!/usr/bin/env bats

load test_helper.bash

setup() {
  bats_require_minimum_version 1.14.0
  root=$(repo_root)
  setup_test_tmpdir
  project=$TEST_TMPDIR/project
  mock_bin=$TEST_TMPDIR/mock-bin
  docker_log=$TEST_TMPDIR/docker.log
  socket_path=$TEST_TMPDIR/docker.sock
  mkdir -p "$project" "$mock_bin"
  : >"$docker_log"
  printf '%s\n' 'services:' '  app:' '    image: example/app:check' >"$project/compose.yaml"

  cp "$root/skills/docker-bootstrap/assets/scripts/container-check" "$project/container-check"
  chmod +x "$project/container-check"
  cp "$root/tests/fixtures/docker-bootstrap/mock-docker" "$mock_bin/docker"
  chmod +x "$mock_bin/docker"
}

frontmatter_value() {
  key=$1
  file=$2
  awk -v key="$key" '
    NR == 1 && $0 != "---" { exit 2 }
    NR > 1 && $0 == "---" { exit }
    index($0, key ":") == 1 {
      sub("^" key ":[[:space:]]*", "")
      print
      found = 1
    }
    END { if (!found) exit 1 }
  ' "$file"
}

run_gate() {
  run env \
    PATH="$mock_bin:$PATH" \
    MOCK_DOCKER_LOG="$docker_log" \
    MOCK_DOCKER_SOCKET="$socket_path" \
    MOCK_DOCKER_FAIL="${MOCK_DOCKER_FAIL:-}" \
    sh -c 'cd "$1" && ./container-check' _ "$project"
}

@test "docker-bootstrap declares its identity, existing-app boundary, and Minimus preflight" {
  skill=$root/skills/docker-bootstrap/SKILL.md
  [ "$(frontmatter_value name "$skill")" = docker-bootstrap ]
  [ "$(frontmatter_value license "$skill")" = MIT ]
  description=$(frontmatter_value description "$skill")
  [[ $description == *existing* ]]
  [[ $description == *Dockerfile* ]]
  grep -Fq 'Confirm the separately installed `minimus-dockerfile` skill is available.' "$skill"
  grep -Fq 'stop before editing and direct the user to install the' "$skill"
  grep -Fq 'There is no supported skill-to-skill dependency declaration' "$skill"
  ! grep -Fq 'allow_implicit_invocation: false' "$skill"
}

@test "skill requires canonical production-parity Compose and conservative collisions" {
  skill=$root/skills/docker-bootstrap/SKILL.md
  grep -Fq 'Create or minimally update `compose.yaml`' "$skill"
  grep -Fq 'obsolete top-level `version` key.' "$skill"
  grep -Fq 'Do not silently delete or convert existing development-oriented Compose' "$skill"
  grep -Fq 'request approval before replacing or' "$skill"
  grep -Fq 'no source bind mounts, development' "$skill"
  grep -Fq 'or development profiles' "$skill"
  grep -Fq '`image: <repository>:<version>@sha256:<multi-platform-digest>`' "$skill"
  grep -Fq 'require the user to select one' "$skill"
  [ ! -e "$root/skills/docker-bootstrap/assets/compose.yaml" ]
}

@test "container-check validates, pulls fresh bases, and scans every Compose image" {
  run_gate
  assert_success
  grep -Fq 'compose -f compose.yaml config --quiet' "$docker_log"
  grep -Fq 'compose -f compose.yaml build --pull app' "$docker_log"
  grep -Fq 'fs --scanners misconfig,secret --severity HIGH,CRITICAL --exit-code 1' "$docker_log"
  grep -Fq 'image --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 example/app:check' "$docker_log"
  grep -Fq 'image --scanners vuln,secret --severity HIGH,CRITICAL --exit-code 1 postgres:17@sha256:dependency' "$docker_log"
  [ "$(grep -c ' image --scanners vuln,secret ' "$docker_log")" -eq 2 ]
  grep -Fq 'volume rm mock-trivy-cache' "$docker_log"
}

@test "container-check isolates the canonical model from Compose overrides" {
  printf '%s\n' 'services:' '  app:' '    image: example/override:wrong' >"$project/compose.override.yaml"
  printf '%s\n' 'services:' '  app:' '    image: example/environment:wrong' >"$project/alternate.yaml"
  export COMPOSE_FILE=alternate.yaml

  run_gate
  assert_success
  [ "$(grep -c '^compose -f compose.yaml ' "$docker_log")" -eq 3 ]
}

@test "container-check propagates scanner failure and cleans its cache volume" {
  export MOCK_DOCKER_FAIL='postgres:17@sha256:dependency'
  run_gate
  assert_failure
  [ "$status" -eq 42 ]
  grep -Fq 'volume rm mock-trivy-cache' "$docker_log"
}

@test "container-check accepts only narrow unexpired YAML exceptions" {
  cat >"$project/.trivyignore.yaml" <<'YAML'
vulnerabilities:
  - id: CVE-2099-0001
    purls:
      - "pkg:apk/example/library@1.2.3" # reviewed package scope
    statement: Upstream fix is scheduled and this package path is not reachable.
    expired_at: 2099-12-31
YAML
  run_gate
  assert_success
  grep -Fq -- '--ignorefile /workspace/.trivyignore.yaml' "$docker_log"

  cat >"$project/.trivyignore.yaml" <<'YAML'
secrets:
  - id: generic-api-key
    paths:
      - "config/test-fixture.env" # reviewed fixture scope
    statement: The committed test fixture contains an inert scanner token.
    expired_at: 2099-12-31
YAML
  : >"$docker_log"
  run_gate
  assert_success

  cat >"$project/.trivyignore.yaml" <<'YAML'
vulnerabilities:
  - id: CVE-2099-0001
    statement: This deliberately broad exception has no scope.
    expired_at: 2099-12-31
YAML
  : >"$docker_log"
  run_gate
  assert_failure
  [[ $output == *'requires paths or purls scope'* ]]
  ! grep -Fq 'compose -f compose.yaml config --quiet' "$docker_log"
  ! grep -Fq 'volume create' "$docker_log"
}

@test "container-check rejects incompatible and whole-tree exception scopes" {
  cat >"$project/.trivyignore.yaml" <<'YAML'
secrets:
  - id: generic-api-key
    purls:
      - pkg:apk/example/library@1.2.3
    statement: A package cannot scope a secret finding.
    expired_at: 2099-12-31
YAML
  run_gate
  assert_failure
  [[ $output == *'purls scope is supported only for vulnerabilities'* ]]
  ! grep -Fq 'compose -f compose.yaml config --quiet' "$docker_log"

  cat >"$project/.trivyignore.yaml" <<'YAML'
misconfigurations:
  - id: DS002
    paths:
      - "**" # an inline comment must not hide a whole-tree pattern
    statement: A whole-tree pattern is deliberately too broad.
    expired_at: 2099-12-31
YAML
  : >"$docker_log"
  run_gate
  assert_failure
  [[ $output == *'paths entries must start with a literal relative path segment'* ]]
  ! grep -Fq 'compose -f compose.yaml config --quiet' "$docker_log"

  cat >"$project/.trivyignore.yaml" <<'YAML'
misconfigurations:
  - id: DS002
    paths:
      - "{**,config/test/**}"
    statement: Brace expansion must not hide a whole-tree alternative.
    expired_at: 2099-12-31
YAML
  : >"$docker_log"
  run_gate
  assert_failure
  [[ $output == *'paths entries must start with a literal relative path segment'* ]]
  ! grep -Fq 'compose -f compose.yaml config --quiet' "$docker_log"

  cat >"$project/.trivyignore.yaml" <<'YAML'
vulnerabilities:
  - id: CVE-2099-0001
    purls:
      - pkg:apk/%
    statement: Invalid package URLs must fail before scanning.
    expired_at: 2099-12-31
YAML
  : >"$docker_log"
  run_gate
  assert_failure
  [[ $output == *'purls entries must be valid pkg: package URLs'* ]]
  ! grep -Fq 'compose -f compose.yaml config --quiet' "$docker_log"
}

@test "container-check fails at Compose validation and does not create scan state" {
  export MOCK_DOCKER_FAIL='compose -f compose.yaml config --quiet'
  run_gate
  assert_failure
  [ "$status" -eq 42 ]
  ! grep -Fq 'compose build' "$docker_log"
  ! grep -Fq 'volume create' "$docker_log"
}
