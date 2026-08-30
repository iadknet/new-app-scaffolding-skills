---
name: golang-lint
description: Configure and resolve golangci-lint findings without broad suppressions.
license: MIT
---

# Go Linting

Use `make lint` for the whole project and `make lint-changed` for quick review
of a branch. Treat complexity, duplication, and test-quality findings as design
feedback. A `//nolint` must name the rule and explain the narrow reason it is
safe.
