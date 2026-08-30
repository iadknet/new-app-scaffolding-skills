# Releasing

This repository uses stable Semantic Versioning tags as its release source of
truth. The first release is `v0.1.0`; do not publish an npm package for this
repository.

From a clean, reviewed `main` checkout, run:

```sh
make changelog VERSION=v0.1.0
git add CHANGELOG.md
git commit -m 'chore: prepare v0.1.0'
make release-check VERSION=v0.1.0
git tag -a v0.1.0 -m 'v0.1.0'
git push origin v0.1.0
```

`make changelog` groups `feat` commits under Added, `fix` commits under Fixed,
and every other non-merge commit under Changed. Review the generated section
before committing it.

After the tag workflow passes, publish its GitHub Release with generated notes:

```sh
gh release create v0.1.0 --generate-notes --verify-tag
```

The installer source is pinned by that tag:

```sh
npx skills@1.5.23 add iadknet/new_app_scaffolding_skills#v0.1.0 \
  --skill agent-project-scaffold --global
```
