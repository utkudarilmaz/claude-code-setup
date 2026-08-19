#!/bin/bash
# Tests for Makefile sync commands. Runs against a temporary TARGET_DIR
# so the real ~/.claude is never touched.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TMP_TARGET=$(mktemp -d)
TMP_TARGET_NORSYNC=$(mktemp -d)
TMP_TARGET_MCP=$(mktemp -d)
trap 'rm -rf "$TMP_TARGET" "$TMP_TARGET_NORSYNC" "$TMP_TARGET_MCP"' EXIT

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
  test "$(jq -r '.effortLevel' "$TMP_TARGET/settings.json")" = "high"

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

# --- update-config merges MCP servers into the target .claude.json ---
check "update-all creates .claude.json with repo MCP servers" \
  test "$(jq -r '.mcpServers["build123d-mcp"].command' "$TMP_TARGET/.claude.json")" = "uv"

jq '.mcpServers["local-server"] = {command: "echo"}
    | .mcpServers["build123d-mcp"].command = "drifted"
    | .oauthAccount = "keep-me"
    | .history = "line1\nline2\ttabbed"' \
  "$TMP_TARGET/.claude.json" > "$TMP_TARGET/.claude.json.tmp"
mv "$TMP_TARGET/.claude.json.tmp" "$TMP_TARGET/.claude.json"
run_make update-config TARGET_DIR="$TMP_TARGET"

check "MCP merge keeps machine-local servers" \
  test "$(jq -r '.mcpServers["local-server"].command' "$TMP_TARGET/.claude.json")" = "echo"
check "MCP merge applies repo server config over local drift" \
  test "$(jq -r '.mcpServers["build123d-mcp"].command' "$TMP_TARGET/.claude.json")" = "uv"
check "MCP merge keeps unrelated .claude.json keys" \
  test "$(jq -r '.oauthAccount' "$TMP_TARGET/.claude.json")" = "keep-me"
check "MCP merge preserves backslash escapes in strings" \
  test "$(jq -r '.history' "$TMP_TARGET/.claude.json")" = "$(printf 'line1\nline2\ttabbed')"

# --- update-mcp syncs MCP servers without touching the other config files ---
run_make update-mcp TARGET_DIR="$TMP_TARGET_MCP"

check "update-mcp creates .claude.json with repo MCP servers" \
  test "$(jq -r '.mcpServers["build123d-mcp"].command' "$TMP_TARGET_MCP/.claude.json")" = "uv"
check "update-mcp leaves settings.json alone" test ! -e "$TMP_TARGET_MCP/settings.json"
check "update-mcp leaves CLAUDE.md alone" test ! -e "$TMP_TARGET_MCP/CLAUDE.md"

jq '.mcpServers["local-server"] = {command: "echo"}' \
  "$TMP_TARGET_MCP/.claude.json" > "$TMP_TARGET_MCP/.claude.json.tmp"
mv "$TMP_TARGET_MCP/.claude.json.tmp" "$TMP_TARGET_MCP/.claude.json"
run_make update-mcp TARGET_DIR="$TMP_TARGET_MCP" DRY_RUN=1

check "update-mcp DRY_RUN=1 writes nothing" \
  test "$(jq -r '.mcpServers | keys | length' "$TMP_TARGET_MCP/.claude.json")" = "3"

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

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
