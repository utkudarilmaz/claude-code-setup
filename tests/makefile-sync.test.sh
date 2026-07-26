#!/bin/bash
# Tests for Makefile sync commands. Runs against a temporary TARGET_DIR
# so the real ~/.claude is never touched.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TMP_TARGET=$(mktemp -d)
TMP_TARGET_NORSYNC=$(mktemp -d)
trap 'rm -rf "$TMP_TARGET" "$TMP_TARGET_NORSYNC"' EXIT

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
