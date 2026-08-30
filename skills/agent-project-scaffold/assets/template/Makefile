.DEFAULT_GOAL := help

.PHONY: help setup precommit prd-check check audit changelog run build test lint format clean

help: ## Show the stable project command interface.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install pinned local tools and configure version-controlled hooks.
	@scripts/install-gitleaks
	@scripts/install-quality-tools
	@git config core.hooksPath .githooks
	@printf 'Setup complete. Git hooks use .githooks.\n'

precommit: ## Validate staged PRDs, repository quality, and secrets.
	@scripts/prd-check --staged
	@scripts/policy-check
	@scripts/quality-check --require-tools
	@scripts/secret-scan staged

prd-check: ## Validate all active and archived PRD sets.
	@scripts/prd-check

check: ## Run PRD, repository policy, and quality validation.
	@scripts/prd-check
	@scripts/policy-check
	@scripts/quality-check

audit: ## Scan the full repository and Git history for secrets.
	@scripts/secret-scan history

changelog: ## Generate a release section. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/changelog "$(VERSION)"

run build test lint format clean: ## Successful placeholders pending stack selection.
	@printf '%s is awaiting the stack-specific follow-on PRD.\n' "$@"
