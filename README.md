# Secure Agentic Project Scaffolding

[![Tests](https://github.com/iadknet/new-app-scaffolding-skills/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/iadknet/new-app-scaffolding-skills/actions/workflows/test.yml?query=branch%3Amain)
[![License: MIT](https://img.shields.io/github/license/iadknet/new-app-scaffolding-skills)](LICENSE)

This project provides reusable agent skills and scripts for initializing new
coding projects with a secure, repeatable baseline. It is for developers
starting agentic coding projects who want essential tooling, workflow guidance,
and guardrails in place before application code begins to accumulate.

I created it to give new agentic coding projects a secure baseline of tools and
guardrails from the start, with particular attention to software supply-chain
protections, dependency integrity, vulnerability detection, secret scanning,
hardened GitHub Actions, and clear agent-facing development workflows.

The scaffolding workflows are intentionally designed for new repositories, not
for retrofitting existing projects. Their templates, policies, and skills can
still serve as a reference when guiding an agent through an ad-hoc retrofit, but
that path is not automated or guaranteed. `docker-bootstrap` is the deliberate
exception: it adds container tooling to an existing application.

## What this project provides

- A framework-neutral foundation for a new agentic coding project.
- An architecture-neutral Go module foundation with Go-specific tooling and
  guardrails.
- Portable project skills for planning, reviewing, and implementing work from
  repository-validated PRDs.
- Pinned development and security tooling with local and CI checks.
- An additive workflow for containerizing an existing application with Minimus,
  Docker Compose, and Trivy.

## Choose a workflow

| Skill | Target | Use it when |
| --- | --- | --- |
| `agent-project-scaffold` | New, empty repository | You want a framework-neutral project foundation with security controls, repository policy, and agent workflow skills. |
| `go-project-scaffold` | New, empty repository | You want an architecture-neutral Go module with Go-specific skills, quality gates, hooks, vulnerability scanning, and CI, without generated application source or an assumed package layout. |
| `docker-bootstrap` | Existing application | You want to add or harden a production-parity Dockerfile, canonical `compose.yaml`, build-context exclusions, and a Trivy gate. |

The two project scaffolds do not merge into non-empty repositories. They also do
not install one another: each owns its template and runtime-skill bundle.

## Quick start

Until the first release is published, clone this repository and install the
skill you want from the local checkout. The scaffold initializers require a
POSIX shell, Git, Node.js 22.20+, and network access for the pinned Agent Skills
installer.

```sh
git clone https://github.com/iadknet/new-app-scaffolding-skills.git
cd new-app-scaffolding-skills

npx skills@1.5.23 add . --skill agent-project-scaffold --global
# Or:
npx skills@1.5.23 add . --skill go-project-scaffold --global
```

Then ask your agent to use the installed skill. Name the target directory and
the agents that should receive the generated project's private skills. The Go
scaffold also requires a module path.

For example:

```text
Use agent-project-scaffold to create "Example Project" at ../example-project
for Codex and Claude Code.
```

```text
Use go-project-scaffold to create an architecture-neutral Go module foundation
at ../example-go with module path example.com/acme/example-go for Codex.
```

After initialization:

```sh
cd ../example-project
brew install aqua # macOS with Homebrew; see Aqua docs for other platforms
make setup
make check
```

Generated projects require [Aqua](https://aquaproj.github.io/docs/install/)
v2.60.1 or newer. `make setup` creates project-local proxy links, downloads the
pinned tools after checksum verification, and configures pre-commit hooks. The
initializer creates a local `main` branch but never creates a commit or remote.

To run the initializers directly from a checkout instead of installing the
skills:

```sh
bin/init-agent-project --name "Example Project" \
  --agent codex --agent claude-code \
  ../example-project

bin/init-go-project --module example.com/acme/example-go \
  --agent codex \
  ../example-go
```

Targets must not exist, be empty, or be otherwise-empty Git repositories.

### Dockerizing an existing application

Install `docker-bootstrap` independently:

```sh
npx skills@1.5.23 add . --skill docker-bootstrap --global
```

This workflow also requires Docker with Compose v2 and the Minimus plugin that
provides `minimus-dockerfile`. It stops before editing if those prerequisites
are unavailable.

## Security baseline

The framework-neutral scaffold establishes controls that do not depend on an
application stack. Stack- and release-specific controls remain explicit
follow-up work rather than being implied by the foundation.

| Area | Baseline | Enforcement |
| --- | --- | --- |
| Tool acquisition | Node, uv, and security and quality tools are pinned in Aqua and verified against committed SHA-256 checksums on first use. | `make setup`, `aqua.yaml`, and `aqua-checksums.json` |
| Dependency integrity | Node and Python dependency roots require a committed lockfile, an exact supported package-manager version, and consistent workspace ownership. | `scripts/dependency-policy-check` through `make check` |
| Dependency freshness | New npm, pnpm, Yarn, and uv resolutions observe a seven-day package-age gate paired with a Dependabot cooldown. | Package-manager configuration and `.github/dependabot.yml` validation |
| Vulnerability management | Supported lockfiles are scanned for known vulnerabilities; exceptions must identify one vulnerability and include a reason and expiration. | OSV-Scanner through `make dependency-audit` and `make check` |
| Secret protection | Staged changes are scanned before commit and Git history is scanned in CI with redacted output. | Gitleaks through pre-commit, `make precommit`, and `make audit` |
| Agent-skill safety | Project skills receive deterministic behavioral, trigger, and overlap analysis; HIGH and CRITICAL findings block checks. | Cisco AI Skill Scanner through pre-commit, `make check`, and CI |
| GitHub Actions hardening | Workflows use read-only contents permissions, disallow job-level permission overrides, pin actions to full commit SHAs, and do not persist checkout credentials. | `scripts/policy-check`, actionlint, and offline zizmor analysis |
| Local/CI parity | Project policy, PRD, quality, skill, dependency, and secret checks are available locally and in CI. | Stable `make` targets and pre-commit hooks |

The generated [security policy](skills/agent-project-scaffold/assets/template/SECURITY.md)
documents dependency acquisition, registries, vulnerability exceptions, and
private reporting. Controls that depend on the chosen stack or release model—
including SBOMs, provenance, CodeQL, dependency review, Scorecard, and repository
rulesets—are intentionally deferred until the necessary context exists.

## Generated-project workflow

The framework-neutral scaffold installs five private runtime skills into the
agent locations selected during initialization:

| Skill | Role |
| --- | --- |
| `project-workflow` | Inspect PRD state and route work to the correct phase. |
| `prd-create` | Research and create a master PRD with dependency-ordered stage PRDs. |
| `prd-review` | Review PRD readiness or completed implementation with P1/P2/P3 findings. |
| `prd-implement` | Implement an approved PRD in stage order and record verification evidence. |
| `public-repo-readiness` | Prepare documentation, badges, licensing, and applicable community files for public GitHub use. |

Generated projects treat PRDs as executable, repository-validated workflow
state. The initializer seeds a `project-foundation` PRD so stack selection begins
with goals, constraints, research, and observable decisions.

1. Use `prd-create` to create the master and stage PRDs.
2. Use `prd-review` to establish implementation readiness. P1 and P2 findings
   require revision; a clean review marks the PRD `Ready` and `APPROVED`.
3. Use `prd-implement` to complete approved stages in dependency order while
   keeping verification evidence and durable documentation current.
4. Use `prd-review` for the final-code gate.
5. Run `make check`, then archive the completed PRD with
   `scripts/prd-archive <slug>`.

`scripts/prd-check` enforces required sections, status consistency, dependency
order, documentation synchronization, readiness-review limits, generated
indexes, and a 750-line limit per PRD.

## Repository architecture

This repository distributes scaffolds; it is not itself an initialized
application project.

- `skills/agent-project-scaffold/` contains the framework-neutral bootstrap,
  its generated-project template, and its private runtime-skill bundle.
- `skills/go-project-scaffold/` contains the Go bootstrap, template, and
  Go-specific runtime skills.
- `skills/docker-bootstrap/` contains the additive container workflow for
  existing applications.
- `bin/` provides direct wrappers around the project initializers.
- `tests/` validates initializer behavior, generated output, policies, and skill
  contracts with Bats-core.

Only a scaffold's `assets/template/` content is copied into a generated project.
Its runtime skills are installed separately into the selected agents' native
project paths. Parent bootstrap skills and sibling scaffold bundles are not
copied into the generated project.

## Development

```sh
make setup
make check
make test
```

`make setup` installs the pinned development, pre-commit, and security tools.
`make check` runs the offline distribution checks, test suite, and deterministic
skill scan.

External-tool and distribution integration tests are separate:

```sh
make test-integration
make test-distribution
```

The Docker/Trivy integration fixture is opt-in because it pulls and builds
container images:

```sh
RUN_DOCKER_BOOTSTRAP_INTEGRATION=1 make test-docker-integration
```

## Releases

Releases are repository-wide stable Semantic Versioning tags, beginning with
`v0.1.0`. A tag pins every scaffold and its private runtime-skill bundle to one
source revision. See [RELEASING.md](RELEASING.md) for the changelog, validation,
tagging, and GitHub Release procedure.

After `v0.1.0` is published, install its immutable source revision with:

```sh
npx skills@1.5.23 add iadknet/new-app-scaffolding-skills#v0.1.0 \
  --skill agent-project-scaffold \
  --global
```

## Contributing and support

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and pull-request
expectations, [SUPPORT.md](SUPPORT.md) for help routes, and the
[Code of Conduct](CODE_OF_CONDUCT.md) for community expectations. Report
security vulnerabilities through the private process in
[SECURITY.md](SECURITY.md), not in a public issue.

## License

The scaffold distributor and its bundled skills are available under the
[MIT License](LICENSE). Generated application projects do not receive an
application license automatically; their owners must choose one explicitly.
