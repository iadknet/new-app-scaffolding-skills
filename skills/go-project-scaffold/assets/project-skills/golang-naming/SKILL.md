---
name: golang-naming
description: Apply standard Go naming conventions when creating or reviewing identifiers, packages, errors, and tests.
license: MIT
---

# Go Naming

Use short, meaningful MixedCaps identifiers. Keep package names singular and
lowercase, avoid stuttering at call sites, use `Err` for sentinel errors, and
keep error strings lowercase without punctuation. Do not use `utils` or
`helpers` as package names.
