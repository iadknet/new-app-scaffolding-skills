---
name: golang-error-handling
description: Apply idiomatic Go error creation, wrapping, inspection, and logging.
license: MIT
---

# Go Error Handling

Return errors to the layer that can act on them. Wrap errors with `%w` when
adding useful context, inspect with `errors.Is` or `errors.As`, and never log
and return the same error at multiple layers. Avoid panic for expected input or
operational failures.
