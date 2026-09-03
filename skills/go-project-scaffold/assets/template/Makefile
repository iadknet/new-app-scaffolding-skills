GO ?= go
TOOLS := .tools/bin

.DEFAULT_GOAL := help

.PHONY: help setup hooks format fmt-check lint lint-changed test test-race verify vuln dep-audit secrets policy-check quick check mutation mutation-diff build

help: ## Show the project command interface.
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install pinned local tools and enable Git hooks.
	@scripts/install-go-tools
	@$(MAKE) --no-print-directory hooks

hooks: ## Enable this repository's native Git hooks.
	@git config core.hooksPath scripts/git-hooks
	@printf 'core.hooksPath -> scripts/git-hooks\\n'

format: ## Rewrite Go files with gofumpt when packages exist.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(TOOLS)/golangci-lint fmt; else printf 'No Go packages yet; skipping format.\n'; fi

fmt-check: ## Fail when Go files require formatting.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(TOOLS)/golangci-lint fmt --diff; else printf 'No Go packages yet; skipping format check.\n'; fi

lint: ## Run static, complexity, security, and test-quality analysis.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(TOOLS)/golangci-lint run ./...; else printf 'No Go packages yet; skipping lint.\n'; fi

lint-changed: ## Report lint issues in files changed since BASE (default origin/main).
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(TOOLS)/golangci-lint run --new-from-merge-base=$${BASE:-origin/main} --whole-files ./...; else printf 'No Go packages yet; skipping lint.\n'; fi

test: ## Run the unit test suite.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(GO) test ./...; else printf 'No Go packages yet; skipping tests.\n'; fi

test-race: ## Run the full unit test suite with the race detector.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(GO) test -race ./...; else printf 'No Go packages yet; skipping race tests.\n'; fi

verify: ## Verify module contents and fail on go.mod/go.sum drift.
	@$(GO) mod verify
	@$(GO) mod tidy -diff

vuln: ## Find reachable known Go vulnerabilities.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(TOOLS)/govulncheck ./...; else printf 'No Go packages yet; skipping reachable-vulnerability analysis.\n'; fi

dep-audit: ## Scan Go dependencies for known vulnerabilities.
	@$(TOOLS)/osv-scanner scan source --recursive .

secrets: ## Scan staged Git changes for secrets.
	@scripts/secret-scan staged

policy-check: ## Verify GitHub Actions use immutable, read-only defaults.
	@scripts/policy-check

quick: fmt-check lint test ## Fast feedback after a coherent edit.

check: fmt-check lint test-race verify vuln dep-audit policy-check ## Full local and CI quality gate.

mutation: ## Run non-blocking whole-module mutation testing.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(TOOLS)/gremlins unleash --output-statuses lc; else printf 'No Go packages yet; skipping mutation testing.\n'; fi

mutation-diff: ## Run non-blocking mutation testing for changes since BASE.
	@packages=$$($(GO) list ./...); status=$$?; [ "$$status" -eq 0 ] || exit "$$status"; if [ -n "$$packages" ]; then $(TOOLS)/gremlins unleash --diff "$${BASE:-origin/main}" --output-statuses lc; else printf 'No Go packages yet; skipping mutation testing.\n'; fi

build: ## Build all Go packages and commands.
	@$(GO) build ./...
