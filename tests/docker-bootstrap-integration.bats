#!/usr/bin/env bats

load test_helper.bash

setup() {
  bats_require_minimum_version 1.14.0
  [ "${RUN_DOCKER_BOOTSTRAP_INTEGRATION:-}" = 1 ] || skip 'set RUN_DOCKER_BOOTSTRAP_INTEGRATION=1 to run Docker integration'
  command -v docker >/dev/null 2>&1 || {
    printf 'docker is required when Docker integration is enabled\n' >&2
    return 1
  }
  docker info >/dev/null 2>&1 || {
    printf 'docker daemon is required when Docker integration is enabled\n' >&2
    return 1
  }
  root=$(repo_root)
  fixture=$BATS_TEST_TMPDIR/fixture
  mkdir -p "$fixture/scripts"
  cp "$root/skills/docker-bootstrap/assets/scripts/container-check" "$fixture/scripts/container-check"
  chmod +x "$fixture/scripts/container-check"
}

teardown() {
  [ "${RUN_DOCKER_BOOTSTRAP_INTEGRATION:-}" = 1 ] || return 0
  if [ -f "${fixture:-}/compose.yaml" ]; then
    docker compose -f "$fixture/compose.yaml" down --remove-orphans >/dev/null 2>&1 || :
  fi
  docker image rm \
    docker-bootstrap-go-integration:local \
    docker-bootstrap-python-integration:local >/dev/null 2>&1 || :
}

write_compose() {
  image_name=$1
  cat >"$fixture/compose.yaml" <<YAML
name: docker-bootstrap-integration-$BATS_TEST_NUMBER
services:
  app:
    build:
      context: .
      pull: true
    image: $image_name
YAML
}

@test "Minimus static and runtime fixtures pass while a vulnerable service fails" {
  cat >"$fixture/go.mod" <<'EOF'
module example.invalid/docker-bootstrap-integration

go 1.25
EOF
  cat >"$fixture/main.go" <<'EOF'
package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) == 2 && os.Args[1] == "--smoke" {
		fmt.Println("go smoke passed")
		return
	}
	select {}
}
EOF
  cat >"$fixture/Dockerfile" <<'EOF'
ARG GO_DEV_IMAGE=reg.mini.dev/go:1.25-dev
ARG STATIC_IMAGE=reg.mini.dev/static:latest
FROM ${GO_DEV_IMAGE} AS build
USER root
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/app .

FROM ${STATIC_IMAGE}
COPY --from=build /out/app /app
USER 1000
ENTRYPOINT ["/app"]
EOF
  printf '%s\n' '.git' '.env' >"$fixture/.dockerignore"
  write_compose docker-bootstrap-go-integration:local

  run bash -c 'cd "$1" && scripts/container-check' _ "$fixture"
  assert_success
  run docker compose -f "$fixture/compose.yaml" run --rm app --smoke
  assert_success
  [[ $output == *'go smoke passed'* ]]

  rm "$fixture/go.mod" "$fixture/main.go"
  cat >"$fixture/app.py" <<'EOF'
import sys
import time

if sys.argv[1:] == ["--smoke"]:
    print("python smoke passed")
else:
    time.sleep(3600)
EOF
  cat >"$fixture/Dockerfile" <<'EOF'
ARG PYTHON_DEV_IMAGE=reg.mini.dev/python:3.13-dev
ARG PYTHON_IMAGE=reg.mini.dev/python:3.13
FROM ${PYTHON_DEV_IMAGE} AS build
USER root
WORKDIR /build
COPY app.py ./

FROM ${PYTHON_IMAGE}
WORKDIR /app
COPY --from=build /build/app.py ./app.py
USER 1000
ENTRYPOINT ["/usr/bin/python", "/app/app.py"]
EOF
  write_compose docker-bootstrap-python-integration:local

  run bash -c 'cd "$1" && scripts/container-check' _ "$fixture"
  assert_success
  run docker compose -f "$fixture/compose.yaml" run --rm app --smoke
  assert_success
  [[ $output == *'python smoke passed'* ]]

  cat >>"$fixture/compose.yaml" <<'YAML'
  deliberately-vulnerable:
    image: alpine:3.10@sha256:451eee8bedcb2f029756dc3e9d73bab0e7943c1ac55cff3a4861c52a0fdd3e98
    command: ["true"]
YAML
  run bash -c 'cd "$1" && scripts/container-check' _ "$fixture"
  assert_failure
  [[ $output == *'CVE-'* ]]
}
