#!/bin/bash

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TMP_TARGET=$(mktemp -d)
TMP_BACKUPS=$(mktemp -d)
TMP_TARGET_SETTINGS=$(mktemp -d)
TMP_TARGET_CLAUDE_MD=$(mktemp -d)
trap 'rm -rf "$TMP_TARGET" "$TMP_BACKUPS" "$TMP_TARGET_SETTINGS" "$TMP_TARGET_CLAUDE_MD"' EXIT

run_make() {
  make -C "$REPO_ROOT" --no-print-directory FORCE=1 BACKUP_DIR="$TMP_BACKUPS" "$@" >/dev/null 2>&1
}

check() {
  local description="$1"
  shift
  if "$@"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    FAILURES=$((FAILURES + 1))
  fi
}

# --- update-config writes settings.json and CLAUDE.md and nothing else ---
run_make update-config TARGET_DIR="$TMP_TARGET"

check "update-config copies settings.json" test -f "$TMP_TARGET/settings.json"
check "update-config copies CLAUDE.md" test -f "$TMP_TARGET/CLAUDE.md"
check "update-config writes nothing else" \
  test "$(ls -A "$TMP_TARGET" | LC_ALL=C sort | tr '\n' ' ')" = ".settings.managed.json CLAUDE.md settings.json "

jq '. + {localOnlyKey: true} | .effortLevel = "low"' "$TMP_TARGET/settings.json" > "$TMP_TARGET/settings.json.tmp"
mv "$TMP_TARGET/settings.json.tmp" "$TMP_TARGET/settings.json"
run_make update-config TARGET_DIR="$TMP_TARGET"

check "update-config keeps machine-local keys" \
  test "$(jq -r '.localOnlyKey' "$TMP_TARGET/settings.json")" = "true"
check "update-config applies repo values over local drift" \
  test "$(jq -r '.effortLevel' "$TMP_TARGET/settings.json")" = "$(jq -r '.effortLevel' "$REPO_ROOT/config/settings.json")"

TMP_HOME=$(mktemp -d)
HOME="$TMP_HOME" run_make update-config
check "update-config with the default home writes ~/.claude" test -f "$TMP_HOME/.claude/settings.json"
check "update-config with the default home leaves ~/.claude.json alone" test ! -e "$TMP_HOME/.claude.json"
rm -rf "$TMP_HOME"

# --- the base settings install the plugin and stay portable across homes ---
check "base settings enable the core plugin" \
  test "$(jq -r '.enabledPlugins["core@claude-code-setup"]' "$REPO_ROOT/config/settings.json")" = "true"
check "base settings declare the repo marketplace with auto update" \
  test "$(jq -c '.extraKnownMarketplaces["claude-code-setup"] | [.source.repo, .autoUpdate]' "$REPO_ROOT/config/settings.json")" = '["utkudarilmaz/claude-code-setup",true]'
check "base settings wire no hooks, the plugin does" \
  test "$(jq 'has("hooks")' "$REPO_ROOT/config/settings.json")" = "false"
check "base settings have no hardcoded ~/.claude path" \
  bash -c '! grep -q "~/\.claude" "$0/config/settings.json"' "$REPO_ROOT"

# --- the old file sync targets are gone ---
no_rule_for() {
  make -C "$REPO_ROOT" --no-print-directory -n "$1" TARGET_DIR="$TMP_TARGET" 2>&1 \
    | grep -qE "No rule to make target .$1'"
}

for target in install update-mcp update-all update-agents update-skills update-hooks rm-agents rm-skills rm-hooks; do
  check "make $target no longer exists" no_rule_for "$target"
done

# --- update-settings syncs settings.json without touching the other config files ---
run_make update-settings TARGET_DIR="$TMP_TARGET_SETTINGS"

check "update-settings copies settings.json" \
  test "$(jq -S . "$REPO_ROOT/config/settings.json")" = "$(jq -S . "$TMP_TARGET_SETTINGS/settings.json")"
check "update-settings leaves CLAUDE.md alone" test ! -e "$TMP_TARGET_SETTINGS/CLAUDE.md"

jq '. + {localOnlyKey: true}' "$TMP_TARGET_SETTINGS/settings.json" > "$TMP_TARGET_SETTINGS/settings.json.tmp"
mv "$TMP_TARGET_SETTINGS/settings.json.tmp" "$TMP_TARGET_SETTINGS/settings.json"
run_make update-settings TARGET_DIR="$TMP_TARGET_SETTINGS"

check "update-settings keeps machine-local keys" \
  test "$(jq -r '.localOnlyKey' "$TMP_TARGET_SETTINGS/settings.json")" = "true"

STATUS_OUTPUT=$(make -C "$REPO_ROOT" --no-print-directory status TARGET_DIR="$TMP_TARGET_SETTINGS" 2>&1)
export STATUS_OUTPUT
check "status calls settings.json synced when only local keys differ" \
  bash -c 'echo "$STATUS_OUTPUT" | grep "settings.json" | grep -q "synced"'

jq '.modelSettings["stale-model"] = {effortLevel: "low"}' "$TMP_TARGET_SETTINGS/settings.json" > "$TMP_TARGET_SETTINGS/settings.json.tmp"
mv "$TMP_TARGET_SETTINGS/settings.json.tmp" "$TMP_TARGET_SETTINGS/settings.json"
run_make update-settings TARGET_DIR="$TMP_TARGET_SETTINGS" PRUNE=modelSettings
check "update-settings PRUNE clears a stale leaf" \
  test "$(jq -r '.modelSettings | has("stale-model")' "$TMP_TARGET_SETTINGS/settings.json")" = "false"
check "update-settings PRUNE=env fails" bash -c '! make -C "$0" --no-print-directory update-settings TARGET_DIR="$1" PRUNE=env >/dev/null 2>&1' "$REPO_ROOT" "$TMP_TARGET_SETTINGS"

# --- diff, status and DRY_RUN show a drifted settings.json without writing, from any directory ---
TMP_TARGET_DIFF=$(mktemp -d)
printf '{"effortLevel":"local-drift","env":{"MY_TOKEN":"diff-secret"}}\n' > "$TMP_TARGET_DIFF/settings.json"
cp "$TMP_TARGET_DIFF/settings.json" "$TMP_TARGET_DIFF.before"
REPO_EFFORT=$(jq -r '.effortLevel' "$REPO_ROOT/config/settings.json")

DIFF_OUTPUT=$(cd "$TMP_TARGET_DIFF" && make -C "$REPO_ROOT" --no-print-directory diff TARGET_DIR="$TMP_TARGET_DIFF" 2>&1)
export DIFF_OUTPUT REPO_EFFORT
check "diff run from another directory says settings.json would update" \
  bash -c 'echo "$DIFF_OUTPUT" | grep -q "^Would update: settings.json"'
check "diff shows the repo value that would win" \
  bash -c 'echo "$DIFF_OUTPUT" | grep -q "^+ *\"effortLevel\": \"$REPO_EFFORT\""'
check "diff does not print env values" bash -c '! echo "$DIFF_OUTPUT" | grep -q "diff-secret"'
check "diff leaves settings.json alone" cmp -s "$TMP_TARGET_DIFF.before" "$TMP_TARGET_DIFF/settings.json"
check "diff writes no snapshot" test ! -e "$TMP_TARGET_DIFF/.settings.managed.json"

STATUS_OUTPUT=$(make -C "$REPO_ROOT" --no-print-directory status TARGET_DIR="$TMP_TARGET_DIFF" 2>&1)
check "status calls a drifted settings.json differs" \
  bash -c 'echo "$STATUS_OUTPUT" | grep "settings.json" | grep -q "differs"'

run_make update-settings TARGET_DIR="$TMP_TARGET_DIFF" DRY_RUN=1
check "update-settings DRY_RUN=1 writes nothing" cmp -s "$TMP_TARGET_DIFF.before" "$TMP_TARGET_DIFF/settings.json"

(cd "$TMP_TARGET_DIFF" && run_make update-settings TARGET_DIR="$TMP_TARGET_DIFF")
check "update-settings run from another directory applies the repo value" \
  test "$(jq -r '.effortLevel' "$TMP_TARGET_DIFF/settings.json")" = "$REPO_EFFORT"
rm -rf "$TMP_TARGET_DIFF" "$TMP_TARGET_DIFF.before"

# --- update-claude-md syncs CLAUDE.md without touching the other config files ---
run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD"

check "update-claude-md copies CLAUDE.md" \
  cmp -s "$REPO_ROOT/config/CLAUDE.md" "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"
check "update-claude-md leaves settings.json alone" test ! -e "$TMP_TARGET_CLAUDE_MD/settings.json"

echo "local edit" > "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"
run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD" DRY_RUN=1
check "update-claude-md DRY_RUN=1 writes nothing" \
  test "$(cat "$TMP_TARGET_CLAUDE_MD/CLAUDE.md")" = "local edit"

run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD"
check "update-claude-md refreshes a locally changed CLAUDE.md" \
  cmp -s "$REPO_ROOT/config/CLAUDE.md" "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"

# --- migrate removes the old file sync copies and keeps everything else ---
new_old_home() {
  OLD_HOME=$(mktemp -d)
  mkdir -p "$OLD_HOME/agents" "$OLD_HOME/skills/docs/references" "$OLD_HOME/skills/security-review" "$OLD_HOME/skills/extra-skill" "$OLD_HOME/hooks"
  touch "$OLD_HOME/agents/docs.md" "$OLD_HOME/agents/security-review.md" "$OLD_HOME/agents/extra-agent.md"
  touch "$OLD_HOME/skills/docs/SKILL.md" "$OLD_HOME/skills/extra-skill/SKILL.md"
  touch "$OLD_HOME/hooks/notification.sh" "$OLD_HOME/hooks/extra.sh"
  cat > "$OLD_HOME/settings.json" <<'JSON'
{
  "model": "opus",
  "hooks": {
    "PreToolUse": [
      {"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/sensitive-file-protection.sh"}]},
      {"matcher": "Bash", "hooks": [
        {"type": "command", "command": "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/dirty-merge-protection.sh"},
        {"type": "command", "command": "/usr/local/bin/my-hook.sh"}
      ]}
    ],
    "Notification": [
      {"hooks": [{"type": "command", "command": "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/notification.sh"}]}
    ]
  }
}
JSON
}

new_old_home
run_make migrate TARGET_DIR="$OLD_HOME" DRY_RUN=1
check "migrate DRY_RUN=1 removes nothing" test -f "$OLD_HOME/agents/docs.md"
check "migrate DRY_RUN=1 leaves settings.json alone" \
  test "$(jq '.hooks.Notification | length' "$OLD_HOME/settings.json")" = "1"
check "migrate DRY_RUN=1 makes no backup" test -z "$(ls -A "$TMP_BACKUPS")"

STATUS_OUTPUT=$(make -C "$REPO_ROOT" --no-print-directory status TARGET_DIR="$OLD_HOME" 2>&1)
export STATUS_OUTPUT
check "status asks for make migrate when old copies exist" \
  bash -c 'echo "$STATUS_OUTPUT" | grep -q "run make migrate"'

run_make migrate TARGET_DIR="$OLD_HOME"
check "migrate makes a backup first" test -n "$(ls -A "$TMP_BACKUPS")"
check "migrate removes an old agent copy" test ! -e "$OLD_HOME/agents/docs.md"
check "migrate removes an old skill copy" test ! -e "$OLD_HOME/skills/docs"
check "migrate removes an old hook script" test ! -e "$OLD_HOME/hooks/notification.sh"
check "migrate removes the agent under its old name" test ! -e "$OLD_HOME/agents/security-review.md"
check "migrate removes the skill under its old name" test ! -e "$OLD_HOME/skills/security-review"
check "migrate keeps an extra agent" test -f "$OLD_HOME/agents/extra-agent.md"
check "migrate keeps an extra skill" test -f "$OLD_HOME/skills/extra-skill/SKILL.md"
check "migrate keeps an extra hook script" test -f "$OLD_HOME/hooks/extra.sh"
check "migrate removes the old hook entries" \
  test "$(jq '[.hooks[][].hooks[].command | select(test("/hooks/"))] | length' "$OLD_HOME/settings.json")" = "0"
check "migrate keeps a local hook entry" \
  test "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$OLD_HOME/settings.json")" = "/usr/local/bin/my-hook.sh"
check "migrate drops an event left empty" test "$(jq '.hooks | has("Notification")' "$OLD_HOME/settings.json")" = "false"
check "migrate keeps other settings" test "$(jq -r '.model' "$OLD_HOME/settings.json")" = "opus"

STATUS_OUTPUT=$(make -C "$REPO_ROOT" --no-print-directory status TARGET_DIR="$OLD_HOME" 2>&1)
check "status stops asking for make migrate afterwards" \
  bash -c '! echo "$0" | grep -q "run make migrate"' "$STATUS_OUTPUT"
check "a second migrate has nothing to do" \
  test -z "$(DRY_RUN=1 bash "$REPO_ROOT/scripts/migrate.sh" "$REPO_ROOT/plugins/core" "$OLD_HOME")"
rm -rf "$OLD_HOME"

new_old_home
printf 'n\n' | make -C "$REPO_ROOT" --no-print-directory migrate TARGET_DIR="$OLD_HOME" BACKUP_DIR="$TMP_BACKUPS" >/dev/null 2>&1
check "migrate stops when the answer is no" test -f "$OLD_HOME/agents/docs.md"
rm -rf "$OLD_HOME"

# --- the claudish server URL and API key stay machine-local ---
TMP_CLAUDISH="$TMP_TARGET_SETTINGS/claudish-test"
mkdir -p "$TMP_CLAUDISH"
printf '{"env":{"CLAUDISH_OPENAI_URL":"http://other-host:11435/v1","CLAUDISH_OPENAI_KEY":"local-key"}}\n' > "$TMP_CLAUDISH/settings.json"
run_make update-settings TARGET_DIR="$TMP_CLAUDISH"
check "repo settings.json holds no claudish server URL or API key" \
  test "$(jq -r '.env | has("CLAUDISH_OPENAI_URL") or has("CLAUDISH_OPENAI_KEY")' "$REPO_ROOT/config/settings.json")" = "false"
check "update-settings keeps a local claudish server URL" \
  test "$(jq -r '.env.CLAUDISH_OPENAI_URL' "$TMP_CLAUDISH/settings.json")" = "http://other-host:11435/v1"
check "update-settings keeps a local claudish API key" \
  test "$(jq -r '.env.CLAUDISH_OPENAI_KEY' "$TMP_CLAUDISH/settings.json")" = "local-key"

# --- a TARGET_DIR with a space that does not exist yet ---
TMP_SPACE_PARENT=$(mktemp -d)
SPACE_HOME="$TMP_SPACE_PARENT/new home"
run_make update-config TARGET_DIR="$SPACE_HOME"
check "update-config creates a home whose path has a space" test -f "$SPACE_HOME/settings.json"
check "update-config copies CLAUDE.md into a home whose path has a space" test -f "$SPACE_HOME/CLAUDE.md"
check "update-config leaves no stray directory in the repo" test ! -e "$REPO_ROOT/home"
SPACE_STATUS=$(make -C "$REPO_ROOT" --no-print-directory status TARGET_DIR="$SPACE_HOME" 2>&1)
check "status works for a home whose path has a space" \
  bash -c '! echo "$0" | grep -q "too many arguments" && echo "$0" | grep "CLAUDE.md" | grep -q synced' "$SPACE_STATUS"
rm -rf "$TMP_SPACE_PARENT"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
