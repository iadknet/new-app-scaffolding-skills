#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-integration.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
project=$tmp/project

"$root/bin/init-agent-project" --agent codex --agent claude-code "$project" >/dev/null
cd "$project"

mock_bin=$tmp/mock-bin
mkdir "$mock_bin"
cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
set -eu

output=
while [ "$#" -gt 0 ]; do
  case $1 in
    -o) output=$2; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$output" ] || exit 2
printf 'deliberately invalid archive' >"$output"
EOF
chmod +x "$mock_bin/curl"
if PATH="$mock_bin:$PATH" scripts/install-gitleaks >/dev/null 2>&1; then
  printf 'tool-integration: invalid Gitleaks archive was accepted\n' >&2
  exit 1
fi
if PATH="$mock_bin:$PATH" scripts/install-quality-tools >/dev/null 2>&1; then
  printf 'tool-integration: invalid quality-tool archive was accepted\n' >&2
  exit 1
fi
[ ! -e .tools/bin/gitleaks ] || { printf 'tool-integration: invalid scanner was installed\n' >&2; exit 1; }
[ ! -e .tools/bin/actionlint ] || { printf 'tool-integration: invalid actionlint was installed\n' >&2; exit 1; }
[ ! -e .tools/bin/shellcheck ] || { printf 'tool-integration: invalid ShellCheck was installed\n' >&2; exit 1; }

make setup
[ -x .git/hooks/pre-commit ] || {
  printf 'tool-integration: pre-commit framework hook was not installed\n' >&2
  exit 1
}
[ -z "$(git config --local --get core.hooksPath 2>/dev/null || :)" ] || {
  printf 'tool-integration: legacy core.hooksPath remains configured\n' >&2
  exit 1
}
make check >/dev/null

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

printf 'Pinned tools, pre-commit, staged secrets, and history scan passed.\n'
