#!/bin/bash
# Tests for scripts/apply-settings.sh and scripts/settings-merge.jq

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPLY="$REPO_ROOT/scripts/apply-settings.sh"
FAILURES=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

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

new_home() {
  HOME_DIR="$TMP/$1"
  BASE="$TMP/$1.base.json"
  mkdir -p "$HOME_DIR"
}

apply() {
  bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
}

value() {
  jq -c "$1" "$HOME_DIR/settings.json"
}

# --- first apply into an empty home ---
new_home first
echo '{"effortLevel":"medium","env":{"REPO":"1"}}' > "$BASE"
apply
check "first apply creates settings.json from the base" \
  test "$(value .)" = '{"effortLevel":"medium","env":{"REPO":"1"}}'
check "first apply writes the managed snapshot" \
  test "$(jq -c . "$HOME_DIR/.settings.managed.json")" = '{"effortLevel":"medium","env":{"REPO":"1"}}'

# --- local keys stay, repo values win ---
new_home local
echo '{"effortLevel":"medium","env":{"REPO":"1"}}' > "$BASE"
echo '{"effortLevel":"high","model":"opus","env":{"SECRET":"s"}}' > "$HOME_DIR/settings.json"
apply
check "a local-only key survives" test "$(value .model)" = '"opus"'
check "a local-only key under a managed parent survives" test "$(value .env.SECRET)" = '"s"'
check "a repo value wins over the local value" test "$(value .effortLevel)" = '"medium"'

# --- keys removed from the base are deleted ---
echo '{"env":{"REPO":"1"}}' > "$BASE"
apply
check "a key removed from the base is deleted" test "$(value 'has("effortLevel")')" = "false"

echo '{}' > "$BASE"
apply
check "a removed key keeps its local siblings" test "$(value .env)" = '{"SECRET":"s"}'

new_home emptied
echo '{"modelSettings":{"a":{"effortLevel":"low"}}}' > "$BASE"
apply
echo '{}' > "$BASE"
apply
check "a parent emptied by a removal is pruned" test "$(value 'has("modelSettings")')" = "false"

# --- a removal through a value the user changed to a non-object does not fail ---
new_home typechange
echo '{"statusLine":{"type":"command"}}' > "$BASE"
apply
echo '{"statusLine":"local"}' > "$HOME_DIR/settings.json"
echo '{}' > "$BASE"
apply
check "a removal through a changed type exits 0" test $? -eq 0
check "a removal through a changed type keeps the local value" test "$(value .statusLine)" = '"local"'

# --- overrides ---
new_home overrides
echo '{"effortLevel":"medium","statusLine":{"type":"command"},"env":{"REPO":"1"}}' > "$BASE"
echo '{"effortLevel":"high","statusLine":null,"env":{"HOST":"x"}}' > "$HOME_DIR/settings.overrides.json"
echo '{"statusLine":{"type":"command"}}' > "$HOME_DIR/settings.json"
apply
check "an override wins over the base" test "$(value .effortLevel)" = '"high"'
check "an override adds a key the base does not have" test "$(value .env.HOST)" = '"x"'
check "an override keeps base siblings" test "$(value .env.REPO)" = '"1"'
check "a null override deletes the base key" test "$(value 'has("statusLine")')" = "false"
check "the snapshot holds no nulls" \
  test "$(jq '[paths(. == null)] | length' "$HOME_DIR/.settings.managed.json")" = "0"

echo '{}' > "$HOME_DIR/settings.overrides.json"
apply
check "a dropped override falls back to the base value" test "$(value .effortLevel)" = '"medium"'
check "a dropped override that is not in the base is deleted" test "$(value '.env | has("HOST")')" = "false"
check "a dropped null override brings the base key back" test "$(value .statusLine.type)" = '"command"'

# --- DRY_RUN ---
new_home dryrun
echo '{"effortLevel":"medium"}' > "$BASE"
echo '{"effortLevel":"high"}' > "$HOME_DIR/settings.json"
DRY_RUN=1 bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "DRY_RUN=1 leaves settings.json alone" test "$(value .effortLevel)" = '"high"'
check "DRY_RUN=1 writes no snapshot" test ! -e "$HOME_DIR/.settings.managed.json"
check "DRY_RUN=1 prints the change" grep -q '"effortLevel": "medium"' "$TMP/out"

new_home dryrunremove
echo '{"effortLevel":"medium"}' > "$BASE"
apply
echo '{}' > "$BASE"
DRY_RUN=1 bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "DRY_RUN=1 lists a deletion as Would remove" grep -q '^Would remove: effortLevel$' "$TMP/out"
check "DRY_RUN=1 does not claim a deletion happened" bash -c '! grep -q "^Removed:" "$0"' "$TMP/out"
apply
check "an apply lists a deletion as Removed" grep -q '^Removed: effortLevel$' "$TMP/out"

# --- --check ---
new_home checkmode
echo '{"effortLevel":"medium"}' > "$BASE"
bash "$APPLY" --check "$BASE" "$HOME_DIR" >/dev/null 2>&1
check "--check exits 1 when an apply would change something" test $? -eq 1
apply
bash "$APPLY" --check "$BASE" "$HOME_DIR" >/dev/null 2>&1
check "--check exits 0 when the home is up to date" test $? -eq 0

# --- PRUNE ---
new_home prune
echo '{"modelSettings":{"new":{"effortLevel":"medium"}},"env":{"REPO":"1"}}' > "$BASE"
echo '{"modelSettings":{"old":{"effortLevel":"low"},"mine":{"effortLevel":"high"}},"env":{"SECRET":"s"},"model":"opus"}' > "$HOME_DIR/settings.json"
echo '{"modelSettings":{"mine":{"effortLevel":"high"}}}' > "$HOME_DIR/settings.overrides.json"
apply
check "without PRUNE a first apply deletes nothing" test "$(value .modelSettings.old.effortLevel)" = '"low"'
PRUNE=modelSettings bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "PRUNE clears stale leaves under the named key" test "$(value '.modelSettings | has("old")')" = "false"
check "PRUNE keeps base leaves" test "$(value .modelSettings.new.effortLevel)" = '"medium"'
check "PRUNE keeps override leaves" test "$(value .modelSettings.mine.effortLevel)" = '"high"'
check "PRUNE leaves other keys alone" test "$(value .model)" = '"opus"'
check "PRUNE leaves env alone" test "$(value .env.SECRET)" = '"s"'

PRUNE="modelSettings env" bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "PRUNE with env fails" test $? -ne 0
check "PRUNE with env says why" grep -q 'env' "$TMP/out"
check "PRUNE with env keeps secrets" test "$(value .env.SECRET)" = '"s"'

# --- writing in place keeps a symlinked settings.json a symlink ---
new_home symlink
echo '{"effortLevel":"medium"}' > "$BASE"
echo '{}' > "$TMP/real-settings.json"
ln -s "$TMP/real-settings.json" "$HOME_DIR/settings.json"
apply
check "a symlinked settings.json stays a symlink" test -L "$HOME_DIR/settings.json"
check "a symlinked settings.json gets the change" \
  test "$(jq -c .effortLevel "$TMP/real-settings.json")" = '"medium"'

# --- jq is required ---
new_home nojq
echo '{"effortLevel":"medium"}' > "$BASE"
PATH="$TMP/empty-bin" /bin/bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "without jq the script fails" test $? -ne 0
check "without jq the script says jq is required" grep -q 'jq is required' "$TMP/out"
check "without jq nothing is written" test ! -e "$HOME_DIR/settings.json"

# --- the repo base is valid and holds no machine secrets ---
check "repo settings.json is valid JSON" jq empty "$REPO_ROOT/.claude/settings.json"
check "repo settings.json has no null values" \
  test "$(jq '[paths(. == null)] | length' "$REPO_ROOT/.claude/settings.json")" = "0"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
