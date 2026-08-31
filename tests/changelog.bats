#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
project=$tmp/project

cmp "$root/scripts/changelog" "$root/skills/agent-project-scaffold/assets/template/scripts/changelog"
git -C "$tmp" init -b main "$project" >/dev/null
git -C "$project" config user.name 'Changelog Test'
git -C "$project" config user.email 'changelog-test@example.invalid'
mkdir "$project/scripts"
cp "$root/scripts/changelog" "$project/scripts/changelog"
cp "$root/skills/agent-project-scaffold/assets/template/CHANGELOG.md" "$project/CHANGELOG.md"
chmod +x "$project/scripts/changelog"

create_first_release() {
  touch "$project/first"
  git -C "$project" add .
  git -C "$project" commit -m 'feat: add first feature' >/dev/null
  (cd "$project" && scripts/changelog v0.1.0)
}
}

@test "changelog generates an initial release" {
create_first_release
grep -Eq '^## \[v0\.1\.0\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' "$project/CHANGELOG.md"
grep -Fq '### Added' "$project/CHANGELOG.md"
grep -Fq 'feat: add first feature' "$project/CHANGELOG.md"
}

@test "changelog appends releases and rejects duplicates" {
create_first_release
git -C "$project" add CHANGELOG.md
git -C "$project" commit -m 'chore: prepare v0.1.0' >/dev/null
git -C "$project" tag v0.1.0
touch "$project/fix"
git -C "$project" add fix
git -C "$project" commit -m 'fix: correct generated output' >/dev/null
(
  cd "$project"
  scripts/changelog v0.1.1
)
grep -Fq '## [v0.1.1] -' "$project/CHANGELOG.md"
grep -Fq '### Fixed' "$project/CHANGELOG.md"
grep -Fq 'fix: correct generated output' "$project/CHANGELOG.md"
grep -Fq '## [v0.1.0] -' "$project/CHANGELOG.md"
if (cd "$project" && scripts/changelog v0.1.1 >/dev/null 2>&1); then
  printf 'changelog: duplicate release section was accepted\n' >&2
  exit 1
fi
}
