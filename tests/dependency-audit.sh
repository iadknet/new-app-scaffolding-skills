#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-scaffold-dependency-audit.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
project=$tmp/project
mkdir -p "$project/scripts" "$project/.tools/bin"
cp "$root/skills/agent-project-scaffold/assets/template/scripts/dependency-audit" \
  "$project/scripts/dependency-audit"
chmod +x "$project/scripts/dependency-audit"

(cd "$project" && scripts/dependency-audit --require-tools >/dev/null)

touch "$project/package-lock.json"
if (cd "$project" && scripts/dependency-audit --require-tools >/dev/null 2>&1); then
  printf 'dependency-audit: required scanner absence was accepted\n' >&2
  exit 1
fi

cat >"$project/.tools/bin/osv-scanner" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$OSV_SCANNER_LOG"
EOF
chmod +x "$project/.tools/bin/osv-scanner"
log=$tmp/invocations
(cd "$project" && OSV_SCANNER_LOG=$log scripts/dependency-audit --require-tools)
grep -Fx 'scan source --recursive .' "$log" >/dev/null || {
  printf 'dependency-audit: scanner did not receive the expected source scan command\n' >&2
  exit 1
}

printf 'Dependency audit lockfile detection and scanner requirement passed.\n'
