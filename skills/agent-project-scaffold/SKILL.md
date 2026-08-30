---
name: agent-project-scaffold
description: Create a new stack-neutral software project with portable agent workflow skills, PRD tooling, repository checks, and security defaults. Use when the user asks to initialize or scaffold a new agent-ready project; do not use to merge the scaffold into an existing non-empty repository.
---

# Scaffold an Agent-Ready Project

Create the requested project by running the deterministic initializer bundled
with this skill. The initializer stages the project template, installs this
parent skill's runtime bundle into the requested agents' native project paths,
initializes a local `main` branch, and validates the generated files.

## Requirements

The initializer requires a POSIX shell, Git, standard Unix utilities, Node.js
22.20+, and network access for `npx skills@1.5.23`. It supports new or
otherwise-empty target directories.

Require an explicit target directory and one or more supported agent identifiers
before making changes. A display name is optional; when omitted, the initializer
derives it from the target directory. Do not infer or install every possible
agent: ask which agents should use the generated project.

Run from this skill directory:

```sh
scripts/init-agent-project [--name <display-name>] \
  --agent <agent> [--agent <agent> ...] <target-directory>
```

The target must not exist, be empty, or be an otherwise-empty Git repository.
Do not bypass this restriction, merge files manually, or overwrite an existing
project. If the user wants to retrofit an existing repository, explain that this
skill does not support that operation.

The initializer does not create commits, remotes, or other external state. It
does not copy this bootstrap skill or sibling scaffolds into the project. On
success, relay its generated-project path and its `make setup` next step.
