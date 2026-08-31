#!/usr/bin/env bats

load test_helper.bash

setup() {
  bats_require_minimum_version 1.14.0
  root=$(repo_root)
}

frontmatter_value() {
  key=$1
  file=$2
  awk -v key="$key" '
    NR == 1 && $0 != "---" { exit 2 }
    NR > 1 && $0 == "---" { exit }
    index($0, key ":") == 1 {
      sub("^" key ":[[:space:]]*", "")
      print
      found = 1
    }
    END { if (!found) exit 1 }
  ' "$file"
}

@test "all distributed skills have valid identity and license metadata" {
  find "$root/skills" -name SKILL.md -type f | sort | while IFS= read -r skill; do
    name=$(frontmatter_value name "$skill")
    description=$(frontmatter_value description "$skill")
    license=$(frontmatter_value license "$skill")

    [ "$name" = "$(basename "$(dirname "$skill")")" ]
    [ -n "$description" ]
    [ "$license" = MIT ]
  done
}

@test "bootstrap skills declare their new-project boundary" {
  for skill in \
    "$root/skills/agent-project-scaffold/SKILL.md" \
    "$root/skills/go-project-scaffold/SKILL.md"; do
    description=$(frontmatter_value description "$skill")
    printf '%s\n' "$description" | grep -Eq 'new|initialize|scaffold'
    printf '%s\n' "$description" | grep -Eq 'do not|does not|not retrofit'
  done
}

@test "public repository readiness skill has a direct documentation boundary" {
  skill="$root/skills/agent-project-scaffold/assets/project-skills/public-repo-readiness/SKILL.md"
  reference="$root/skills/agent-project-scaffold/assets/project-skills/public-repo-readiness/references/public-repository-checklist.md"

  [ "$(frontmatter_value name "$skill")" = public-repo-readiness ]
  [ -f "$reference" ]
  grep -Fq 'does not replace the PRD workflow' "$skill"
  grep -Fq 'Do not change repository visibility' "$skill"
}
