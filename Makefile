.DEFAULT_GOAL := help

AQUA_ROOT_DIR ?= $(CURDIR)/.tools/aqua
export AQUA_ROOT_DIR
export AQUA_ENFORCE_CHECKSUM := true
export AQUA_ENFORCE_REQUIRE_CHECKSUM := true
export PATH := $(AQUA_ROOT_DIR)/bin:$(PATH)

.PHONY: help setup require-bats precommit project-precommit quality skill-check check test test-integration test-docker-integration test-distribution changelog release-check test-network

BATS := $(AQUA_ROOT_DIR)/bin/bats

help: ## Show development targets.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install pinned development, pre-commit, and security tools.
	@aqua install -l
	@scripts/install-skill-scanner
	@scripts/install-pre-commit

require-bats:
	@test -x "$(BATS)" || { printf '%s\n' 'Bats-core is not installed; run make setup.' >&2; exit 1; }

precommit: ## Run the configured pre-commit hooks against staged changes.
	@.tools/bin/pre-commit run

project-precommit: ## Run the project-validation pre-commit entry point.
	@scripts/project-precommit

quality: require-bats ## Run distribution ShellCheck and GitHub Actions validation.
	@$(BATS) tests/distribution-quality.bats

skill-check: ## Scan all repository skills for high-severity security findings.
	@scripts/skill-check

check: require-bats ## Run distribution quality checks and the local test suite.
	@find bin scripts skills/agent-project-scaffold/scripts skills/agent-project-scaffold/assets/template/scripts skills/go-project-scaffold/scripts skills/go-project-scaffold/assets/template/scripts skills/docker-bootstrap/assets/scripts -type f -perm -111 -print | while IFS= read -r file; do sh -n "$$file"; done
	@$(BATS) tests/distribution-quality.bats
	@$(MAKE) --no-print-directory test
	@scripts/skill-check

test: require-bats ## Run focused offline tests for initialization and template behavior.
	@$(BATS) tests/run.bats tests/prd-tools.bats tests/policy-check.bats tests/dependency-policy.bats tests/dependency-audit.bats tests/changelog.bats tests/skill-check.bats tests/skill-contracts.bats tests/aqua-config.bats tests/go-scaffold.bats tests/docker-bootstrap.bats

test-integration: require-bats ## Verify pinned external tools end to end.
	@$(BATS) tests/tool-integration.bats

test-docker-integration: require-bats ## Opt in with RUN_DOCKER_BOOTSTRAP_INTEGRATION=1 to exercise Docker and Trivy.
	@$(BATS) tests/docker-bootstrap-integration.bats

test-distribution: require-bats ## Verify installation and initialization through npx skills.
	@$(BATS) tests/distribution-install.bats

changelog: ## Generate a release section. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/changelog "$(VERSION)"

release-check: ## Run all release checks. Set VERSION=v<major>.<minor>.<patch>.
	@scripts/release-check "$(VERSION)"

test-network: test-integration
