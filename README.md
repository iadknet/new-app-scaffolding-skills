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
- `tests/` validates both the initializer and the generated output.
- The root `Makefile` develops and tests the distributor. The `Makefile` under
  the skill's bundled template becomes the generated project's command interface.

Only `assets/template/` is copied into a generated project. A parent scaffold's
runtime skills remain private to that parent until its initializer installs them
through `skills`; neither the bootstrap skill nor sibling scaffold bundles are
copied into the generated project.

Future stack-specific scaffolds are sibling bootstrap skills. Each owns its
template and runtime-skill bundle, so installing or invoking one cannot install
another scaffold's skills.

## Create a project

```sh
bin/init-agent-project --name "Example Project" \
  --agent codex --agent claude-code \
  ../example-project
cd ../example-project
make setup
```

The target must not exist, be empty, or be an otherwise-empty Git repository.
Provide one or more `--agent` values supported by the pinned `skills` CLI. The
initializer requires POSIX shell tools, Git, Node.js 22.20+, and network access
for the pinned installer. It builds and validates a staging project before it
replaces the target, creates a local `main` branch, and never creates a commit
or remote. `make setup` installs pinned quality and security tools and configures
Git hooks.

This initializer supports new projects only. It does not install the scaffold or
its skills into an existing, non-empty repository.

## Install as an agent skill

Install a released bootstrap skill with the multi-agent Agent Skills installer,
selecting user/global scope so it can create a separate empty project:

```sh
npx skills@1.5.23 add iadknet/new_app_scaffolding_skills#v0.1.0 \
  --skill agent-project-scaffold \
  --global
```

Then ask the agent to use `agent-project-scaffold` to create a named project at
an explicit target directory and name the target agents. The installed skill
runs the same bundled initializer as `bin/init-agent-project`.

`v0.1.0` is the first planned release; until it exists, use a local checkout for
development:

```sh
npx skills@1.5.23 add . --skill agent-project-scaffold --global
```

## Releases

Releases are repository-wide stable SemVer tags, beginning with `v0.1.0`. A tag
pins every parent scaffold and its private runtime-skill bundle to one immutable
source revision. Generate and review the corresponding [CHANGELOG.md](CHANGELOG.md)
section before running the checks and publishing a GitHub Release after tag CI
passes; the exact procedure is in [RELEASING.md](RELEASING.md).

## Development

```sh
make check
make test
```

Real external-tool integration is separate from the offline default test suite:

```sh
make test-integration
make test-distribution
```

The integration target downloads the pinned release archives and verifies their
checksums, executable layouts, and end-to-end detection behavior.
`test-distribution` installs a local bootstrap copy through `npx skills` and
verifies the installed initializer's generated project.
