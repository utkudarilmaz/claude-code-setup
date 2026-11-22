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
check "first apply writes the managed key paths to the snapshot" \
  test "$(jq -c . "$HOME_DIR/.settings.managed.json")" = '{"effortLevel":true,"env":{"REPO":true}}'

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

new_home overrideobject
echo '{"effortLevel":"medium"}' > "$BASE"
echo '{"newObject":{"a":1,"nested":{"b":2}}}' > "$HOME_DIR/settings.overrides.json"
apply
check "an override adds a whole new top-level object" test "$(value .newObject)" = '{"a":1,"nested":{"b":2}}'
echo '{}' > "$HOME_DIR/settings.overrides.json"
apply
check "a dropped override object is deleted with its emptied parents" test "$(value 'has("newObject")')" = "false"

new_home nullwhole
echo '{"permissions":{"allow":["a"]}}' > "$BASE"
echo '{"model":"opus","permissions":{"deny":["d"]}}' > "$HOME_DIR/settings.json"
echo '{"model":null,"permissions":null}' > "$HOME_DIR/settings.overrides.json"
apply
check "a null override deletes a key only the home has" test "$(value 'has("model")')" = "false"
check "a null override deletes a whole object with its local children" \
  test "$(value 'has("permissions")')" = "false"

# --- arrays are replaced whole, never merged ---
new_home arrays
echo '{"permissions":{"allow":["a","b"]}}' > "$BASE"
echo '{"permissions":{"allow":["local"],"deny":["d"]}}' > "$HOME_DIR/settings.json"
apply
check "a base array replaces the local array whole" test "$(value .permissions.allow)" = '["a","b"]'
check "a local-only array survives" test "$(value .permissions.deny)" = '["d"]'
echo '{"permissions":{"allow":["z"]}}' > "$HOME_DIR/settings.overrides.json"
apply
check "an override array replaces the base array whole" test "$(value .permissions.allow)" = '["z"]'
rm "$HOME_DIR/settings.overrides.json"
echo '{}' > "$BASE"
apply
check "an array dropped from the base is deleted" test "$(value '.permissions | has("allow")')" = "false"

new_home falsy
echo '{"flag":false}' > "$BASE"
apply
check "a false value in the base is written, not treated as a delete" test "$(value .flag)" = "false"

# --- a key that only changes type is not reported as removed ---
new_home typeswap
echo '{"statusLine":"plain"}' > "$BASE"
apply
echo '{"statusLine":{"type":"command"}}' > "$BASE"
apply
check "a scalar that becomes an object is not reported as removed" bash -c '! grep -q "^Removed:" "$0"' "$TMP/out"
echo '{"statusLine":"plain"}' > "$BASE"
apply
check "an object that becomes a scalar is not reported as removed" bash -c '! grep -q "^Removed:" "$0"' "$TMP/out"
check "the new scalar value is written" test "$(value .statusLine)" = '"plain"'

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

new_home checkempty
echo '{}' > "$BASE"
bash "$APPLY" --check "$BASE" "$HOME_DIR" >/dev/null 2>&1
check "--check exits 1 when settings.json is missing even if the base is empty" test $? -eq 1
check "--check writes no settings.json" test ! -e "$HOME_DIR/settings.json"
check "--check writes no snapshot" test ! -e "$HOME_DIR/.settings.managed.json"

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

PRUNE="modelSettings,env" bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "PRUNE with env after a comma fails" test $? -ne 0
check "PRUNE with env after a comma keeps secrets" test "$(value .env.SECRET)" = '"s"'

prunes_many() {
  new_home prunemany
  echo '{"a":{"keep":1}}' > "$BASE"
  echo '{"a":{"old":1},"b":{"old":1},"c":{"old":1}}' > "$HOME_DIR/settings.json"
  PRUNE="$1" bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1 || return 1
  test "$(jq -S -c . "$HOME_DIR/settings.json")" = '{"a":{"keep":1},"c":{"old":1}}'
}

check "PRUNE with keys split by spaces clears each key and no other" prunes_many "a b"
check "PRUNE with keys split by a comma clears each key and no other" prunes_many "a,b"
check "PRUNE with keys split by a comma and a space clears each key and no other" prunes_many "a, b"

# --- writing in place keeps a symlinked settings.json a symlink ---
new_home symlink
echo '{"effortLevel":"medium"}' > "$BASE"
echo '{}' > "$TMP/real-settings.json"
ln -s "$TMP/real-settings.json" "$HOME_DIR/settings.json"
apply
check "a symlinked settings.json stays a symlink" test -L "$HOME_DIR/settings.json"
check "a symlinked settings.json gets the change" \
  test "$(jq -c .effortLevel "$TMP/real-settings.json")" = '"medium"'

# --- the snapshot holds no values from the overrides ---
new_home snapshotsecret
echo '{"env":{"REPO":"1"}}' > "$BASE"
echo '{"env":{"API_KEY":"override-secret"}}' > "$HOME_DIR/settings.overrides.json"
apply
check "an override secret reaches settings.json" test "$(value .env.API_KEY)" = '"override-secret"'
check "the snapshot does not copy an override secret" \
  bash -c '! grep -q "override-secret" "$0"' "$HOME_DIR/.settings.managed.json"
echo '{}' > "$HOME_DIR/settings.overrides.json"
apply
check "a key dropped from the overrides is still deleted with a value-free snapshot" \
  test "$(value '.env | has("API_KEY")')" = "false"

# --- new files are private, existing modes are kept ---
file_mode() {
  ls -l "$1" | cut -c1-10
}

new_home modes
echo '{"effortLevel":"medium"}' > "$BASE"
apply
check "a new settings.json is readable only by the owner" test "$(file_mode "$HOME_DIR/settings.json")" = "-rw-------"
check "a new snapshot is readable only by the owner" \
  test "$(file_mode "$HOME_DIR/.settings.managed.json")" = "-rw-------"
chmod 640 "$HOME_DIR/settings.json"
echo '{"effortLevel":"high"}' > "$BASE"
apply
check "an update keeps the mode of settings.json" test "$(file_mode "$HOME_DIR/settings.json")" = "-rw-r-----"

# --- a broken or non-object file is never replaced ---
refuses() {
  local file="$1" content="$2"
  new_home refuse
  echo '{"effortLevel":"medium"}' > "$BASE"
  echo '{"env":{"SECRET":"s"}}' > "$HOME_DIR/settings.json"
  printf '%s' "$content" > "$HOME_DIR/$file"
  cp "$HOME_DIR/settings.json" "$TMP/refuse.before"
  if apply; then return 1; fi
  cmp -s "$TMP/refuse.before" "$HOME_DIR/settings.json" || return 1
  grep -q "must hold one JSON object" "$TMP/out"
}

check "a settings.json with two JSON values is refused" refuses settings.json '{"a":1}{"env":{"SECRET":"s"}}'
check "a settings.json that is an array is refused" refuses settings.json '[]'
check "an empty settings.json is refused" refuses settings.json ''
check "a settings.json with broken JSON is refused" refuses settings.json '{"env":'
check "an overrides file that is null is refused" refuses settings.overrides.json 'null'
check "a broken snapshot is refused" refuses .settings.managed.json '{"a":'

refuses_base() {
  new_home refusebase
  echo '{"env":{"SECRET":"s"}}' > "$HOME_DIR/settings.json"
  printf '%s' "$1" > "$BASE"
  cp "$HOME_DIR/settings.json" "$TMP/refuse.before"
  if apply; then return 1; fi
  cmp -s "$TMP/refuse.before" "$HOME_DIR/settings.json" || return 1
  test ! -e "$HOME_DIR/.settings.managed.json" || return 1
  grep -q "must hold one JSON object" "$TMP/out"
}

check "a base with broken JSON is refused" refuses_base '{"a":'
check "a base with two JSON values is refused" refuses_base '{"a":1}{"b":2}'
check "a base that is an array is refused" refuses_base '[]'

new_home refusevalue
echo '{"effortLevel":"medium"}' > "$BASE"
echo '{"env":{"SECRET":"hidden-value"}} []' > "$HOME_DIR/settings.json"
apply
check "a refused settings.json is not printed" bash -c '! grep -q "hidden-value" "$0"' "$TMP/out"

new_home nobase
echo '{"env":{"SECRET":"s"}}' > "$HOME_DIR/settings.json"
apply
check "a missing base fails" test $? -ne 0
check "a missing base leaves settings.json alone" test "$(value .env.SECRET)" = '"s"'

# --- env can not be wiped by the base or the overrides ---
new_home envnull
echo '{"env":{"REPO":"1"}}' > "$BASE"
echo '{"env":{"SECRET":"s"}}' > "$HOME_DIR/settings.json"
echo '{"env":null}' > "$HOME_DIR/settings.overrides.json"
apply
check "a null env override fails" test $? -ne 0
check "a null env override keeps secrets" test "$(value .env.SECRET)" = '"s"'
echo '{"env":"x"}' > "$HOME_DIR/settings.overrides.json"
apply
check "a non-object env override fails" test $? -ne 0
check "a non-object env override keeps secrets" test "$(value .env.SECRET)" = '"s"'
echo '{"env":{"REPO":null}}' > "$HOME_DIR/settings.overrides.json"
apply
check "a null override of one env key still works" test "$(value .env)" = '{"SECRET":"s"}'

new_home emptyenv
echo '{"env":{}}' > "$BASE"
echo '{"env":{"SECRET":"s"}}' > "$HOME_DIR/settings.json"
apply
echo '{"env":{"REPO":"1"}}' > "$BASE"
apply
check "an empty env in the base that later gets keys keeps secrets" test "$(value .env.SECRET)" = '"s"'
check "an empty env in the base that later gets keys is not reported removed" \
  bash -c '! grep -q "Removed: env" "$0"' "$TMP/out"

new_home emptyobject
echo '{"permissions":{}}' > "$BASE"
apply
echo '{}' > "$BASE"
apply
check "a managed empty object that is still empty is deleted" test "$(value 'has("permissions")')" = "false"

# --- DRY_RUN hides env values ---
new_home dryrunsecret
echo '{"effortLevel":"medium","env":{"REPO":"1"}}' > "$BASE"
echo '{"effortLevel":"high","env":{"API_KEY":"old-secret","REPO":"1"}}' > "$HOME_DIR/settings.json"
echo '{"env":{"API_KEY":"new-secret"}}' > "$HOME_DIR/settings.overrides.json"
DRY_RUN=1 bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "DRY_RUN=1 does not print an old env value" bash -c '! grep -q "old-secret" "$0"' "$TMP/out"
check "DRY_RUN=1 does not print a new env value" bash -c '! grep -q "new-secret" "$0"' "$TMP/out"
check "DRY_RUN=1 marks a changed env value" grep -q '^+ *"API_KEY": "<hidden, changed>"' "$TMP/out"
check "DRY_RUN=1 still prints other changes" grep -q '^+ *"effortLevel": "medium"' "$TMP/out"

# --- a failed write keeps the old settings.json ---
if [ "$(id -u)" != "0" ]; then
  new_home writefail
  echo '{"effortLevel":"medium"}' > "$BASE"
  echo '{"env":{"SECRET":"s"}}' > "$HOME_DIR/settings.json"
  chmod 400 "$HOME_DIR/settings.json"
  apply
  check "a failed write exits non-zero" test $? -ne 0
  check "a failed write leaves settings.json whole" test "$(value .env.SECRET)" = '"s"'
  saved=$(sed -n 's/.*The old file is saved in //p' "$TMP/out")
  check "a failed write that can not put the file back says where the old file is" test -f "$saved"
  [ -n "$saved" ] && rm -rf "$(dirname "$saved")"
  chmod 600 "$HOME_DIR/settings.json"
fi

# --- paths with spaces ---
new_home "with space"
echo '{"effortLevel":"medium"}' > "$BASE"
apply
check "a home path with spaces works" test "$(value .effortLevel)" = '"medium"'
bash "$APPLY" "$REPO_ROOT/.claude/settings.json" "$HOME_DIR" >/dev/null 2>&1
STATUS_OUTPUT=$(make -C "$REPO_ROOT" --no-print-directory status TARGET_DIR="$HOME_DIR" 2>&1)
check "make status works with a TARGET_DIR with spaces" \
  bash -c 'printf "%s" "$0" | grep -q "settings.json.*(synced)"' "$STATUS_OUTPUT"
DIFF_OUTPUT=$(make -C "$REPO_ROOT" --no-print-directory diff TARGET_DIR="$HOME_DIR" 2>&1)
check "make diff works with a TARGET_DIR with spaces" \
  bash -c 'printf "%s" "$0" | grep -q "Unchanged: settings.json"' "$DIFF_OUTPUT"

# --- jq is required ---
new_home nojq
echo '{"effortLevel":"medium"}' > "$BASE"
PATH="$TMP/empty-bin" /bin/bash "$APPLY" "$BASE" "$HOME_DIR" >"$TMP/out" 2>&1
check "without jq the script fails" test $? -ne 0
check "without jq the script says jq is required" grep -q 'jq is required' "$TMP/out"
check "without jq nothing is written" test ! -e "$HOME_DIR/settings.json"

# --- the repo base is valid and holds no machine secrets ---
check "repo settings.json is valid JSON" jq empty "$REPO_ROOT/config/settings.json"
check "repo settings.json has no null values" \
  test "$(jq '[paths(. == null)] | length' "$REPO_ROOT/config/settings.json")" = "0"

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
