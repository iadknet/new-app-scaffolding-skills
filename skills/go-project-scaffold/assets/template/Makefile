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
	@git config core.hooksPath .githooks
	@printf 'core.hooksPath -> .githooks\\n'

format: ## Rewrite Go files with gofumpt.
	@$(TOOLS)/golangci-lint fmt

fmt-check: ## Fail when Go files require formatting.
	@$(TOOLS)/golangci-lint fmt --diff

lint: ## Run static, complexity, security, and test-quality analysis.
	@$(TOOLS)/golangci-lint run ./...

lint-changed: ## Report lint issues in files changed since BASE (default origin/main).
	@$(TOOLS)/golangci-lint run --new-from-merge-base=$${BASE:-origin/main} --whole-files ./...

test: ## Run the unit test suite.
	@$(GO) test ./...

test-race: ## Run the full unit test suite with the race detector.
	@$(GO) test -race ./...

verify: ## Verify module contents and fail on go.mod/go.sum drift.
	@$(GO) mod verify
	@$(GO) mod tidy -diff

vuln: ## Find reachable known Go vulnerabilities.
	@$(TOOLS)/govulncheck ./...

dep-audit: ## Scan Go dependencies for known vulnerabilities.
	@$(TOOLS)/osv-scanner scan source --recursive .

secrets: ## Scan staged Git changes for secrets.
	@scripts/secret-scan staged

policy-check: ## Verify GitHub Actions use immutable, read-only defaults.
	@scripts/policy-check

quick: fmt-check lint test ## Fast feedback after a coherent edit.

check: fmt-check lint test-race verify vuln dep-audit policy-check ## Full local and CI quality gate.

mutation: ## Run non-blocking whole-module mutation testing.
	@$(TOOLS)/gremlins unleash --output-statuses lc

mutation-diff: ## Run non-blocking mutation testing for changes since BASE.
	@$(TOOLS)/gremlins unleash --diff "$${BASE:-origin/main}" --output-statuses lc

build: ## Build every Go command.
	@$(GO) build ./cmd/...
