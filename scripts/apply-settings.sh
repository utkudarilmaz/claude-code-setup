#!/usr/bin/env bash
# Usage: apply-settings.sh [--check] <base settings.json> <claude home>
# Env: DRY_RUN=1 prints the change and writes nothing. PRUNE="key ..." clears stale leaves under those keys.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to merge settings.json. Install it and run again." >&2
  exit 1
fi

check=0
if [ "${1:-}" = "--check" ]; then
  check=1
  shift
fi

base="$1"
home="$2"
settings="$home/settings.json"
overrides="$home/settings.overrides.json"
managed="$home/.settings.managed.json"
filter="$(cd "$(dirname "$0")" && pwd)/settings-merge.jq"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

json_or_empty() {
  if [ -f "$1" ]; then cat "$1"; else echo '{}'; fi
}

json_or_empty "$settings" > "$tmp/target.json"
json_or_empty "$managed" > "$tmp/last.json"
json_or_empty "$overrides" > "$tmp/overrides.json"

jq -n \
  --slurpfile target "$tmp/target.json" \
  --slurpfile last "$tmp/last.json" \
  --slurpfile base "$base" \
  --slurpfile overrides "$tmp/overrides.json" \
  --arg prune "${PRUNE:-}" \
  -f "$filter" > "$tmp/result.json"

jq '.settings' "$tmp/result.json" > "$tmp/settings.json"
jq '.managed' "$tmp/result.json" > "$tmp/managed.json"

jq -S . "$tmp/target.json" > "$tmp/before.sorted"
jq -S . "$tmp/settings.json" > "$tmp/after.sorted"

if cmp -s "$tmp/before.sorted" "$tmp/after.sorted" && [ -f "$settings" ]; then
  changed=0
else
  changed=1
fi

if [ "$check" = "1" ]; then
  exit "$changed"
fi

if [ "$changed" = "0" ]; then
  echo "Unchanged: settings.json"
elif [ "${DRY_RUN:-0}" = "1" ]; then
  echo "Would update: settings.json"
  diff -u --label "settings.json (now)" --label "settings.json (after update)" \
    "$tmp/before.sorted" "$tmp/after.sorted" || true
else
  cat "$tmp/settings.json" > "$settings"
  echo "Updated: settings.json"
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
  jq -r '.removed[] | "Would remove: \(.)"' "$tmp/result.json"
else
  cat "$tmp/managed.json" > "$managed"
  jq -r '.removed[] | "Removed: \(.)"' "$tmp/result.json"
fi
