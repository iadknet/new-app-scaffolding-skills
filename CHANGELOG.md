# Changelog

All notable changes are generated from Git history at release time.

## [Unreleased]

### Added

- Add the agent project scaffolding skill.
- Add a generated-project skill for preparing public-facing documentation,
  badges, licensing, and community files.
- Add the `docker-bootstrap` skill for existing applications, with Minimus
  Dockerfile coordination, canonical Compose guidance, and a pinned Trivy gate.
- Make the Go project scaffold architecture-neutral instead of generating a
  command and `cmd` layout before the project's role is known.
- Add a lifecycle-enforced documentation impact and synchronization gate to
  generated PRDs and their create, review, and implementation skills.
- Add the standard pre-commit framework to distributor and generated-project
  checks.
- Add pinned Cisco AI Skill Scanner checks to pre-commit, local validation, and
  GitHub Actions in the distributor and generated scaffold.
