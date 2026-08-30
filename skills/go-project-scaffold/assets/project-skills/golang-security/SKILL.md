---
name: golang-security
description: Apply Go security practices for input, filesystem, networking, secrets, cryptography, and dependencies.
license: MIT
---

# Go Security

Validate untrusted input at boundaries, use context-aware APIs, avoid shell
construction, keep secrets out of source and logs, and rely on standard-library
cryptography. Run `make vuln` and `make dep-audit` before completing
security-sensitive changes.
