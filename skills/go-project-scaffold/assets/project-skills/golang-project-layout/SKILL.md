---
name: golang-project-layout
description: Choose an idiomatic Go module and package layout from the project's actual library, command, server, or mixed role.
license: MIT
---

# Go Project Layout

Keep one module at the repository root unless independently versioned modules
are an explicit requirement. Choose the source layout only after the project's
role is known:

- A small importable package or single command may live at the module root.
- Multiple commands, mixed packages and commands, or servers with substantial
  non-Go assets may place commands under `cmd/<name>`.
- Implementation packages that must not be imported by other modules belong
  under `internal/`.

Add directories only for concrete responsibilities. Do not create `cmd`,
`internal`, `pkg`, `api`, or layered folders preemptively.
