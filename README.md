# Lean Agent Project Scaffolding

This repository contains an initializer for new, stack-agnostic software
projects. It creates agent-portable workflow skills, PRD tooling, repository
policy checks, pinned shell/workflow analysis, and secret scanning without
selecting an application framework.

## Repository boundary

This repository is the scaffold distributor, not an initialized application
project:

- `skills/agent-project-scaffold/` is the portable bootstrap skill. Its bundled
  script creates a new project from `assets/template/` and installs its private
  `assets/project-skills/` bundle into the selected agents' native project paths.
- `bin/init-agent-project` is a wrapper around that same bundled initializer.
- `tests/` validates both the initializer and the generated output with Bats-core.
- The root `Makefile` develops and tests the distributor. The `Makefile` under
  the skill's bundled template becomes the generated project's command interface.

Only `assets/template/` is copied into a generated project. A parent scaffold's
runtime skills remain private to that parent until its initializer installs them
through `skills`; neither the bootstrap skill nor sibling scaffold bundles are
copied into the generated project.

Future stack-specific scaffolds are sibling bootstrap skills. Each owns its
template and runtime-skill bundle, so installing or invoking one cannot install
another scaffold's skills.

`skills/go-project-scaffold/` is the first stack-specific sibling. It creates a
single-module Go command project with tight static feedback, native Git hooks,
dependency vulnerability scanning, a non-blocking mutation-testing pilot, and
GitHub Actions CI.

## Security defaults

The generated project starts with security controls that do not depend on an
application stack. Stack- and release-specific controls remain explicit follow-up
work rather than being implied by the foundation.

| Area | Practice implemented by the template | Enforcement |
| --- | --- | --- |
| Tool acquisition | Security and quality tools are version-pinned in Aqua and verified against committed SHA-256 checksums. | `make setup`, `aqua.yaml`, and `aqua-checksums.json` |
| Dependency integrity | Node and Python dependency roots require a committed lockfile, an exact supported package-manager version, and consistent workspace ownership. | `scripts/dependency-policy-check` through `make check` |
| Dependency freshness | New npm, pnpm, Yarn, and uv resolutions must observe a seven-day package-age gate, paired with a seven-day Dependabot cooldown. | Native package-manager configuration checks and `.github/dependabot.yml` validation |
| Vulnerability management | Supported lockfiles are scanned for known vulnerabilities. Exceptions must name one vulnerability and include a reason and expiration; broad package overrides are rejected. | OSV-Scanner through `make dependency-audit` and `make check` |
| Secret protection | Staged changes are scanned before commit and the complete Git history is scanned in CI. Scan output is redacted. | Gitleaks through pre-commit, `make precommit`, and `make audit` |
| Agent-skill safety | Project skills receive deterministic behavioral, trigger, and overlap analysis. HIGH and CRITICAL findings block the check; LLM analysis is not part of the blocking path. | Cisco AI Skill Scanner through pre-commit, `make check`, and a dedicated CI job |
| GitHub Actions hardening | Workflows must declare read-only `contents` permission, may not override it at job level, and must pin actions to full commit SHAs. Checkout credentials are not persisted. | `scripts/policy-check`; offline zizmor analysis runs in CI |
| Local/CI parity | The same project policy, PRD, quality, skill, dependency, and secret checks are available locally and in CI. | The stable `make` interface and the standard pre-commit framework |
| Deferred release controls | SBOMs, provenance attestations, CodeQL, dependency review, Scorecard, and repository rulesets are intentionally deferred until the stack, visibility, artifact, and GitHub plan are known. | Documented in the generated `SECURITY.md` and selected-stack PRD |

### Included security and quality tooling

| Tool | Pinned version | Role in a generated project |
| --- | --- | --- |
| Gitleaks | 8.30.1 | Scans staged changes and Git history for secrets |
| OSV-Scanner | 2.4.0 | Scans supported dependency lockfiles for known vulnerabilities |
| Cisco AI Skill Scanner | 2.0.13 | Scans installed project skills and blocks HIGH or CRITICAL findings |
| ShellCheck | 0.11.0 | Statically analyzes the template's POSIX shell scripts |
| actionlint | 1.7.12 | Validates GitHub Actions workflows and invokes the pinned ShellCheck binary for embedded shell |
| pre-commit | 4.5.1 | Runs project validation and skill scanning from the standard Git hook framework |
| zizmor | 1.29.0 | Performs offline GitHub Actions security analysis in CI |
| uv | 0.12.3 in CI | Installs pinned Python-based tools with a seven-day release-age constraint |

The generated [security policy](skills/agent-project-scaffold/assets/template/SECURITY.md)
contains the complete dependency acquisition, registry, exception, and private
vulnerability-reporting guidance.

## Skills

The bootstrap skill creates the project; five private runtime skills are then
installed only for the agents selected during initialization.

| Skill | Scope | Use it for |
| --- | --- | --- |
| `agent-project-scaffold` | User/global bootstrap skill | Create a new, empty agent-ready project and install the selected agents' runtime skills. It does not retrofit existing repositories. |
| `go-project-scaffold` | User/global bootstrap skill | Create a new Go command project with Go-specific skills, quality gates, hooks, and CI. It requires a Go module path. |
| `project-workflow` | Generated project | Inspect current PRD state and route work to creation, readiness review, implementation, final review, or archival. |
| `prd-create` | Generated project | Research, create, or materially revise a master PRD and dependency-ordered stage PRDs without implementing product code. |
| `prd-review` | Generated project | Review a PRD for implementation readiness or review completed code, reporting P1/P2/P3 findings and enforcing revision gates. |
| `prd-implement` | Generated project | Implement an approved PRD in stage order, maintain truthful status and verification evidence, synchronize documentation, and prepare it for final review. |
| `public-repo-readiness` | Generated project | Prepare public-facing documentation, badges, licensing, and applicable community files without changing product or repository-admin configuration. |

## PRD workflow

Generated projects treat PRDs as executable, repository-validated workflow
state. The initializer seeds a `project-foundation` PRD so stack selection begins
with goals, constraints, research, and observable decisions instead of framework
assumptions.

1. **Create:** invoke `prd-create`, which uses `scripts/prd-new` to create one
   master PRD and one or more dependency-ordered stage PRDs under
   `docs/prds/active/<slug>/`.
2. **Review for readiness:** invoke `prd-review`. P1 and P2 findings require
   revision; a clean review sets the PRD and its stages to `Ready` and its inline
   `Review Status` to `APPROVED`. Automated readiness review is capped at three
   attempts before human intervention is required.
3. **Implement:** invoke `prd-implement` only for an approved `Ready` or
   `In Progress` PRD. Complete stages in order, record verification evidence,
   and keep affected durable documentation synchronized.
4. **Review the implementation:** invoke `prd-review` for the final-code gate.
   P1 and P2 findings block completion; the review reruns the checks declared by
   affected stages and does not alter the readiness review count.
5. **Validate and archive:** run `make check`, then
   `scripts/prd-archive <slug>`. Archival succeeds only for a complete, valid PRD
   set and rolls back the move if post-archive validation fails.

`scripts/prd-check` enforces required sections, status and checkbox consistency,
dependency order, documentation synchronization gates, the three-review cap,
generated indexes, and a 750-line limit per PRD. Use
`project-workflow` when the appropriate phase is not already clear from the
current state.

## Create a project

```sh
bin/init-agent-project --name "Example Project" \
  --agent codex --agent claude-code \
  ../example-project
cd ../example-project
# One-time bootstrap: https://aquaproj.github.io/docs/install/
brew install aqua # macOS with Homebrew
make setup
```

The target must not exist, be empty, or be an otherwise-empty Git repository.
Provide one or more `--agent` values supported by the pinned `skills` CLI. The
initializer requires POSIX shell tools, Git, Node.js 22.20+, and network access
for the pinned installer. It builds and validates a staging project before it
replaces the target, creates a local `main` branch, and never creates a commit
or remote. `make setup` additionally requires [Aqua](https://aquaproj.github.io/docs/install/)
v2.60.1+ and `uv`. Install Aqua once using its platform-specific instructions
(for example, `brew install aqua` on macOS with Homebrew); Aqua then installs
the project tools from the committed `aqua.yaml` and `aqua-checksums.json`, and
setup configures the standard pre-commit framework.

This initializer supports new projects only. It does not install the scaffold or
its skills into an existing, non-empty repository.

## Install as an agent skill

Until the first release is published, install a local checkout with the
multi-agent Agent Skills installer:

```sh
npx skills@1.5.23 add . --skill agent-project-scaffold --global
```

Then ask the agent to use `agent-project-scaffold` to create a named project at
an explicit target directory and name the target agents. The installed skill
runs the same bundled initializer as `bin/init-agent-project`.

After `v0.1.0` is published, install its immutable source revision with:

```sh
npx skills@1.5.23 add iadknet/new_app_scaffolding_skills#v0.1.0 \
  --skill agent-project-scaffold \
  --global
```

## Releases

Releases are repository-wide stable SemVer tags, beginning with `v0.1.0`. A tag
pins every parent scaffold and its private runtime-skill bundle to one immutable
source revision. Generate and review the corresponding [CHANGELOG.md](CHANGELOG.md)
section before running the checks and publishing a GitHub Release after tag CI
passes; the exact procedure is in [RELEASING.md](RELEASING.md).

## Development

```sh
make setup
make check
make test
```

`make setup` is the one-time development bootstrap. Test and quality targets use
the pinned local Bats-core and analysis tools and fail with an actionable error
until setup has installed them.

Real external-tool integration is separate from the offline default test suite:

```sh
make test-integration
make test-distribution
```

The integration target installs the pinned Aqua release-binary tools and Python
tools, then verifies their executable layouts, hook installation, and end-to-end
detection behavior.
Cisco AI Skill Scanner runs with deterministic analyzers in `make check`,
pre-commit, and a dedicated GitHub Actions job; LLM analysis is not enabled by
default.
`test-distribution` installs a local bootstrap copy through `npx skills` and
verifies the installed initializer's generated project.

## License

The scaffold distributor and its bundled skills are available under the
[MIT License](LICENSE). Generated application projects do not receive an
application license automatically; their owners must choose one explicitly.
