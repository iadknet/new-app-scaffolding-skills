# __PROJECT_NAME__

Go module: `__MODULE_PATH__`.

## Development

```sh
make setup
make quick
make check
```

`make quick` is the tight edit loop. `make check` is the full quality gate.
`make mutation` and `make mutation-diff` are non-blocking diagnostics that
identify tests which do not distinguish meaningful code changes.
