# Stage 01 — Goals and Stack Discovery

- Status: Draft
- Depends on: None
- Master: [Master PRD](master-prd.md)

## Goal

Produce the decisions and evidence needed to begin application implementation
without guessing the product, users, constraints, or technology.

## Scope

- Define the project goal, audience, success criteria, and constraints.
- Research credible existing stack options using current primary sources.
- Select and justify a stack, including meaningful tradeoffs.
- Decide licensing, repository visibility, and ownership.
- Revisit deferred security tools in the context of the selected stack.
- Create a dependency-ordered follow-on implementation PRD.

## Non-Goals

- Adding application dependencies, generated framework code, or infrastructure.
- Implementing the selected stack within this stage.

## Inputs and Existing-Code Interactions

Use the current stack-neutral files and stable Make interface as constraints.
Inspect the repository before documenting assumptions. Research existing tools
and official guidance before proposing custom mechanisms.

## Boundaries and Abstraction Layers

Product outcomes and system constraints belong here. Concrete component design,
dependency configuration, and source-code tasks belong in the follow-on PRD.

## Separation of Concerns and Decomposition

Keep research evidence adjacent to the decision it supports. Separate product
requirements from technical options, and split the follow-on implementation into
stages whose outputs can be independently verified.

## Tech Debt and Spaghetti-Code Implications

Record whether the selected stack creates coupling, generated-code ownership, or
migration debt. None identified in the current stack-neutral foundation.

## Implementation or Decision Tasks

- [ ] Write the project goal and primary audience.
- [ ] Define measurable success criteria and constraints.
- [ ] Research at least two credible stack alternatives from current primary sources.
- [ ] Record the selected stack and rejected alternatives with tradeoffs.
- [ ] Decide licensing, repository visibility, and ownership.
- [ ] Decide which deferred security tools now apply.
- [ ] Create and link the stack implementation PRD that replaces Make placeholders.

## Verification and Observable Success Criteria

- [ ] Every required decision has evidence and no placeholder language remains.
- [ ] Selected tools support the target development and deployment environments.
- [ ] The follow-on PRD passes `scripts/prd-check`.
- [ ] `make check` passes.

## Current Status

Draft. The decisions above have not yet been made.
