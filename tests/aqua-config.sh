#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
template=$root/skills/agent-project-scaffold/assets/template

cmp "$root/aqua.yaml" "$template/aqua.yaml"
cmp "$root/aqua-checksums.json" "$template/aqua-checksums.json"
cmp "$root/scripts/aqua" "$template/scripts/aqua"

for package in \
  'rhysd/actionlint@v1.7.12' \
  'koalaman/shellcheck@v0.11.0' \
  'gitleaks/gitleaks@v8.30.1' \
  'google/osv-scanner@v2.4.0'; do
  grep -Fq "name: $package" "$root/aqua.yaml" || {
    printf 'aqua-config: missing pinned package %s\n' "$package" >&2
    exit 1
  }
done

grep -Fq 'require_checksum: true' "$root/aqua.yaml"
grep -Fq '"checksums"' "$root/aqua-checksums.json"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/aqua-config-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir "$tmp/bin"
cat >"$tmp/bin/aqua" <<'EOF'
#!/bin/sh
set -eu

case ${1:-} in
  --version) printf 'aqua version %s\n' "$MOCK_AQUA_VERSION" ;;
  install) printf 'install\n' >>"$MOCK_AQUA_LOG" ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$tmp/bin/aqua"

if PATH="$tmp/bin:$PATH" MOCK_AQUA_VERSION=2.60.0 MOCK_AQUA_LOG="$tmp/log" "$root/scripts/aqua" install >/dev/null 2>&1; then
  printf 'aqua-config: accepted Aqua older than v2.60.1\n' >&2
  exit 1
fi
[ ! -e "$tmp/log" ] || { printf 'aqua-config: invoked an unsupported Aqua version\n' >&2; exit 1; }
PATH="$tmp/bin:$PATH" MOCK_AQUA_VERSION=2.60.1 MOCK_AQUA_LOG="$tmp/log" "$root/scripts/aqua" install
grep -Fx 'install' "$tmp/log" >/dev/null
printf 'Aqua configuration and template lockfile are synchronized.\n'
