# Contributing

Contributions should keep each scaffold deterministic, portable, and safe to
run against only the target shapes it documents.

## Development setup

Install the pinned toolchain and run the repository checks:

```sh
make setup
make check
```

Changes that exercise downloaded tools or skill distribution must also run:

```sh
make test-integration
make test-distribution
```

## Pull requests

- Keep changes focused and include tests for observable behavior.
- Preserve support for both Ubuntu and macOS.
- Keep GitHub Actions pinned to full commit SHAs with read-only permissions.
- Update the README, templates, and bundled skills when their public behavior
  changes.
- Record the commands run and their results in the pull request.

Report suspected vulnerabilities through the private process in
[`SECURITY.md`](SECURITY.md), not through a public issue.
