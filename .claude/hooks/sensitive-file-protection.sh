#!/bin/bash
# PreToolUse hook: blocks Edit/Write on protected files.
# Claude Code sends {tool_name, tool_input} as JSON on stdin.
# Exit 2 blocks the tool call; stderr is fed back to Claude.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
  # Fallback without jq: pull the file_path value out of the raw JSON
  FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

if [ -n "$FILE_PATH" ] && echo "$FILE_PATH" | grep -Eq '\.env|credentials|secrets|\.lock|lock\.json|lock\.yaml'; then
  echo "BLOCK: Protected file: $FILE_PATH" >&2
  exit 2
fi

exit 0
