# __PROJECT_NAME__

This repository starts with a stack-neutral project foundation. The first active
PRD defines the goal, audience, constraints, researched stack alternatives, and
the follow-on work that will make the application targets real.

## Start here

```sh
make setup
make check
```

Then read [the project foundation PRD](docs/prds/active/project-foundation/master-prd.md)
and [the contributor guide](CONTRIBUTING.md).

`make setup` requires `uv` and network access to install the pinned Python tools.

## Workflow skills

The initializer has installed four project-scoped workflow skills for the
agent(s) selected during project creation. `make setup` installs quality and
security tools, not skills.

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

Run `make help` for the complete interface. `check`, `audit`, `precommit`, and
`prd-check` retain stable meanings. Before setup, `check` runs dependency-free
validation and clearly reports that extended checks were skipped. After setup,
it also runs pinned ShellCheck and actionlint. `run`, `build`, `test`, `lint`,
`format`, and `clean` intentionally remain successful placeholders until the
selected-stack PRD replaces them.
