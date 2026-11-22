#!/usr/bin/env bash
# Usage: migrate.sh <plugin dir> <claude home>
# Env: DRY_RUN=1 lists what would go and changes nothing.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to clean settings.json. Install it and run again." >&2
  exit 1
fi

plugin="$1"
home="$2"
dry_run="${DRY_RUN:-0}"
renamed="agents/security-review.md skills/security-review"

remove() {
  if [ "$dry_run" = "1" ]; then
    echo "Would remove: $1"
  else
    rm -rf "$1"
    echo "Removed: $1"
  fi
}

for kind in agents skills hooks; do
  for src in "$plugin/$kind"/*; do
    name=$(basename "$src")
    if [ "$name" != "hooks.json" ] && [ -e "$home/$kind/$name" ]; then
      remove "$home/$kind/$name"
    fi
  done
done

for old in $renamed; do
  if [ -e "$home/$old" ]; then
    remove "$home/$old"
  fi
done

settings="$home/settings.json"
if [ ! -f "$settings" ]; then
  exit 0
fi

scripts=$(cd "$plugin/hooks" && ls -- *.sh | jq -R . | jq -s -c .)
old_hook='def old_hook: (.command // "") | rtrimstr("\"") as $c | any($scripts[]; . as $n | $c | endswith("/hooks/" + $n));'
list="$old_hook"' (.hooks // {}) | objects | .[] | arrays | .[] | (.hooks // [])[] | select(old_hook) | .command'
clean="$old_hook"'
  .hooks |= (
    with_entries(.value |= (map(.hooks |= map(select(old_hook | not))) | map(select(.hooks | length > 0))))
    | with_entries(select(.value | length > 0)))
  | if .hooks == {} then del(.hooks) else . end'

old_hooks=$(jq -r --argjson scripts "$scripts" "$list" "$settings")
if [ -z "$old_hooks" ]; then
  exit 0
fi

while IFS= read -r command; do
  if [ "$dry_run" = "1" ]; then
    echo "Would remove hook: $command"
  else
    echo "Removed hook: $command"
  fi
done <<< "$old_hooks"

if [ "$dry_run" != "1" ]; then
  cleaned=$(jq --argjson scripts "$scripts" "$clean" "$settings")
  printf '%s\n' "$cleaned" > "$settings"
fi
