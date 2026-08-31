.DEFAULT_GOAL := help

.PHONY: help setup precommit prd-check skill-check dependency-audit check audit changelog run build test lint format clean

help: ## Show the stable project command interface.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install pinned local tools and configure pre-commit hooks.
	@scripts/aqua install
	@scripts/install-skill-scanner
	@scripts/install-pre-commit
	@printf 'Setup complete. Git hooks use the pre-commit framework.\n'

precommit: ## Validate staged PRDs, repository quality, and secrets.
	@.tools/bin/pre-commit run

prd-check: ## Validate all active and archived PRD sets.
	@scripts/prd-check

skill-check: ## Scan all project skills for high-severity security findings.
	@scripts/skill-check

dependency-audit: ## Scan supported dependency lockfiles for known vulnerabilities.
	@scripts/dependency-audit

check: ## Run PRD, repository policy, and quality validation.
	@scripts/prd-check
	@scripts/policy-check
	@scripts/quality-check
	@scripts/skill-check
	@scripts/dependency-audit

audit: ## Scan the full repository and Git history for secrets.
	@scripts/secret-scan history

changelog: ## Generate a release section. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/changelog "$(VERSION)"

run build test lint format clean: ## Successful placeholders pending stack selection.
	@printf '%s is awaiting the stack-specific follow-on PRD.\n' "$@"
