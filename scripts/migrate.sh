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

if [ "$dry_run" = "1" ]; then
  verb="Would remove"
else
  verb="Removed"
fi

remove() {
  if [ -e "$1" ]; then
    [ "$dry_run" = "1" ] || rm -rf "$1"
    echo "$verb: $1"
  fi
}

for kind in agents skills hooks; do
  for src in "$plugin/$kind"/*; do
    name=$(basename "$src")
    [ "$name" = "hooks.json" ] || remove "$home/$kind/$name"
  done
done

for old in $renamed; do
  remove "$home/$old"
done

settings="$home/settings.json"
if [ ! -f "$settings" ]; then
  exit 0
fi

scripts=$(cd "$plugin/hooks" && ls -- *.sh | jq -Rnc '[inputs]')
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
  echo "$verb hook: $command"
done <<< "$old_hooks"

if [ "$dry_run" != "1" ]; then
  cleaned=$(jq --argjson scripts "$scripts" "$clean" "$settings")
  printf '%s\n' "$cleaned" > "$settings"
fi
