# Go Project Agent Notes

Keep changes small and use standard-library-first Go. Add packages only when
they have a distinct responsibility; keep non-public code under `internal/`.
Do not introduce layers, interfaces, or abstractions without a concrete caller.
Do not assume this module is a CLI: choose its initial package and directory
layout from the product's actual library, command, server, or mixed role.

After every coherent edit, run `make quick`. Before declaring work complete,
run `make check`. For changes to validation, parsing, authorization,
calculations, retries, or other branch-heavy behavior, also run
`make mutation-diff BASE=<base-ref>` when the base ref is available.

Do not add broad lint suppressions. Every `//nolint` must identify the linter
and explain why the exception is safe. Git hooks provide feedback, but required
CI status checks are the merge authority.
