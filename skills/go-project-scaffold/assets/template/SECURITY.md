# Security Policy

Run `make check` before merging. It includes reachable-vulnerability analysis
with govulncheck and manifest vulnerability scanning with OSV-Scanner.
Dependabot delays ordinary Go module updates by seven days but does not delay
security fixes. Report vulnerabilities privately to the repository maintainers.

The local Gitleaks hook scans staged changes; CI scans complete Git history.
Exceptions to vulnerability findings must be narrowly documented in the pull
request that introduces them.
