.DEFAULT_GOAL := help

.PHONY: help setup quality check test test-integration test-distribution changelog release-check test-network

help: ## Show development targets.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install pinned development quality tools.
	@skills/agent-project-scaffold/assets/template/scripts/install-quality-tools

quality: ## Run distribution ShellCheck and GitHub Actions validation.
	@tests/distribution-quality.sh

check: ## Run distribution quality checks and the local test suite.
	@find bin scripts tests skills/agent-project-scaffold/scripts skills/agent-project-scaffold/assets/template/scripts skills/agent-project-scaffold/assets/template/.githooks -type f -print | while IFS= read -r file; do sh -n "$$file"; done
	@tests/distribution-quality.sh
	@$(MAKE) --no-print-directory test

test: ## Run focused offline tests for initialization and template behavior.
	@tests/run.sh
	@tests/prd-tools.sh
	@tests/policy-check.sh
	@tests/changelog.sh

test-integration: ## Verify pinned external tools end to end.
	@tests/tool-integration.sh

test-distribution: ## Verify installation and initialization through npx skills.
	@tests/distribution-install.sh

changelog: ## Generate a release section. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/changelog "$(VERSION)"

release-check: ## Run all release checks. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/release-check "$(VERSION)"

test-network: test-integration
