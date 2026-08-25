#!/bin/bash
# Tests for .claude/hooks/notification.sh
# The hook plays a sound through the first available player and must always
# exit 0. Players are replaced with stubs on a private PATH so no sound is
# played and the same cases run on macOS and Linux.

HOOK="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/notification.sh"
BASH_BIN="$(command -v bash)"
STUB_DIR=$(mktemp -d)
CALL_LOG="$STUB_DIR/calls.log"
FAILURES=0
trap 'rm -rf "$STUB_DIR"' EXIT

MAC_SOUND="afplay /System/Library/Sounds/Glass.aiff"
PULSE_SOUND="paplay /usr/share/sounds/freedesktop/stereo/complete.oga"
ALSA_SOUND="aplay /usr/share/sounds/alsa/Front_Center.wav"
PAYLOAD='{"hookEventName":"Notification","message":"Claude needs your permission"}'

reset_stubs() {
  rm -f "$STUB_DIR"/*
  : > "$CALL_LOG"
}

stub() {
  local name="$1" exit_code="$2" stderr_message="$3"
  {
    echo '#!/bin/bash'
    echo "echo \"$name \$*\" >> \"$CALL_LOG\""
    if [ -n "$stderr_message" ]; then
      echo "echo \"$stderr_message\" >&2"
    fi
    echo "exit $exit_code"
  } > "$STUB_DIR/$name"
  chmod +x "$STUB_DIR/$name"
}

run_hook() {
  HOOK_OUTPUT=$(printf '%s' "$1" | PATH="$STUB_DIR" "$BASH_BIN" "$HOOK" 2>&1)
  HOOK_EXIT=$?
}

calls() {
  awk '{print $1}' "$CALL_LOG" | tr '\n' ' ' | sed 's/ *$//'
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

# --- macOS: afplay is available and works ---
reset_stubs
stub afplay 0
stub paplay 0
stub aplay 0
run_hook "$PAYLOAD"

check "exits 0 when afplay plays the sound" test "$HOOK_EXIT" -eq 0
check "plays the macOS sound with afplay" grep -Fxq "$MAC_SOUND" "$CALL_LOG"
check "stops at the first player that works" test "$(calls)" = "afplay"
check "prints nothing on the macOS path" test -z "$HOOK_OUTPUT"

# --- Linux with PulseAudio: no afplay ---
reset_stubs
stub paplay 0
stub aplay 0
run_hook "$PAYLOAD"

check "exits 0 when paplay plays the sound" test "$HOOK_EXIT" -eq 0
check "falls back to paplay when afplay is missing" test "$(calls)" = "paplay"
check "plays the freedesktop sound with paplay" grep -Fxq "$PULSE_SOUND" "$CALL_LOG"

# --- Linux with ALSA only ---
reset_stubs
stub aplay 0
run_hook "$PAYLOAD"

check "exits 0 when aplay plays the sound" test "$HOOK_EXIT" -eq 0
check "falls back to aplay when afplay and paplay are missing" test "$(calls)" = "aplay"
check "plays the ALSA sound with aplay" grep -Fxq "$ALSA_SOUND" "$CALL_LOG"

# --- Players installed but failing (no audio device, dead sound server) ---
reset_stubs
stub afplay 1 "afplay: no audio device"
stub paplay 1 "paplay: connection refused"
stub aplay 0
run_hook "$PAYLOAD"

check "keeps trying players until one succeeds" test "$(calls)" = "afplay paplay aplay"
check "exits 0 when earlier players fail" test "$HOOK_EXIT" -eq 0
check "hides failing player errors from the hook output" test -z "$HOOK_OUTPUT"

# --- Every player fails ---
reset_stubs
stub afplay 1 "afplay: no audio device"
stub paplay 1 "paplay: connection refused"
stub aplay 2 "aplay: device busy"
run_hook "$PAYLOAD"

check "exits 0 when every player fails" test "$HOOK_EXIT" -eq 0
check "tries all three players before giving up" test "$(calls)" = "afplay paplay aplay"
check "stays silent when every player fails" test -z "$HOOK_OUTPUT"

# --- No player installed at all ---
reset_stubs
run_hook "$PAYLOAD"

check "exits 0 when no player is installed" test "$HOOK_EXIT" -eq 0
check "stays silent when no player is installed" test -z "$HOOK_OUTPUT"

# --- Stdin the hook may receive from Claude Code ---
reset_stubs
stub afplay 0
run_hook ""
check "exits 0 with empty stdin" test "$HOOK_EXIT" -eq 0
check "still plays the sound with empty stdin" test "$(calls)" = "afplay"

reset_stubs
stub afplay 0
run_hook "not json at all"
check "exits 0 with malformed stdin" test "$HOOK_EXIT" -eq 0

reset_stubs
stub afplay 0
run_hook '{"hookEventName":"Notification","message":"line one\nline two \"quoted\""}'
check "exits 0 with multiline and quoted JSON stdin" test "$HOOK_EXIT" -eq 0

reset_stubs
stub afplay 0
HOOK_OUTPUT=$(PATH="$STUB_DIR" "$BASH_BIN" "$HOOK" < /dev/null 2>&1)
HOOK_EXIT=$?
check "exits 0 when stdin is closed" test "$HOOK_EXIT" -eq 0

# --- The script as Claude Code runs it: executed directly, not through bash ---
check "hook script is executable" test -x "$HOOK"

reset_stubs
stub afplay 0
HOOK_OUTPUT=$(printf '%s' "$PAYLOAD" | PATH="$STUB_DIR" "$HOOK" 2>&1)
HOOK_EXIT=$?
check "exits 0 when run directly through its shebang" test "$HOOK_EXIT" -eq 0
check "plays the sound when run directly through its shebang" test "$(calls)" = "afplay"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
