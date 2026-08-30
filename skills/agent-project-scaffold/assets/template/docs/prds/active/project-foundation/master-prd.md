# Project Foundation — Master PRD

- Status: Draft
- Owner: Unassigned
- Created: __INITIALIZATION_DATE__
- Review Status: DRAFT
- Review Count: 0

## Goal

Define a credible product direction and selected implementation stack before
application code or stack-specific automation is introduced.

## Scope

- Establish the project goal, audience, observable success criteria, and constraints.
- Research credible stack alternatives and record a justified selection.
- Decide repository visibility, ownership, licensing, and deferred security tools.
- Create the follow-on PRD that replaces placeholder Make targets.

## Non-Goals

- Implementing the application or selecting infrastructure speculatively.
- Replacing the stable Make command interface during discovery.

## Inputs and Existing-Code Interactions

The repository currently contains only stack-neutral workflows, documentation,
policy checks, PRD tooling, and secret scanning. The selected stack must preserve
these interfaces or explicitly migrate them in the follow-on PRD.

## Boundaries and Abstraction Layers

This PRD owns product and stack decisions. The follow-on PRD owns concrete
application architecture, dependencies, code, and stack-specific Make recipes.

## Separation of Concerns and Decomposition

Discovery is one stage because its decisions are coupled and precede all
implementation. Application work is deliberately split into a later PRD so this
master does not mix product selection with implementation detail.

## Tech Debt and Spaghetti-Code Implications

Premature implementation would embed unreviewed technology choices. Keeping the
repository stack-neutral avoids that debt. None identified beyond this avoided risk.

## Documentation Impact and Synchronization

The discovery stage produces durable decision documentation in this PRD and its
follow-on implementation PRD. Update project onboarding documentation when the
selected stack changes setup or usage guidance.

## Stage Order and Links

1. [Stage 01 — Goals and Stack Discovery](stage-01-goals-and-stack-discovery.md) — `Draft`

Stage 01 has no implementation predecessor. Its decisions are inputs to a new,
separately reviewed implementation PRD.

## Cross-Stage Decisions

- The stable Make targets remain the project interface across stack selection.
- Application package Dependabot entries, frozen-install commands, and the
  matching package-manager age gate are required when the stack is selected.
  CodeQL, dependency review, OpenSSF Scorecard, CODEOWNERS, SBOMs, and build
  provenance remain deferred until repository and release context is known.

## Implementation or Decision Tasks

- [ ] Complete the discovery stage.
- [ ] Link the follow-on stack implementation PRD.

## Verification and Observable Success Criteria

- [ ] The stage contains evidence for each required decision and passes readiness review.
- [ ] The follow-on PRD exists with stage-level verification.
- [ ] Affected durable documentation is created, updated, or synchronized, or a no-change rationale is recorded.
- [ ] The final-code review gate for this decision work has passed.

## Current Status

Draft. Product and stack discovery is the next action.
