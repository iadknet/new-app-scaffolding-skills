# Security Policy

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability. Until the project
foundation PRD records an approved private reporting channel, contact the
repository maintainers through an already-established private channel.

This repository does not yet make claims about supported release versions. That
policy is established after the product and release model are selected.

## Local checks

`make precommit` validates repository quality and scans staged changes. `make
audit` scans repository history. Run `make setup` once to install the pinned
Gitleaks, ShellCheck, and actionlint binaries and configure the version-controlled
hook. CI also runs offline zizmor analysis over GitHub Actions definitions.
