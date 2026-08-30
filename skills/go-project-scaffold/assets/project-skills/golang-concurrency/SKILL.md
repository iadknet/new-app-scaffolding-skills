---
name: golang-concurrency
description: Apply safe Go goroutine, channel, and synchronization patterns.
license: MIT
---

# Go Concurrency

Give every goroutine an owner, a cancellation path, and a completion condition.
Prefer the simplest synchronization primitive that expresses ownership. Run
race tests when changing concurrent code and do not introduce worker pools or
channels without a measured need.
