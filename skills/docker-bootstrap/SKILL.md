---
name: docker-bootstrap
description: Dockerize, migrate, or harden an existing non-empty application repository with a production-parity Dockerfile, canonical Compose model, build-context exclusions, and a Trivy security gate. Use for existing applications; do not use to create an empty application project or production deployment platform.
license: MIT
---

# Bootstrap Application Containers

Add or conservatively improve container assets in an existing application
repository. Compose is for production-runtime parity and local verification; it
is not a production deployment system. Live-development profiles, Kubernetes,
Helm, publishing, SBOM generation, and Checkov are out of scope.

## Preflight Before Editing

1. Confirm the repository is a non-empty application repository.
2. Require `docker`, Compose v2 (`docker compose version`), a reachable daemon,
   and a local `unix://` Docker endpoint. Stop before mutation when any is
   unavailable; a remote or non-POSIX endpoint cannot support the packaged
   scanner's socket mount.
3. Confirm the separately installed `minimus-dockerfile` skill is available.
   If it is missing, stop before editing and direct the user to install the
   Minimus plugin. There is no supported skill-to-skill dependency declaration,
   so do not invent dependency metadata.
4. Inspect application manifests and lockfiles, documented and configured start
   commands, listening ports, environment-variable reads, writable paths,
   existing Docker/Compose files, CI, and evidenced database/cache clients.
   Distinguish runtime dependencies from test and development dependencies.
5. Ask only when the runtime contract remains ambiguous or repository evidence
   does not establish a supporting service's major version.

Complete the preflight and resolve required questions before changing files.
Never infer a database or cache merely because one is common for the stack.

## Application Dockerfile

Delegate all application `Dockerfile` or `Containerfile` creation, migration,
and hardening to `minimus-dockerfile`; follow that skill completely. Its work
includes live image and tag discovery, runtime-contract and shell inspection,
package resolution, behavior-preserving multi-stage construction, a build and
runtime smoke test, and the CVE-reduction report. Do not substitute an upstream
application runtime image, invent a Minimus image/tag, or duplicate a weaker
Dockerfile workflow here.

Supporting database and cache containers are the exception: use their official
upstream images, not Minimus images. Pin each as
`image:<version>@sha256:<multi-platform-digest>`. Resolve the current digest from
the publisher or registry and preserve the human-readable version tag. If the
repository does not establish a major version, require the user to select one
before writing Compose.

## Compose Runtime Model

Create or minimally update `compose.yaml`, Docker's canonical filename. Do not
add the obsolete top-level `version` key. Define an `app` service using the
hardened application build/image and add only evidenced supporting services.

- Model production runtime behavior: no source bind mounts, development
  commands, hot reload, or development profiles.
- Do not silently delete or convert existing development-oriented Compose
  behavior. Explain the collision and request approval before replacing or
  splitting it. Preserve unrelated services and behavior in existing assets.
- Add named volumes only for evidenced persistent runtime state. Do not create
  volumes for application source or dependency caches.
- Publish only ports needed for the requested local verification. Keep secrets
  out of Compose and source control.
- Add an exec-form health check only after verifying its executable exists in
  that exact image. Use long-form `depends_on` with
  `condition: service_healthy` only for dependencies that have such a verified
  health check; otherwise use ordinary dependency ordering or application
  retry behavior.
- Create `.env.example` only when Compose interpolation is required. Include
  safe placeholders or non-secret defaults, never working credentials. Do not
  create or commit `.env`.

Validate the result with `docker compose config --quiet`.

## Build Context and Security Gate

Create or merge `.dockerignore`. Preserve existing rules and exclude Git
metadata, secret files, local dependency directories, editor/OS files, caches,
coverage, logs, and build output. Check every proposed pattern against all
Dockerfile `COPY`/`ADD` inputs; required manifests, lockfiles, source, generated
runtime assets, and build inputs must remain in context. Prefer specific secret
patterns over a broad rule that would exclude `.env.example`.

Copy [assets/scripts/container-check](assets/scripts/container-check) to
`scripts/container-check` in the target, preserving executable mode. If that
path already exists, inspect it and make the smallest behavior-preserving merge;
do not overwrite it. The command validates Compose, rebuilds `app` with fresh
base-image resolution, scans repository container configuration and secrets,
and scans every Compose image for HIGH/CRITICAL vulnerabilities and embedded
secrets with pinned Trivy. It does not suppress unfixed vulnerabilities.

Do not add broad exceptions. `.trivyignore.yaml` is the only supported exception
file. Every entry must identify one finding, have a path or package (`purl`)
scope, a non-empty `statement` justification, and an ISO expiration date. The
packaged command rejects expired or structurally broad entries. Remove an
exception when its finding is fixed.

## CI and Handoff

When a recognized CI pipeline already exists and can safely run a local Docker
daemon, wire `scripts/container-check` into it with least-privilege permissions.
Pin third-party CI actions according to the repository's existing policy. If no
CI exists, or Docker execution cannot be inferred safely, document the stable
`scripts/container-check` command without introducing a CI provider.

Run the packaged gate after the Minimus build/smoke test. Report files created
or minimally changed, supporting-service evidence and pinned references,
published Minimus CVE reduction, verification results, and any unresolved
development-Compose collision. Never create commits, registry state, or real
credentials unless the user separately requests and authorizes them.
