#!/bin/bash

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TMP_TARGET=$(mktemp -d)
TMP_TARGET_NORSYNC=$(mktemp -d)
TMP_TARGET_SETTINGS=$(mktemp -d)
TMP_TARGET_CLAUDE_MD=$(mktemp -d)
trap 'rm -rf "$TMP_TARGET" "$TMP_TARGET_NORSYNC" "$TMP_TARGET_SETTINGS" "$TMP_TARGET_CLAUDE_MD"' EXIT

run_make() {
  make -C "$REPO_ROOT" --no-print-directory FORCE=1 "$@" >/dev/null 2>&1
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

# --- update-all populates an empty target ---
run_make update-all TARGET_DIR="$TMP_TARGET"

check "update-all copies agents" test -f "$TMP_TARGET/agents/docs.md"
check "update-all copies skills with references" test -f "$TMP_TARGET/skills/docs/references/comprehensive-mode.md"
check "update-all copies hooks" test -f "$TMP_TARGET/hooks/sensitive-file-protection.sh"
check "update-all copies settings.json" test -f "$TMP_TARGET/settings.json"
check "update-all copies CLAUDE.md" test -f "$TMP_TARGET/CLAUDE.md"
check "synced hook script is executable" test -x "$TMP_TARGET/hooks/sensitive-file-protection.sh"

# --- update keeps extra files and refreshes changed ones ---
touch "$TMP_TARGET/agents/extra-agent.md"
echo "local edit" > "$TMP_TARGET/agents/docs.md"
run_make update-agents TARGET_DIR="$TMP_TARGET"

check "update keeps extra files in target" test -f "$TMP_TARGET/agents/extra-agent.md"
check "update refreshes locally changed files" cmp -s "$REPO_ROOT/.claude/agents/docs.md" "$TMP_TARGET/agents/docs.md"

# --- update-config merges settings.json instead of clobbering it ---
jq '. + {localOnlyKey: true} | .effortLevel = "low"' "$TMP_TARGET/settings.json" > "$TMP_TARGET/settings.json.tmp"
mv "$TMP_TARGET/settings.json.tmp" "$TMP_TARGET/settings.json"
run_make update-config TARGET_DIR="$TMP_TARGET"

check "update-config keeps machine-local keys" \
  test "$(jq -r '.localOnlyKey' "$TMP_TARGET/settings.json")" = "true"
check "update-config applies repo values over local drift" \
  test "$(jq -r '.effortLevel' "$TMP_TARGET/settings.json")" = "$(jq -r '.effortLevel' "$REPO_ROOT/.claude/settings.json")"

# --- config paths stay portable across a custom TARGET_DIR ---
# Hook and statusLine commands must resolve against the active Claude home.
# A hardcoded ~/.claude makes a second home silently run the first home's
# scripts, which breaks the moment the first home is removed.
hook_exit_for_home() {
  local home="$1" expected="$2" cmd status
  cmd=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$TMP_TARGET/settings.json")
  printf '{"tool_input":{"file_path":"/tmp/app/.env"}}' \
    | CLAUDE_CONFIG_DIR="$home" bash -c "$cmd" >/dev/null 2>&1
  status=$?
  test "$status" -eq "$expected"
}

check "repo settings.json has no hardcoded ~/.claude path" \
  bash -c '! grep -q "~/\.claude" "$0/.claude/settings.json"' "$REPO_ROOT"
check "synced settings.json has no hardcoded ~/.claude path" \
  bash -c '! grep -q "~/\.claude" "$0/settings.json"' "$TMP_TARGET"
check "hook command resolves to the target home's own script" \
  hook_exit_for_home "$TMP_TARGET" 2
check "hook command follows CLAUDE_CONFIG_DIR rather than falling back" \
  hook_exit_for_home "$TMP_TARGET/nonexistent-home" 127

# --- MCP servers are set up by hand, so the sync never writes .claude.json ---
check "update-all leaves .claude.json alone" test ! -e "$TMP_TARGET/.claude.json"

TMP_HOME=$(mktemp -d)
HOME="$TMP_HOME" run_make update-all
check "update-all with the default home leaves ~/.claude.json alone" test ! -e "$TMP_HOME/.claude.json"
rm -rf "$TMP_HOME"

# --- update-config runs only update-settings and update-claude-md ---
TMP_TARGET_CONFIG=$(mktemp -d)
run_make update-config TARGET_DIR="$TMP_TARGET_CONFIG"

check "update-config copies settings.json" test -f "$TMP_TARGET_CONFIG/settings.json"
check "update-config copies CLAUDE.md" test -f "$TMP_TARGET_CONFIG/CLAUDE.md"
check "update-config writes nothing else" \
  test "$(ls -A "$TMP_TARGET_CONFIG" | sort | tr '\n' ' ')" = "CLAUDE.md settings.json "
rm -rf "$TMP_TARGET_CONFIG"

# --- the removed targets are gone ---
no_rule_for() {
  make -C "$REPO_ROOT" --no-print-directory -n "$1" TARGET_DIR="$TMP_TARGET" 2>&1 \
    | grep -qF "No rule to make target '$1'"
}

check "make install no longer exists" no_rule_for install
check "make update-mcp no longer exists" no_rule_for update-mcp

# --- update-settings syncs settings.json without touching the other config files ---
run_make update-settings TARGET_DIR="$TMP_TARGET_SETTINGS"

check "update-settings copies settings.json" \
  cmp -s "$REPO_ROOT/.claude/settings.json" "$TMP_TARGET_SETTINGS/settings.json"
check "update-settings leaves CLAUDE.md alone" test ! -e "$TMP_TARGET_SETTINGS/CLAUDE.md"

jq '. + {localOnlyKey: true}' "$TMP_TARGET_SETTINGS/settings.json" > "$TMP_TARGET_SETTINGS/settings.json.tmp"
mv "$TMP_TARGET_SETTINGS/settings.json.tmp" "$TMP_TARGET_SETTINGS/settings.json"
run_make update-settings TARGET_DIR="$TMP_TARGET_SETTINGS"

check "update-settings keeps machine-local keys" \
  test "$(jq -r '.localOnlyKey' "$TMP_TARGET_SETTINGS/settings.json")" = "true"

# --- update-claude-md syncs CLAUDE.md without touching the other config files ---
run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD"

check "update-claude-md copies CLAUDE.md" \
  cmp -s "$REPO_ROOT/.claude/CLAUDE.md" "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"
check "update-claude-md leaves settings.json alone" test ! -e "$TMP_TARGET_CLAUDE_MD/settings.json"

echo "local edit" > "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"
run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD" DRY_RUN=1
check "update-claude-md DRY_RUN=1 writes nothing" \
  test "$(cat "$TMP_TARGET_CLAUDE_MD/CLAUDE.md")" = "local edit"

run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD"
check "update-claude-md refreshes a locally changed CLAUDE.md" \
  cmp -s "$REPO_ROOT/.claude/CLAUDE.md" "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"

# --- rm commands remove repo-managed files only ---
run_make rm-agents TARGET_DIR="$TMP_TARGET"

check "rm-agents removes repo-managed agents" test ! -e "$TMP_TARGET/agents/docs.md"
check "rm-agents keeps extra agents" test -f "$TMP_TARGET/agents/extra-agent.md"

# --- NO_RSYNC=1 exercises the copy fallback path ---
NORSYNC_OUTPUT=$(make -C "$REPO_ROOT" --no-print-directory FORCE=1 update-all TARGET_DIR="$TMP_TARGET_NORSYNC" NO_RSYNC=1 2>&1)

export NORSYNC_OUTPUT
check "fallback path is used when NO_RSYNC=1" \
  bash -c "echo \"\$NORSYNC_OUTPUT\" | grep -q 'Added: agents/'"
check "fallback path copies agents" test -f "$TMP_TARGET_NORSYNC/agents/docs.md"
check "fallback path copies skills with references" test -f "$TMP_TARGET_NORSYNC/skills/docs/references/comprehensive-mode.md"
check "fallback path makes hook scripts executable" test -x "$TMP_TARGET_NORSYNC/hooks/sensitive-file-protection.sh"

# --- the claudish server URL and API key stay machine-local ---
TMP_CLAUDISH="$TMP_TARGET/claudish-test"
mkdir -p "$TMP_CLAUDISH"
printf '{"env":{"CLAUDISH_OPENAI_URL":"http://other-host:11435/v1","CLAUDISH_OPENAI_KEY":"local-key"}}\n' > "$TMP_CLAUDISH/settings.json"
run_make update-settings TARGET_DIR="$TMP_CLAUDISH"
check "repo settings.json holds no claudish server URL or API key" \
  test "$(jq -r '.env | has("CLAUDISH_OPENAI_URL") or has("CLAUDISH_OPENAI_KEY")' "$REPO_ROOT/.claude/settings.json")" = "false"
check "update-settings keeps a local claudish server URL" \
  test "$(jq -r '.env.CLAUDISH_OPENAI_URL' "$TMP_CLAUDISH/settings.json")" = "http://other-host:11435/v1"
check "update-settings keeps a local claudish API key" \
  test "$(jq -r '.env.CLAUDISH_OPENAI_KEY' "$TMP_CLAUDISH/settings.json")" = "local-key"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
