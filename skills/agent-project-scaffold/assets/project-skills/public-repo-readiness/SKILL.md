---
name: public-repo-readiness
description: Prepare a project repository for public GitHub use by improving its README, adding truthful badges, selecting a license explicitly, and completing applicable community files. Use for open-sourcing or polishing a repository; do not use for application code, CI hardening, or GitHub-admin changes.
license: MIT
---

# Prepare a Public Repository

Make the repository understandable, usable, and welcoming to an outsider while
preserving its established documentation and project workflow. This skill may
directly edit the narrow documentation and community-file scope allowed by
`AGENTS.md`; it does not replace the PRD workflow for product or engineering
work.

## Inspect and decide

Read `AGENTS.md`, the README, existing community files, manifests, workflows,
release history, and Git remote before changing anything. Preserve uncommitted
user changes unless the requested work explicitly includes them.

Derive facts from the repository first. Ask only for information that is not
available and changes the result:

- a project summary or intended audience when the README does not establish it;
- the license choice, which must be explicit and is not legal advice;
- an enforcement contact for a code of conduct, support route, and private
  vulnerability-reporting route when they are missing;
- ownership, citation, funding, or governance details only when those files
  apply.

Read [the public repository checklist](references/public-repository-checklist.md)
before creating or materially revising public-facing files.

## Apply the public baseline

Improve the README in place. It should explain the project's purpose, value,
quick start, requirements, ordinary usage, support, contributing, security,
and license in language appropriate to the project. Link to existing durable
documentation rather than duplicating it.

Add a compact badge row only for facts the repository can prove:

- a GitHub Actions status badge for an existing primary workflow on the default
  branch;
- a license badge after an explicit license has been added and a GitHub remote
  identifies the repository;
- a release or OpenSSF Scorecard badge only when that release or Scorecard
  publication actually exists.

Every badge must link to its underlying workflow, release, policy, or report.
Do not add popularity, download, coverage, security, or maturity badges without
current evidence.

Create or improve these files when needed: `LICENSE`, `CONTRIBUTING.md`,
`CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, issue forms or templates,
and a pull-request template. Do not overwrite a meaningful existing file.
Keep license references consistent with the chosen license, but do not invent
ecosystem-specific metadata fields. Do not claim private vulnerability reporting
is enabled unless the repository configuration proves it.

Create `CODEOWNERS`, `CITATION.cff`, `FUNDING.yml`, or `GOVERNANCE.md` only when
the owner or project purpose makes it applicable. Never guess GitHub usernames,
teams, payment destinations, or contact addresses.

## Boundaries and verification

Do not change repository visibility, description, topics, social-preview
images, rulesets, GitHub Actions workflows, dependencies, application code, or
remote settings. Report relevant GitHub repository-page items as a maintainer
checklist instead.

Before handoff, verify relative README links and referenced local files, run
`git diff --check`, and run the project's documented check command when it is
available. Report skipped checks and unresolved decisions plainly. Do not commit,
open a pull request, or change remote state without explicit user authorization.
