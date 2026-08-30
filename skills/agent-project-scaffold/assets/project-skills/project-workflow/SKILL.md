---
name: project-workflow
description: Route repository work through PRD creation, readiness review, ordered implementation, final review, and archival based on the current PRD state.
---

# Project Workflow

Inspect `AGENTS.md`, `docs/prds/active/`, and the user's requested outcome, then
select the narrowest applicable workflow:

- No applicable PRD, or a material scope/design change: use `$prd-create`.
- `Draft` PRD with `Review Status: DRAFT` and fewer than three reviews: use
  `$prd-review` for readiness.
- `Draft` PRD with three reviews and unresolved P1/P2 findings: stop for human
  intervention.
- `Ready` or `In Progress` PRD with `Review Status: APPROVED`: use
  `$prd-implement`.
- Implemented stages awaiting final review: use `$prd-review` for final code.
- `Complete` PRD: validate and archive through `scripts/prd-archive`.

Run only phases authorized by the user. Creating or reviewing a plan does not by
itself authorize implementation, commits, remotes, or external changes. When a
phase reveals a material mismatch, move back to the appropriate earlier skill and
preserve truthful statuses and checkboxes.

The inline readiness status, three-review cap, documentation synchronization
gate, and 750-line limit are hard gates enforced by `scripts/prd-check`; do not
bypass them.
