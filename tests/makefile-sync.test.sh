#!/bin/bash

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TMP_TARGET=$(mktemp -d)
TMP_TARGET_NORSYNC=$(mktemp -d)
TMP_TARGET_MCP=$(mktemp -d)
TMP_TARGET_SETTINGS=$(mktemp -d)
TMP_TARGET_CLAUDE_MD=$(mktemp -d)
trap 'rm -rf "$TMP_TARGET" "$TMP_TARGET_NORSYNC" "$TMP_TARGET_MCP" "$TMP_TARGET_SETTINGS" "$TMP_TARGET_CLAUDE_MD"' EXIT

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

# --- update-config merges MCP servers into the target .claude.json ---
check "update-all creates .claude.json with repo MCP servers" \
  test "$(jq -r '.mcpServers["terraform"].command' "$TMP_TARGET/.claude.json")" = "docker"

jq '.mcpServers["local-server"] = {command: "echo"}
    | .mcpServers["terraform"].command = "drifted"
    | .oauthAccount = "keep-me"
    | .history = "line1\nline2\ttabbed"' \
  "$TMP_TARGET/.claude.json" > "$TMP_TARGET/.claude.json.tmp"
mv "$TMP_TARGET/.claude.json.tmp" "$TMP_TARGET/.claude.json"
run_make update-config TARGET_DIR="$TMP_TARGET"

check "MCP merge keeps machine-local servers" \
  test "$(jq -r '.mcpServers["local-server"].command' "$TMP_TARGET/.claude.json")" = "echo"
check "MCP merge applies repo server config over local drift" \
  test "$(jq -r '.mcpServers["terraform"].command' "$TMP_TARGET/.claude.json")" = "docker"
check "MCP merge keeps unrelated .claude.json keys" \
  test "$(jq -r '.oauthAccount' "$TMP_TARGET/.claude.json")" = "keep-me"
check "MCP merge preserves backslash escapes in strings" \
  test "$(jq -r '.history' "$TMP_TARGET/.claude.json")" = "$(printf 'line1\nline2\ttabbed')"

# --- update-mcp syncs MCP servers without touching the other config files ---
run_make update-mcp TARGET_DIR="$TMP_TARGET_MCP"

check "update-mcp creates .claude.json with repo MCP servers" \
  test "$(jq -r '.mcpServers["terraform"].command' "$TMP_TARGET_MCP/.claude.json")" = "docker"
check "update-mcp leaves settings.json alone" test ! -e "$TMP_TARGET_MCP/settings.json"
check "update-mcp leaves CLAUDE.md alone" test ! -e "$TMP_TARGET_MCP/CLAUDE.md"

jq '.mcpServers["local-server"] = {command: "echo"}' \
  "$TMP_TARGET_MCP/.claude.json" > "$TMP_TARGET_MCP/.claude.json.tmp"
mv "$TMP_TARGET_MCP/.claude.json.tmp" "$TMP_TARGET_MCP/.claude.json"
run_make update-mcp TARGET_DIR="$TMP_TARGET_MCP" DRY_RUN=1

REPO_MCP_COUNT=$(jq '.mcpServers | length' "$REPO_ROOT/.claude/mcp-servers.json")
check "update-mcp DRY_RUN=1 writes nothing" \
  test "$(jq -r '.mcpServers | keys | length' "$TMP_TARGET_MCP/.claude.json")" = "$((REPO_MCP_COUNT + 1))"

# --- update-settings syncs settings.json without touching the other config files ---
run_make update-settings TARGET_DIR="$TMP_TARGET_SETTINGS"

check "update-settings copies settings.json" \
  cmp -s "$REPO_ROOT/.claude/settings.json" "$TMP_TARGET_SETTINGS/settings.json"
check "update-settings leaves CLAUDE.md alone" test ! -e "$TMP_TARGET_SETTINGS/CLAUDE.md"
check "update-settings leaves .claude.json alone" test ! -e "$TMP_TARGET_SETTINGS/.claude.json"

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
check "update-claude-md leaves .claude.json alone" test ! -e "$TMP_TARGET_CLAUDE_MD/.claude.json"

echo "local edit" > "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"
run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD" DRY_RUN=1
check "update-claude-md DRY_RUN=1 writes nothing" \
  test "$(cat "$TMP_TARGET_CLAUDE_MD/CLAUDE.md")" = "local edit"

run_make update-claude-md TARGET_DIR="$TMP_TARGET_CLAUDE_MD"
check "update-claude-md refreshes a locally changed CLAUDE.md" \
  cmp -s "$REPO_ROOT/.claude/CLAUDE.md" "$TMP_TARGET_CLAUDE_MD/CLAUDE.md"

# --- install DRY_RUN=1 prints the command and never calls npx ---
TMP_STUB_BIN=$(mktemp -d)
printf '#!/bin/sh\ntouch "%s/npx-called"\n' "$TMP_STUB_BIN" > "$TMP_STUB_BIN/npx"
chmod +x "$TMP_STUB_BIN/npx"
ANATOMY_OUTPUT=$(PATH="$TMP_STUB_BIN:$PATH" make -C "$REPO_ROOT" --no-print-directory DRY_RUN=1 install anatomy TARGET_DIR="$TMP_TARGET" 2>&1)

export ANATOMY_OUTPUT TMP_TARGET
check "install anatomy DRY_RUN=1 prints npx command with CLAUDE_CONFIG_DIR" \
  bash -c 'echo "$ANATOMY_OUTPUT" | grep -qF "Would run: CLAUDE_CONFIG_DIR=$TMP_TARGET npx skills add wheresryan22/anatomy -g -a claude-code"'
check "install anatomy DRY_RUN=1 does not run npx" test ! -e "$TMP_STUB_BIN/npx-called"

# --- install asks for each item of a group and installs only the approved ones ---
printf '#!/bin/sh\necho "$*" >> "%s/npx-args"\n' "$TMP_STUB_BIN" > "$TMP_STUB_BIN/npx"
INSTALL_ASK_OUTPUT=$(printf 'n\ny\n' | PATH="$TMP_STUB_BIN:$PATH" make -C "$REPO_ROOT" --no-print-directory install skills TARGET_DIR="$TMP_TARGET" 2>&1)

export INSTALL_ASK_OUTPUT
check "install skills asks for each item" \
  bash -c 'echo "$INSTALL_ASK_OUTPUT" | grep -qF "Install google-maps-scraper? [y/N]" && echo "$INSTALL_ASK_OUTPUT" | grep -qF "Install anatomy? [y/N]"'
check "install skills skips a declined item" \
  bash -c 'echo "$INSTALL_ASK_OUTPUT" | grep -qF "Skipped google-maps-scraper. Run later with: make install google-maps-scraper"'
check "install skills runs only the approved item" \
  test "$(cat "$TMP_STUB_BIN/npx-args" 2>/dev/null)" = "skills add wheresryan22/anatomy -g -a claude-code"

rm -f "$TMP_STUB_BIN/npx-args"
PATH="$TMP_STUB_BIN:$PATH" make -C "$REPO_ROOT" --no-print-directory install TARGET_DIR="$TMP_TARGET" </dev/null >/dev/null 2>&1
check "install with no answers installs nothing" test ! -e "$TMP_STUB_BIN/npx-args"

PATH="$TMP_STUB_BIN:$PATH" make -C "$REPO_ROOT" --no-print-directory install anatomy TARGET_DIR="$TMP_TARGET" </dev/null >/dev/null 2>&1
check "install <target> runs without asking" \
  test "$(cat "$TMP_STUB_BIN/npx-args" 2>/dev/null)" = "skills add wheresryan22/anatomy -g -a claude-code"
rm -rf "$TMP_STUB_BIN"

# --- install sync asks for hooks and config and syncs only the approved one ---
TMP_TARGET_INSTALL=$(mktemp -d)
printf 'y\nn\n' | make -C "$REPO_ROOT" --no-print-directory install sync TARGET_DIR="$TMP_TARGET_INSTALL" >/dev/null 2>&1
check "install sync copies approved hooks" test -f "$TMP_TARGET_INSTALL/hooks/sensitive-file-protection.sh"
check "install sync skips declined config" test ! -e "$TMP_TARGET_INSTALL/settings.json"

make -C "$REPO_ROOT" --no-print-directory install config TARGET_DIR="$TMP_TARGET_INSTALL" </dev/null >/dev/null 2>&1
check "install config copies settings.json" test -f "$TMP_TARGET_INSTALL/settings.json"
check "install config copies CLAUDE.md" test -f "$TMP_TARGET_INSTALL/CLAUDE.md"

# --- every install target has a matching install-<name> recipe ---
INSTALL_TARGET_NAMES=$(make -C "$REPO_ROOT" --no-print-directory -pn help 2>/dev/null | sed -n 's/^INSTALL_TARGETS := //p')
export INSTALL_TARGET_NAMES REPO_ROOT TMP_TARGET_INSTALL
check "install target list is not empty" test -n "$INSTALL_TARGET_NAMES"
check "every install target has an install-<name> recipe" \
  bash -c 'for t in $INSTALL_TARGET_NAMES; do make -C "$REPO_ROOT" --no-print-directory -n "install-$t" TARGET_DIR="$TMP_TARGET_INSTALL" >/dev/null 2>&1 || { echo "missing recipe: install-$t"; exit 1; }; done'
rm -rf "$TMP_TARGET_INSTALL"

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

# --- install claudish sets up the llama.cpp server without touching the repo ---
TMP_CLAUDISH="$TMP_TARGET/claudish-test"
mkdir -p "$TMP_CLAUDISH/bin" "$TMP_CLAUDISH/models" "$TMP_CLAUDISH/home"
for stub in brew llama-server launchctl; do
  printf '#!/bin/sh\necho "$0 $*" >> "%s/calls"\n[ "$1" = "print" ] && exit 1\nexit 0\n' "$TMP_CLAUDISH" > "$TMP_CLAUDISH/bin/$stub"
  chmod +x "$TMP_CLAUDISH/bin/$stub"
done
printf '{"env":{"LOCAL_ONLY":"kept"}}\n' > "$TMP_CLAUDISH/home/settings.json"
claudish_make() {
  PATH="$TMP_CLAUDISH/bin:$PATH" make -C "$REPO_ROOT" --no-print-directory "$@" install claudish \
    TARGET_DIR="$TMP_CLAUDISH/home" \
    LLAMA_MODEL_DIR="$TMP_CLAUDISH/models" \
    LLAMA_MODEL_URL="https://example.invalid/model.gguf" \
    LLAMA_MTP_URL="https://example.invalid/mtp.gguf" \
    LLAMA_KEY_FILE="$TMP_CLAUDISH/key/api-key" \
    LLAMA_PLIST="$TMP_CLAUDISH/agents/server.plist" \
    LLAMA_LOG="$TMP_CLAUDISH/logs/server.log" 2>&1
}

CLAUDISH_DRY_OUTPUT=$(claudish_make DRY_RUN=1)
export CLAUDISH_DRY_OUTPUT TMP_CLAUDISH
check "install claudish DRY_RUN=1 names the model download" \
  bash -c 'echo "$CLAUDISH_DRY_OUTPUT" | grep -qF "Would ask, then download: https://example.invalid/model.gguf"'
check "install claudish DRY_RUN=1 names the server URL" \
  bash -c 'echo "$CLAUDISH_DRY_OUTPUT" | grep -qF "Would set CLAUDISH_OPENAI_URL=http://127.0.0.1:11435/v1"'
check "install claudish DRY_RUN=1 writes no API key" test ! -e "$TMP_CLAUDISH/key/api-key"
check "install claudish DRY_RUN=1 leaves settings.json alone" \
  test "$(cat "$TMP_CLAUDISH/home/settings.json")" = '{"env":{"LOCAL_ONLY":"kept"}}'

echo "model" > "$TMP_CLAUDISH/models/model.gguf"
echo "mtp" > "$TMP_CLAUDISH/models/mtp.gguf"
claudish_make FORCE=1 LLAMA_HOST=0.0.0.0 >/dev/null
check "install claudish writes an API key" test -s "$TMP_CLAUDISH/key/api-key"
check "install claudish keeps the API key private" \
  test "$(ls -l "$TMP_CLAUDISH/key/api-key" | cut -c1-10)" = "-rw-------"
check "install claudish sets the server URL in the target settings" \
  test "$(jq -r '.env.CLAUDISH_OPENAI_URL' "$TMP_CLAUDISH/home/settings.json")" = "http://127.0.0.1:11435/v1"
check "install claudish sets the API key in the target settings" \
  test "$(jq -r '.env.CLAUDISH_OPENAI_KEY' "$TMP_CLAUDISH/home/settings.json")" = "$(cat "$TMP_CLAUDISH/key/api-key")"
check "install claudish keeps local-only settings" \
  test "$(jq -r '.env.LOCAL_ONLY' "$TMP_CLAUDISH/home/settings.json")" = "kept"
check "repo settings.json holds no server URL or API key" \
  test "$(jq -r '.env | has("CLAUDISH_OPENAI_URL") or has("CLAUDISH_OPENAI_KEY")' "$REPO_ROOT/.claude/settings.json")" = "false"
if [ "$(uname)" = "Darwin" ]; then
  check "install claudish renders the login service file" \
    grep -q "<string>$TMP_CLAUDISH/models/model.gguf</string>" "$TMP_CLAUDISH/agents/server.plist"
  check "install claudish puts the host in the login service file" \
    grep -q "<string>0.0.0.0</string>" "$TMP_CLAUDISH/agents/server.plist"
  check "install claudish leaves no placeholder in the login service file" \
    bash -c '! grep -q "@[A-Z_]*@" "$TMP_CLAUDISH/agents/server.plist"'
  check "install claudish starts the login service" \
    grep -q "launchctl bootstrap" "$TMP_CLAUDISH/calls"
fi

jq '.env.CLAUDISH_OPENAI_URL = "http://other-host:11435/v1"' "$TMP_CLAUDISH/home/settings.json" > "$TMP_CLAUDISH/home/settings.tmp"
mv "$TMP_CLAUDISH/home/settings.tmp" "$TMP_CLAUDISH/home/settings.json"
claudish_make FORCE=1 >/dev/null
run_make update-settings TARGET_DIR="$TMP_CLAUDISH/home"
check "a server URL on another host survives install and update-settings" \
  test "$(jq -r '.env.CLAUDISH_OPENAI_URL' "$TMP_CLAUDISH/home/settings.json")" = "http://other-host:11435/v1"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
