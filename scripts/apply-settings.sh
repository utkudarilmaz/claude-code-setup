#!/usr/bin/env bash
# Usage: apply-settings.sh [--check] <base settings.json> <claude home>
# Env: DRY_RUN=1 prints the change and writes nothing. PRUNE="key ..." clears stale leaves under those keys.
set -euo pipefail
umask 077

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to merge settings.json. Install it and run again." >&2
  exit 1
fi

check=0
if [ "${1:-}" = "--check" ]; then
  check=1
  shift
fi

if [ "$#" -ne 2 ] || [ -z "$2" ]; then
  echo "Usage: apply-settings.sh [--check] <base settings.json> <claude home>" >&2
  exit 1
fi

base="$1"
home="$2"
settings="$home/settings.json"
overrides="$home/settings.overrides.json"
managed="$home/.settings.managed.json"
filter="$(cd "$(dirname "$0")" && pwd)/settings-merge.jq"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

is_one_object() {
  jq -e -s 'length == 1 and (.[0] | type) == "object"' "$1" >/dev/null 2>&1
}

load() {
  if [ ! -f "$1" ]; then
    echo '{}' > "$2"
  elif is_one_object "$1"; then
    cat "$1" > "$2"
  else
    echo "Not changed: $1 must hold one JSON object. Fix or remove it and run again." >&2
    exit 1
  fi
}

if [ ! -f "$base" ]; then
  echo "Base settings not found: $base" >&2
  exit 1
fi

existed=0
if [ -f "$settings" ]; then
  existed=1
fi

load "$settings" "$tmp/target.json"
load "$managed" "$tmp/last.json"
load "$overrides" "$tmp/overrides.json"
load "$base" "$tmp/base.json"

jq -n \
  --slurpfile target "$tmp/target.json" \
  --slurpfile last "$tmp/last.json" \
  --slurpfile base "$tmp/base.json" \
  --slurpfile overrides "$tmp/overrides.json" \
  --arg prune "${PRUNE:-}" \
  -f "$filter" > "$tmp/result.json"

jq '.settings' "$tmp/result.json" > "$tmp/settings.json"
if ! is_one_object "$tmp/settings.json"; then
  echo "Not changed: the merge did not give one JSON object." >&2
  exit 1
fi
jq -S . "$tmp/target.json" > "$tmp/before.sorted"
jq -S '.settings' "$tmp/result.json" > "$tmp/after.sorted"

if cmp -s "$tmp/before.sorted" "$tmp/after.sorted" && [ -f "$settings" ]; then
  changed=0
else
  changed=1
fi

if [ "$check" = "1" ]; then
  exit "$changed"
fi

hide_env='
  if has("env") then
    (($old[0].env | objects) // {}) as $o
    | .env |= (if type == "object"
        then with_entries(.key as $k | .value as $v
          | .value = (if ($o | has($k)) and $o[$k] == $v then "<hidden>" else "<hidden, changed>" end))
        else "<hidden>" end)
  else . end'

write_settings() {
  if cat "$tmp/settings.json" > "$settings" && cmp -s "$tmp/settings.json" "$settings"; then
    return 0
  fi
  if [ "$existed" = "0" ]; then
    [ -L "$settings" ] || rm -f "$settings"
    echo "Could not write $settings." >&2
  elif cat "$tmp/target.json" > "$settings" && cmp -s "$tmp/target.json" "$settings"; then
    echo "Could not write $settings. The old file was put back." >&2
  else
    trap - EXIT
    echo "Could not write $settings. The old file is saved in $tmp/target.json" >&2
  fi
  exit 1
}

dry_run="${DRY_RUN:-0}"

if [ "$changed" = "0" ]; then
  echo "Unchanged: settings.json"
elif [ "$dry_run" = "1" ]; then
  echo "Would update: settings.json"
  jq -S --slurpfile old "$tmp/target.json" "$hide_env" "$tmp/target.json" > "$tmp/before.shown"
  jq -S --slurpfile old "$tmp/target.json" "$hide_env" "$tmp/settings.json" > "$tmp/after.shown"
  diff -u --label "settings.json (now)" --label "settings.json (after update)" \
    "$tmp/before.shown" "$tmp/after.shown" || true
else
  write_settings
  echo "Updated: settings.json"
fi

if [ "$dry_run" = "1" ]; then
  verb="Would remove"
else
  jq '.managed' "$tmp/result.json" > "$managed"
  verb="Removed"
fi
jq -r --arg verb "$verb" '.removed[] | "\($verb): \(.)"' "$tmp/result.json"
