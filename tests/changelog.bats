#!/usr/bin/env bats

load test_helper.bash

setup() {
bats_require_minimum_version 1.14.0
unset GIT_INDEX_FILE
root=$(repo_root)
tmp="$BATS_TEST_TMPDIR"
project=$tmp/project

cmp "$root/scripts/changelog" "$root/skills/agent-project-scaffold/assets/template/scripts/changelog"
git -C "$tmp" init -b main "$project" >/dev/null
git -C "$project" config user.name 'Changelog Test'
git -C "$project" config user.email 'changelog-test@example.invalid'
mkdir "$project/scripts"
mkdir "$project/bin"
cp "$root/scripts/changelog" "$project/scripts/changelog"
cp "$root/scripts/release-check" "$project/scripts/release-check"
cp "$root/scripts/release-tag-check" "$project/scripts/release-tag-check"
cp "$root/skills/agent-project-scaffold/assets/template/CHANGELOG.md" "$project/CHANGELOG.md"
printf '#!/bin/sh\nexit 0\n' >"$project/bin/make"
chmod +x "$project/bin/make" "$project/scripts/changelog" "$project/scripts/release-check" "$project/scripts/release-tag-check"

create_first_release() {
  touch "$project/first"
  git -C "$project" add .
  git -C "$project" commit -m 'feat: add first feature' >/dev/null
  (cd "$project" && scripts/changelog v0.1.0)
}

prepare_first_release() {
  create_first_release
  git -C "$project" add CHANGELOG.md
  git -C "$project" commit -m 'chore: prepare v0.1.0' >/dev/null
}

run_release_check() {
  (cd "$project" && PATH="$project/bin:$PATH" scripts/release-check v0.1.0)
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

@test "release tag check requires a matching changelog section at HEAD" {
create_first_release
git -C "$project" add CHANGELOG.md
git -C "$project" commit -m 'chore: prepare v0.1.0' >/dev/null
git -C "$project" tag v0.1.0
(
  cd "$project"
  scripts/release-tag-check v0.1.0
)

touch "$project/later"
git -C "$project" add later
git -C "$project" commit -m 'chore: later commit' >/dev/null
if (cd "$project" && scripts/release-tag-check v0.1.0 >/dev/null 2>&1); then
  printf 'release-tag-check: accepted a tag that did not point to HEAD\n' >&2
  exit 1
fi
}

@test "release check accepts a complete generated release section" {
prepare_first_release
run_release_check
}

@test "release check rejects a release section with a missing commit" {
create_first_release
sed -i.bak '/feat: add first feature/d' "$project/CHANGELOG.md"
rm "$project/CHANGELOG.md.bak"
git -C "$project" add CHANGELOG.md
git -C "$project" commit -m 'chore: prepare v0.1.0' >/dev/null

run run_release_check
[ "$status" -ne 0 ]
[[ "$output" == *"must list every non-merge commit"* ]]
}

@test "release check rejects an unrecognized commit hash" {
create_first_release
sed -i.bak '/feat: add first feature/a\
- feat: invented entry (`deadbee`)' "$project/CHANGELOG.md"
rm "$project/CHANGELOG.md.bak"
git -C "$project" add CHANGELOG.md
git -C "$project" commit -m 'chore: prepare v0.1.0' >/dev/null

run run_release_check
[ "$status" -ne 0 ]
[[ "$output" == *"must list every non-merge commit"* ]]
}

@test "release check rejects commits made after changelog generation" {
create_first_release
touch "$project/later"
git -C "$project" add later
git -C "$project" commit -m 'fix: post-generation change' >/dev/null
git -C "$project" add CHANGELOG.md
git -C "$project" commit -m 'chore: prepare v0.1.0' >/dev/null

run run_release_check
[ "$status" -ne 0 ]
[[ "$output" == *"must list every non-merge commit"* ]]
}
