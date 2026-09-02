---
name: go-project-scaffold
description: Create a new, agent-ready Go module with deterministic quality gates, security scanning, GitHub Actions CI, and no assumed application architecture. Use when a user asks to initialize a new Go project; do not retrofit a non-empty repository.
license: MIT
---

# Scaffold an Agent-Ready Go Module

Create a new Go module foundation by running the bundled initializer. It adds
the module definition, Go-specific agent skills, pinned development tools,
quality and security checks, Git hooks, and CI without generating application
source or choosing a command, library, server, or package layout. The
initializer requires an explicit Go module path and at least one agent because
both are fundamental generated-project configuration, not defaults to guess.

```sh
scripts/init-go-project --module example.com/acme/widget \
  --agent codex --agent claude-code ../widget
```

The target must be new, empty, or an otherwise-empty Git repository. The
initializer installs only this skill's runtime Go skills into the selected
agents' native project paths. It creates no commit, remote, or external state.

After initialization, run `make setup`, then `make check`.
