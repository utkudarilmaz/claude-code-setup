#!/bin/bash
# Tests for .claude/hooks/sensitive-file-protection.sh
# The hook receives PreToolUse JSON on stdin and must exit 2 to block.

HOOK="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/sensitive-file-protection.sh"
FAILURES=0

run_case() {
  local description="$1"
  local payload="$2"
  local expected_exit="$3"
  local output actual_exit

  output=$(echo "$payload" | bash "$HOOK" 2>&1)
  actual_exit=$?

  if [ "$actual_exit" -ne "$expected_exit" ]; then
    echo "FAIL: $description (expected exit $expected_exit, got $actual_exit)"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if [ "$expected_exit" -eq 2 ] && ! echo "$output" | grep -q "Protected file"; then
    echo "FAIL: $description (blocked but no 'Protected file' message)"
    FAILURES=$((FAILURES + 1))
    return
  fi

  echo "PASS: $description"
}

run_case "blocks Edit on .env" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/app/.env","old_string":"a","new_string":"b"}}' 2

run_case "blocks Write on credentials file" \
  '{"tool_name":"Write","tool_input":{"file_path":"/app/credentials.json","content":"x"}}' 2

run_case "blocks Edit on secrets file" \
  '{"tool_name":"Edit","tool_input":{"file_path":"config/secrets.yaml","old_string":"a","new_string":"b"}}' 2

run_case "blocks Write on package-lock.json" \
  '{"tool_name":"Write","tool_input":{"file_path":"package-lock.json","content":"x"}}' 2

run_case "allows Edit on regular source file" \
  '{"tool_name":"Edit","tool_input":{"file_path":"src/main.go","old_string":"a","new_string":"b"}}' 0

run_case "allows input without file_path" \
  '{"tool_name":"Edit","tool_input":{}}' 0

run_case "allows protected-looking content in a safe file" \
  '{"tool_name":"Write","tool_input":{"file_path":"docs/notes.md","content":"how to rotate credentials and secrets"}}' 0

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
