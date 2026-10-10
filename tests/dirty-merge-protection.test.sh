#!/bin/bash

HOOK="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/dirty-merge-protection.sh"
FAILURES=0

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

make_repo() {
  git init -q "$1"
  git -C "$1" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m init
}

CLEAN="$TMP/clean"
DIRTY="$TMP/dirty"
UNTRACKED="$TMP/untracked"
make_repo "$CLEAN"
make_repo "$DIRTY"
make_repo "$UNTRACKED"
echo a > "$DIRTY/file.txt"
git -C "$DIRTY" add file.txt
echo b > "$UNTRACKED/new.txt"
mkdir "$TMP/plain"
HOSTILE="$TMP/hostile"
make_repo "$HOSTILE"
git -C "$HOSTILE" config core.fsmonitor "touch '$TMP/fsmonitor-ran'; echo"

run_case() {
  local description="$1"
  local command="$2"
  local cwd="$3"
  local expected_exit="$4"
  local expected_output="$5"
  local payload output actual_exit

  payload=$(jq -n --arg c "$command" --arg d "$cwd" '{tool_name: "Bash", tool_input: {command: $c}, cwd: $d}')
  output=$(echo "$payload" | HOME="${CASE_HOME:-$HOME}" PATH="${CASE_PATH:-$PATH}" "$BASH" "$HOOK" 2>&1)
  actual_exit=$?

  if [ "$actual_exit" -ne "$expected_exit" ]; then
    echo "FAIL: $description (expected exit $expected_exit, got $actual_exit)"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if [ "$expected_exit" -eq 2 ] && ! echo "$output" | grep -q "Uncommitted changes"; then
    echo "FAIL: $description (blocked but no 'Uncommitted changes' message)"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if [ -n "$expected_output" ] && ! echo "$output" | grep -qF "$expected_output"; then
    echo "FAIL: $description (output does not contain '$expected_output')"
    FAILURES=$((FAILURES + 1))
    return
  fi

  echo "PASS: $description"
}

run_case "blocks git merge in dirty repo" "git merge feat/x" "$DIRTY" 2
run_case "blocks git merge with untracked files" "git merge feat/x" "$UNTRACKED" 2
run_case "blocks gh pr merge in dirty repo" "gh pr merge 12 --squash" "$DIRTY" 2
run_case "blocks chained git merge in dirty repo" "git checkout main && git merge feat/x" "$DIRTY" 2
run_case "blocks git -C merge on dirty repo" "git -C $DIRTY merge feat/x" "$CLEAN" 2
run_case "blocks cd into dirty repo then merge" "cd $DIRTY && git merge feat/x" "$CLEAN" 2
run_case "blocks cd later in the command then merge" "git status && cd $DIRTY && git merge feat/x" "$CLEAN" 2
run_case "blocks cd inside a subshell then merge" "(cd $DIRTY && git merge feat/x)" "$CLEAN" 2
run_case "uses the last cd before merge" "cd $DIRTY && cd $CLEAN && git merge feat/x" "$DIRTY" 0
run_case "blocks merge chained after git merge --abort" "git merge --abort && git merge feat/x" "$DIRTY" 2
run_case "blocks gh pr merge chained with git merge --continue" "git merge --continue && gh pr merge 12" "$DIRTY" 2
run_case "blocks relative cd into dirty repo then merge" "cd dirty && git merge feat/x" "$TMP" 2
run_case "blocks quoted cd into dirty repo then merge" "cd \"$DIRTY\" && git merge feat/x" "$CLEAN" 2
run_case "blocks relative git -C merge on dirty repo" "git -C dirty merge feat/x" "$TMP" 2
CASE_HOME="$TMP" run_case "blocks cd into ~ dirty repo then merge" "cd ~/dirty && git merge feat/x" "$CLEAN" 2
CASE_HOME="$TMP" run_case "blocks git -C ~ merge on dirty repo" "git -C ~/dirty merge feat/x" "$CLEAN" 2
run_case "lists changed files when blocking" "git merge feat/x" "$DIRTY" 2 "file.txt"
run_case "lists untracked files when blocking" "git merge feat/x" "$UNTRACKED" 2 "new.txt"
run_case "names the dirty directory when blocking" "git -C $DIRTY merge feat/x" "$CLEAN" 2 "$DIRTY"
run_case "allows relative cd into clean repo then merge" "cd clean && git merge feat/x" "$TMP" 0
run_case "allows git merge in clean repo" "git merge feat/x" "$CLEAN" 0
run_case "allows gh pr merge in clean repo" "gh pr merge 12" "$CLEAN" 0
run_case "allows git -C merge on clean repo" "git -C $CLEAN merge feat/x" "$DIRTY" 0
run_case "allows git merge --abort in dirty repo" "git merge --abort" "$DIRTY" 0
run_case "allows git merge --continue in dirty repo" "git merge --continue" "$DIRTY" 0
run_case "allows git merge-base in dirty repo" "git merge-base main HEAD" "$DIRTY" 0
run_case "allows git mergetool in dirty repo" "git mergetool" "$DIRTY" 0
run_case "allows other git commands in dirty repo" "git status" "$DIRTY" 0
run_case "allows merge outside a git repo" "git merge feat/x" "$TMP/plain" 0
run_case "allows empty command" "" "$DIRTY" 0

NOJQ_BIN="$TMP/nojq-bin"
mkdir "$NOJQ_BIN"
NOJQ_OK=1
for tool in cat sed grep git head tr; do
  tool_path=$(command -v "$tool") && ln -s "$tool_path" "$NOJQ_BIN/$tool" || NOJQ_OK=0
done
if [ "$NOJQ_OK" -eq 1 ] && ! PATH="$NOJQ_BIN" "$BASH" -c 'command -v jq' >/dev/null 2>&1; then
  CASE_PATH="$NOJQ_BIN" run_case "blocks git merge in dirty repo without jq" "git merge feat/x" "$DIRTY" 2 "file.txt"
  CASE_PATH="$NOJQ_BIN" run_case "blocks cd into dirty repo then merge without jq" "cd $DIRTY && git merge feat/x" "$CLEAN" 2
  CASE_PATH="$NOJQ_BIN" run_case "allows git merge in clean repo without jq" "git merge feat/x" "$CLEAN" 0
  CASE_PATH="$NOJQ_BIN" run_case "allows git merge --abort in dirty repo without jq" "git merge --abort" "$DIRTY" 0
else
  echo "SKIP: jq fallback cases (could not build a PATH without jq)"
fi

run_case "allows merge in clean repo with hostile fsmonitor config" "git -C $HOSTILE merge feat/x" "$CLEAN" 0
if [ -e "$TMP/fsmonitor-ran" ]; then
  echo "FAIL: hook ran core.fsmonitor from the target repo config"
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: hook ignores core.fsmonitor from the target repo config"
fi

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
