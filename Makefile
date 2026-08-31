.DEFAULT_GOAL := help

.PHONY: help setup require-bats precommit quality skill-check check test test-integration test-distribution changelog release-check test-network

BATS := .tools/aqua/bin/bats

help: ## Show development targets.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install pinned development, pre-commit, and security tools.
	@scripts/aqua install
	@scripts/install-skill-scanner
	@scripts/install-pre-commit

require-bats:
	@test -x "$(BATS)" || { printf '%s\n' 'Bats-core is not installed; run make setup.' >&2; exit 1; }

precommit: ## Run the configured pre-commit hooks against staged changes.
	@.tools/bin/pre-commit run

quality: require-bats ## Run distribution ShellCheck and GitHub Actions validation.
	@$(BATS) tests/distribution-quality.bats

skill-check: ## Scan all repository skills for high-severity security findings.
	@scripts/skill-check

check: require-bats ## Run distribution quality checks and the local test suite.
	@find bin scripts skills/agent-project-scaffold/scripts skills/agent-project-scaffold/assets/template/scripts skills/go-project-scaffold/scripts skills/go-project-scaffold/assets/template/scripts skills/go-project-scaffold/assets/template/.githooks -type f -perm -111 -print | while IFS= read -r file; do sh -n "$$file"; done
	@$(BATS) tests/distribution-quality.bats
	@$(MAKE) --no-print-directory test
	@scripts/skill-check

test: require-bats ## Run focused offline tests for initialization and template behavior.
	@$(BATS) tests/run.bats tests/prd-tools.bats tests/policy-check.bats tests/dependency-policy.bats tests/dependency-audit.bats tests/changelog.bats tests/skill-check.bats tests/skill-contracts.bats tests/aqua-config.bats tests/go-scaffold.bats

test-integration: require-bats ## Verify pinned external tools end to end.
	@$(BATS) tests/tool-integration.bats

test-distribution: require-bats ## Verify installation and initialization through npx skills.
	@$(BATS) tests/distribution-install.bats

changelog: ## Generate a release section. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/changelog "$(VERSION)"

release-check: ## Run all release checks. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/release-check "$(VERSION)"

test-network: test-integration
