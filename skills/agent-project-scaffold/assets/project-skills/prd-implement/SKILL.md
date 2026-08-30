---
name: prd-implement
description: Implement an active PRD that has passed readiness review, preserving stage order, truthful state, verification, final review, and archival gates.
---

# Implement a Reviewed PRD

Accept only a PRD with `Review Status: APPROVED` whose master is `Ready` or
`In Progress` and whose applicable stage is `Ready` or `In Progress`. If not,
route to `$prd-review` or `$prd-create` instead of starting code changes.

## Workflow

1. Read the master, every stage, their references, and affected code. Confirm the
   dependency order and current repository state still match the plan.
2. Implement stages in order. Keep changes within the stated boundaries; revise
   and re-review the PRD if discovered work materially changes scope, architecture,
   dependencies, or non-goals.
3. Mark a task complete only after its result exists. Run each declared check and
   mark verification complete only after observing success. Record useful evidence
   in the stage rather than relying on intent.
4. Set a stage `Complete` only when its dependencies, tasks, and verification are
   complete. Keep the master `In Progress` until every stage and implementation
   task is complete.
5. Use `$prd-review` for the final-code gate. Address P1/P2 findings and rerun
   affected verification after review-driven changes. This review does not change
   the PRD readiness `Review Count`.
6. Run `make check`. When final review has passed and validation confirms complete
   state, run `scripts/prd-archive <slug>`.

Do not archive manually, skip dependencies, or conceal follow-up debt in order to
declare completion.
