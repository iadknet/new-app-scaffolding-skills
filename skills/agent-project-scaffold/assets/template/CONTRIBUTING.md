# Contributing

Start with `AGENTS.md` and the applicable active PRD. Keep a change scoped to one
stage when practical, update its checkboxes only after the work is observable,
and run the stage's verification plus `make check`.

For new work, create a PRD set with:

```sh
scripts/prd-new <kebab-slug> <stage-slug> [stage-slug ...]
```

Review security-sensitive reports privately as described in `SECURITY.md`.
