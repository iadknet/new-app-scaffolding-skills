# __PROJECT_NAME__

This repository starts with a stack-neutral project foundation. The first active
PRD defines the goal, audience, constraints, researched stack alternatives, and
the follow-on work that will make the application targets real.

## Start here

```sh
# One-time bootstrap: https://aquaproj.github.io/docs/install/
brew install aqua # macOS with Homebrew
make setup
make check
```

Then read [the project foundation PRD](docs/prds/active/project-foundation/master-prd.md)
and [the contributor guide](CONTRIBUTING.md).

`make setup` requires Aqua v2.60.1+, `uv`, and network access. Install Aqua
once using its [platform-specific instructions](https://aquaproj.github.io/docs/install/)
(for example, `brew install aqua` on macOS with Homebrew). Aqua installs the
pinned release-binary tools from `aqua.yaml` and `aqua-checksums.json`; the
Python tool resolution uses a seven-day release-age window.

## Workflow skills

The initializer has installed four project-scoped workflow skills for the
agent(s) selected during project creation. `make setup` installs quality and
security tools through Aqua, not skills.

Use your agent's skill interface to inspect and invoke `project-workflow`,
`prd-create`, `prd-review`, and `prd-implement`. Start with
`project-workflow` when the current PRD state should select the appropriate
phase.

## Changelog

Before tagging a release, generate and review its entry:

```sh
make changelog VERSION=v0.1.0
```

The generator groups `feat` commits under Added, `fix` commits under Fixed, and
other non-merge commits under Changed.

## Stable commands

Run `make help` for the complete interface. `check`, `audit`, `precommit`,
`prd-check`, and `dependency-audit` retain stable meanings. Before setup,
`check` runs dependency-free validation and clearly reports that extended checks
were skipped. After setup, it also runs pinned ShellCheck, actionlint, Cisco AI
Skill Scanner, and OSV-Scanner. OSV-Scanner checks supported dependency lockfiles
when the selected stack adds them. For a selected Node stack, `check` also verifies
the declared package-manager binary and its effective project configuration. The
skill scanner uses deterministic behavioral
and trigger analysis and blocks HIGH or CRITICAL findings; LLM analysis is not
enabled. `run`, `build`, `test`, `lint`,
`format`, and `clean` intentionally remain successful placeholders until the
selected-stack PRD replaces them.
