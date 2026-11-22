#!/usr/bin/env bash
# Usage: migrate.sh <plugin dir> <claude home>
# Env: DRY_RUN=1 lists what would go and changes nothing.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to clean settings.json. Install it and run again." >&2
  exit 1
fi

plugin="${1:-}"
home="${2:-}"
dry_run="${DRY_RUN:-0}"
renamed="agents/security-review.md skills/security-review"

if [ -z "$plugin" ] || [ ! -d "$plugin/hooks" ]; then
  echo "migrate: plugin directory not found: '$plugin'" >&2
  exit 1
fi
if [ -z "$home" ] || [ ! -d "$home" ]; then
  echo "migrate: Claude home not found: '$home'" >&2
  exit 1
fi

plugin_real=$(cd -P "$plugin" && pwd)
home_real=$(cd -P "$home" && pwd)
case "$home_real/" in
  / | "$plugin_real"/*)
    echo "migrate: refusing to clean '$home'" >&2
    exit 1
    ;;
esac

if [ "$dry_run" = "1" ]; then
  verb="Would remove"
else
  verb="Removed"
fi

remove() {
  local path="$home/$1"
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    return 0
  fi
  if [ -L "$home/${1%%/*}" ]; then
    echo "Skipped: $path, because $home/${1%%/*} is a symlink. Remove it by hand." >&2
    return 0
  fi
  [ "$dry_run" = "1" ] || rm -rf "$path"
  echo "$verb: $path"
}

for kind in agents skills hooks; do
  for src in "$plugin/$kind"/*; do
    [ -e "$src" ] || continue
    name=$(basename "$src")
    [ "$name" = "hooks.json" ] || remove "$kind/$name"
  done
done

for old in $renamed; do
  remove "$old"
done

settings="$home/settings.json"
if [ ! -f "$settings" ]; then
  exit 0
fi

scripts=$(cd "$plugin/hooks" && ls -- *.sh | jq -Rnc '[inputs]')
dirs=$(printf '%s\n' '${CLAUDE_CONFIG_DIR:-$HOME/.claude}' '~/.claude' '$HOME/.claude' '${HOME}/.claude' "$home" "$home_real" | jq -Rnc '[inputs]')
old_hook='def old_hook:
  (.command? // "") as $raw
  | if ($raw | type) != "string" then false
    else ($raw | split("\"") | join("") | split("'"'"'") | join("") | ltrimstr("bash ") | ltrimstr("sh ")) as $c
      | any($dirs[]; . as $d | any($scripts[]; $c == $d + "/hooks/" + .))
    end;'
list="$old_hook"' .hooks | objects | .[] | arrays | .[] | objects | (.hooks // []) | arrays | .[] | objects | select(old_hook) | .command'
clean="$old_hook"'
  def has_old: any(.[]? | objects | (.hooks // []) | arrays | .[] | objects; old_hook);
  .hooks |= with_entries(
    if (.value | type == "array") and (.value | has_old) then
      .value |= map(
        if [.] | has_old then (.hooks |= map(select(old_hook | not))) | select(.hooks | length > 0) else . end)
      | select(.value | length > 0)
    else . end)
  | if .hooks == {} then del(.hooks) else . end'

old_hooks=$(jq -r --argjson scripts "$scripts" --argjson dirs "$dirs" "$list" "$settings")
if [ -z "$old_hooks" ]; then
  exit 0
fi

while IFS= read -r command; do
  echo "$verb hook: $command"
done <<< "$old_hooks"

if [ "$dry_run" != "1" ]; then
  cleaned=$(jq --argjson scripts "$scripts" --argjson dirs "$dirs" "$clean" "$settings")
  printf '%s\n' "$cleaned" > "$settings"
fi
