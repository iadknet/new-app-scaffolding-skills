# Security Policy

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability. Until the project
foundation PRD records an approved private reporting channel, contact the
repository maintainers through an already-established private channel.

This repository does not yet make claims about supported release versions. That
policy is established after the product and release model are selected.

## Local checks

`make precommit` runs the standard pre-commit framework, validates repository
quality, scans staged secrets, and checks project skills for HIGH or CRITICAL
security findings. `make audit` scans repository history. Run `make setup` once
to install pinned Gitleaks, ShellCheck, actionlint, pre-commit, and Cisco AI Skill
Scanner tools and install the Git hook. CI runs the same deterministic skill
scan and offline zizmor analysis over GitHub Actions definitions. LLM skill
analysis is intentionally excluded from blocking checks.
