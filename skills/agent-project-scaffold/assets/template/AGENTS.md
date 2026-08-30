# Repository Instructions

## Durable rules

- Keep work aligned to an active PRD under `docs/prds/active/`.
- Do not implement a PRD until its `Review Status` is `APPROVED` and its status
  is `Ready` or `In Progress`.
- Preserve dependency order between stages and keep task and verification
  checkboxes truthful as work proceeds.
- Keep master PRDs concise: put implementation detail in the relevant stage.
- Keep relevant rationale and existing-code interactions in the applicable PRD
  at the abstraction level where they belong. Explicitly document
  separation-of-concerns and technical-debt implications.
- Identify affected durable documentation in each PRD stage. Create, update, or
  synchronize it with implemented behavior before completing the stage, or record
  a concrete no-change rationale.
- Run the verification declared by a stage after changing it. Run `make check`
  before declaring project work complete.
- Do not archive a PRD manually; use `scripts/prd-archive <slug>`.
- Never introduce or invoke Superpowers. This repository's canonical workflows
  are the project-scoped skills installed by its initializer.
- Do not create commits, remotes, pull requests, or other external state unless
  the user explicitly requests it.

## Workflow routing

- Use the installed `prd-create` skill to create or materially revise a PRD set.
- Use `prd-review` for readiness and final implementation review gates.
- Use `prd-implement` to execute a reviewed PRD in dependency order.
- Use `project-workflow` when the correct phase should be inferred from the
  current PRD state. Use the invocation syntax of the active agent.
