#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-integration.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
project=$tmp/project

"$root/bin/init-agent-project" --agent codex --agent claude-code "$project" >/dev/null
cd "$project"

command -v aqua >/dev/null 2>&1 || {
  printf 'tool-integration: Aqua is required; install Aqua v2.60.1 or newer\n' >&2
  exit 1
}

make setup
[ -x .tools/aqua/bin/gitleaks ] || { printf 'tool-integration: Gitleaks was not installed by Aqua\n' >&2; exit 1; }
[ -x .tools/aqua/bin/actionlint ] || { printf 'tool-integration: actionlint was not installed by Aqua\n' >&2; exit 1; }
[ -x .tools/aqua/bin/shellcheck ] || { printf 'tool-integration: ShellCheck was not installed by Aqua\n' >&2; exit 1; }
[ -x .tools/aqua/bin/osv-scanner ] || { printf 'tool-integration: OSV-Scanner was not installed by Aqua\n' >&2; exit 1; }

# A fresh Aqua root must not install anything when its checksum lock entries
# are absent. This verifies the wrapper's checksum enforcement, rather than
# merely checking that the configuration requests it.
mv aqua-checksums.json aqua-checksums.json.valid
printf '{\n  "checksums": []\n}\n' >aqua-checksums.json
rm -rf .tools/aqua
if scripts/aqua install >/dev/null 2>&1; then
  printf 'tool-integration: Aqua accepted a checksum lockfile with no entries\n' >&2
  exit 1
fi
mv aqua-checksums.json.valid aqua-checksums.json

[ -x .git/hooks/pre-commit ] || {
  printf 'tool-integration: pre-commit framework hook was not installed\n' >&2
  exit 1
}
[ -z "$(git config --local --get core.hooksPath 2>/dev/null || :)" ] || {
  printf 'tool-integration: legacy core.hooksPath remains configured\n' >&2
  exit 1
}
make check >/dev/null

cp -R "$root/tests/fixtures/malicious-skill" .agents/skills/malicious-fixture
if scripts/skill-check --require-tools >/dev/null 2>&1; then
  printf 'tool-integration: Cisco AI Skill Scanner accepted the malicious skill fixture\n' >&2
  exit 1
fi
rm -rf .agents/skills/malicious-fixture

cat >scripts/shellcheck-failure <<'EOF'
#!/bin/sh
value=$1
printf '%s\n' $value
EOF
if scripts/quality-check --require-tools >/dev/null 2>&1; then
  printf 'tool-integration: ShellCheck did not reject the shell fixture\n' >&2
  exit 1
fi
rm scripts/shellcheck-failure

cat >.github/workflows/actionlint-failure.yml <<'EOF'
name: Invalid workflow fixture
on: push
permissions:
  contents: read
jobs:
  invalid:
    runs-on: ubuntu-latest
    steps:
      - run: echo "${{ github.property_that_does_not_exist }}"
EOF
if scripts/quality-check --require-tools >/dev/null 2>&1; then
  printf 'tool-integration: actionlint did not reject the workflow fixture\n' >&2
  exit 1
fi
rm .github/workflows/actionlint-failure.yml

git config user.name 'Scaffold Test'
git config user.email 'scaffold-test@example.invalid'
git add .
git commit -m foundation >/dev/null

printf 'AWS_ACCESS_KEY_ID=%s%s\n' 'AKIA' '6RVLMJWE7T4N7Q2X' >credentials.env
git add credentials.env
if make precommit >/dev/null 2>&1; then
  printf 'tool-integration: staged synthetic credential was not detected\n' >&2
  exit 1
fi

git commit --no-verify -m 'synthetic credential fixture' >/dev/null
rm credentials.env
git add -u
git commit --no-verify -m 'remove synthetic credential fixture' >/dev/null
if make audit >/dev/null 2>&1; then
  printf 'tool-integration: historical synthetic credential was not detected\n' >&2
  exit 1
fi

printf 'Pinned tools, pre-commit, skill security, staged secrets, and history scan passed.\n'
