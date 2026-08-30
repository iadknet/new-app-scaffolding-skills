---
name: golang-project-layout
description: Apply conventional Go module, cmd, and internal package layout when starting or reorganizing this project.
license: MIT
---

# Go Project Layout

Keep one module at the repository root. Commands live in `cmd/<name>` and
non-public implementation packages live in `internal/`. Add directories only
for concrete responsibilities; do not create `pkg`, `api`, or layered folders
preemptively.
