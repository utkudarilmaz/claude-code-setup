#!/bin/bash
# PreToolUse hook: exit 2 blocks the tool call; stderr is fed back to Claude.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
else
  COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  CWD=$(echo "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

[ -z "$COMMAND" ] && exit 0

START='(^|[;&|(`[:space:]])'
GIT_MERGE="${START}git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+merge([[:space:]]|$)"
GH_MERGE="${START}gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)"

MERGES=$(echo "$COMMAND" | sed -E 's/git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?merge[[:space:]]+--(abort|continue|quit)//g')
if ! echo "$MERGES" | grep -Eq "$GIT_MERGE|$GH_MERGE"; then
  exit 0
fi

DIR="${CWD:-$PWD}"
TARGET=$(echo "$COMMAND" | sed -n 's/.*git[[:space:]][[:space:]]*-C[[:space:]][[:space:]]*\([^[:space:]]*\).*/\1/p')
[ -z "$TARGET" ] && TARGET=$(echo ";$COMMAND" | sed -n 's/.*[;&|(][[:space:]]*cd[[:space:]][[:space:]]*\([^[:space:];&|)]*\).*/\1/p')
if [ -n "$TARGET" ]; then
  TARGET=$(echo "$TARGET" | tr -d "\"'")
  case "$TARGET" in
    "~"*) TARGET="$HOME${TARGET#\~}" ;;
    /*) ;;
    *) TARGET="$DIR/$TARGET" ;;
  esac
  DIR="$TARGET"
fi

# The target repo is untrusted input; keep git from running commands from its config.
safe_git() {
  GIT_OPTIONAL_LOCKS=0 git -c core.fsmonitor=false -c core.hooksPath=/dev/null "$@"
}

safe_git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

CHANGES=$(safe_git -C "$DIR" status --porcelain 2>/dev/null)
if [ -n "$CHANGES" ]; then
  echo "BLOCK: Uncommitted changes in $DIR. Commit or remove them before merging:" >&2
  echo "$CHANGES" | head -20 >&2
  exit 2
fi

exit 0
