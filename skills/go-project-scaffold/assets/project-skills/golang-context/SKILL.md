---
name: golang-context
description: Apply idiomatic context propagation, cancellation, and deadline handling in Go.
license: MIT
---

# Go Context

Accept `context.Context` as the first parameter at request and operation
boundaries, propagate it unchanged, and derive cancellation only where its
lifetime is clear. Never store contexts in structs or use them for optional
parameters.
