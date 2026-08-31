---
name: go-project-scaffold
description: Create a new, agent-ready Go command project with conventional layout, deterministic quality gates, security scanning, and GitHub Actions CI. Use when a user asks to initialize a new Go project; do not retrofit a non-empty repository.
license: MIT
---

# Scaffold an Agent-Ready Go Project

Create a new Go command project by running the bundled initializer. The
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
