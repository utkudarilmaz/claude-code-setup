#!/bin/bash
# Tests for the marketplace and the core plugin layout

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO_ROOT/plugins/core"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
FAILURES=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
BUILTIN_COMMANDS="add-dir agents bug clear code-review compact config context cost doctor effort exit export fast help hooks ide init login logout loop mcp memory model permissions plugin pr-comments release-notes resume review rewind run schedule security-review simplify status statusline upgrade usage vim"

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

frontmatter_name() {
  awk '/^---$/ { n++; next } n == 1 && /^name:/ { sub(/^name:[ ]*/, ""); print; exit }' "$1"
}

# --- every JSON file parses ---
while IFS= read -r file; do
  check "$file is valid JSON" jq empty "$REPO_ROOT/$file"
done < <(cd "$REPO_ROOT" && git ls-files '*.json')

# --- the manifests point at each other ---
check "the marketplace lists core at ./plugins/core" \
  test "$(jq -c '[.plugins[] | select(.name == "core") | .source]' "$MARKETPLACE")" = '["./plugins/core"]'
check "the plugin is named core" test "$(jq -r .name "$PLUGIN/.claude-plugin/plugin.json")" = "core"
check "the plugin pins no version, so every commit reaches users" \
  test "$(jq 'has("version")' "$PLUGIN/.claude-plugin/plugin.json")" = "false"
check "the marketplace and plugin.json describe core the same way" \
  test "$(jq -r '.plugins[] | select(.name == "core") | .description' "$MARKETPLACE")" = "$(jq -r .description "$PLUGIN/.claude-plugin/plugin.json")"

MARKETPLACE_NAME=$(jq -r .name "$MARKETPLACE")
check "base settings enable core under the marketplace's own name" \
  test "$(jq -r --arg k "core@$MARKETPLACE_NAME" '.enabledPlugins[$k]' "$REPO_ROOT/config/settings.json")" = "true"
check "base settings fetch the marketplace from the plugin's repository" \
  test "https://github.com/$(jq -r --arg m "$MARKETPLACE_NAME" '.extraKnownMarketplaces[$m].source.repo' "$REPO_ROOT/config/settings.json")" = "$(jq -r .repository "$PLUGIN/.claude-plugin/plugin.json")"

# --- skills ---
for skill in "$PLUGIN"/skills/*/; do
  dir=$(basename "$skill")
  name=$(frontmatter_name "$skill/SKILL.md")
  check "skill $dir has a frontmatter name matching its folder" test "$name" = "$dir"
  check "skill $dir does not take the name of a built-in command" \
    bash -c 'case " $1 " in *" $0 "*) exit 1 ;; esac' "$name" "$BUILTIN_COMMANDS"
  check "the plugin README lists /$dir" grep -qF "\`/$dir\`" "$PLUGIN/README.md"
  case "$dir" in
    changelog | release-tag) ;;
    *) check "skill $dir dispatches the agent of the same name" grep -qF "subagent_type=\"core:$dir\"" "$skill/SKILL.md" ;;
  esac
done

unknown_readme_skills=$(grep -oE '`/[a-z0-9-]+`' "$PLUGIN/README.md" | tr -d '`/' | sort -u | while read -r name; do
  test -f "$PLUGIN/skills/$name/SKILL.md" || echo "/$name"
done)
check "every skill the plugin README lists exists" test -z "$unknown_readme_skills"
[ -n "$unknown_readme_skills" ] && echo "  unknown: $unknown_readme_skills"

check "release-tag invokes core:changelog through the Skill tool" \
  grep -qE 'Skill tool to invoke `core:changelog`' "$PLUGIN/skills/release-tag/SKILL.md"

missing_skills=$(grep -rhoE 'Skill tool to invoke `[^`]+`' "$PLUGIN" | sed -E 's/.*`([^`]+)`$/\1/' | sort -u | while read -r ref; do
  case "$ref" in
    core:*) test -f "$PLUGIN/skills/${ref#core:}/SKILL.md" || echo "$ref" ;;
    *) echo "$ref" ;;
  esac
done)
check "every Skill tool call names a core: skill that exists" test -z "$missing_skills"
[ -n "$missing_skills" ] && echo "  missing: $missing_skills"

unrooted_refs=$(
  for skill in "$PLUGIN"/skills/*/; do
    awk -v skill="$(basename "$skill")" '
      /^```/ { inside = !inside; dispatch = 0; next }
      inside && /subagent_type=/ { dispatch = 1 }
      inside && dispatch {
        line = $0
        while (match(line, /[^ "`(*]*references\/[A-Za-z0-9_.-]+/)) {
          ref = substr(line, RSTART, RLENGTH)
          if (ref !~ /^[$][{]CLAUDE_(SKILL_DIR|PLUGIN_ROOT)[}]\//) print skill ": " ref
          line = substr(line, RSTART + RLENGTH)
        }
      }
    ' "$skill/SKILL.md"
  done
  for agent in "$PLUGIN"/agents/*.md; do
    grep -oE '[^ "`(*]*references/[A-Za-z0-9_.-]+' "$agent" | grep -vE '^[$][{]CLAUDE_PLUGIN_ROOT[}]/' | sed "s|^|$(basename "$agent"): |"
  done
)
check "every references/ path an agent reads starts at \${CLAUDE_SKILL_DIR} or \${CLAUDE_PLUGIN_ROOT}" test -z "$unrooted_refs"
[ -n "$unrooted_refs" ] && echo "  unrooted: $unrooted_refs"

# --- agents ---
for agent in "$PLUGIN"/agents/*.md; do
  file=$(basename "$agent" .md)
  check "agent $file has a frontmatter name matching its file" test "$(frontmatter_name "$agent")" = "$file"
  check "agent $file is dispatched by a skill" grep -rqF "subagent_type=\"core:$file\"" "$PLUGIN/skills"
done

missing_agents=$(grep -rhoE 'subagent_type="[^"]*"' "$PLUGIN" | sed 's/subagent_type="//; s/"$//' | sort -u | while read -r ref; do
  case "$ref" in
    core:*) test -f "$PLUGIN/agents/${ref#core:}.md" || echo "$ref" ;;
    *) echo "$ref" ;;
  esac
done)
check "every subagent_type names a core: agent that exists" test -z "$missing_agents"
[ -n "$missing_agents" ] && echo "  missing: $missing_agents"

# --- paths inside skills, agents and hooks resolve ---
missing_paths=$(
  grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' "$PLUGIN" | sort -u | while read -r ref; do
    test -e "$PLUGIN/${ref#\$\{CLAUDE_PLUGIN_ROOT\}/}" || echo "$ref"
  done
  for skill in "$PLUGIN"/skills/*/; do
    grep -hoE '\$\{CLAUDE_SKILL_DIR\}/[A-Za-z0-9_./-]+' "$skill/SKILL.md" | sort -u | while read -r ref; do
      test -e "$skill/${ref#\$\{CLAUDE_SKILL_DIR\}/}" || echo "$skill: $ref"
    done
  done
)
check "every \${CLAUDE_PLUGIN_ROOT} and \${CLAUDE_SKILL_DIR} path exists" test -z "$missing_paths"
[ -n "$missing_paths" ] && echo "  missing: $missing_paths"

# --- hooks ---
while IFS= read -r command; do
  script="$PLUGIN/${command#*\$\{CLAUDE_PLUGIN_ROOT\}/}"
  script="${script%\"}"
  check "hook $(basename "$script") is executable" test -x "$script"
done < <(jq -r '.hooks[][].hooks[].command' "$PLUGIN/hooks/hooks.json")

for script in "$PLUGIN"/hooks/*.sh; do
  check "hook $(basename "$script") is wired in hooks.json" \
    grep -qF "/hooks/$(basename "$script")" "$PLUGIN/hooks/hooks.json"
done

hook_matcher() {
  jq -r --arg e "$1" --arg s "/hooks/$2" \
    '.hooks[$e][]? | select(any(.hooks[]; .command | contains($s))) | .matcher // "(any)"' "$PLUGIN/hooks/hooks.json"
}

check "sensitive-file-protection runs before Edit and Write" \
  test "$(hook_matcher PreToolUse sensitive-file-protection.sh)" = "Edit|Write"
check "dirty-merge-protection runs before Bash" \
  test "$(hook_matcher PreToolUse dirty-merge-protection.sh)" = "Bash"
check "notification runs on every Notification" \
  test "$(hook_matcher Notification notification.sh)" = "(any)"

# The space in CLAUDE_PLUGIN_ROOT catches a hooks.json command that is not quoted.
mkdir -p "$TMP/stubs" "$TMP/root parent"
ln -s "$PLUGIN" "$TMP/root parent/plugin root"
printf '#!/bin/sh\ntouch "%s/afplay-ran"\n' "$TMP" > "$TMP/stubs/afplay"
chmod +x "$TMP/stubs/afplay"
git init -q "$TMP/clean"
git init -q "$TMP/dirty"
touch "$TMP/dirty/new.txt"

run_wired_hook() {
  local command
  command=$(jq -r --arg s "/hooks/$1" '.hooks[][].hooks[].command | select(contains($s))' "$PLUGIN/hooks/hooks.json")
  [ -z "$command" ] && echo "not wired" && return
  printf '%s' "$2" | CLAUDE_PLUGIN_ROOT="$TMP/root parent/plugin root" PATH="$TMP/stubs:$PATH" sh -c "$command" >/dev/null 2>&1
  echo $?
}

edit_payload() { jq -nc --arg p "$1" '{tool_name: "Edit", tool_input: {file_path: $p, old_string: "a", new_string: "b"}}'; }
bash_payload() { jq -nc --arg c "$1" --arg d "$2" '{tool_name: "Bash", tool_input: {command: $c}, cwd: $d}'; }

check "the wired sensitive-file-protection blocks an edit to .env" \
  test "$(run_wired_hook sensitive-file-protection.sh "$(edit_payload /app/.env)")" = "2"
check "the wired sensitive-file-protection allows an edit to README.md" \
  test "$(run_wired_hook sensitive-file-protection.sh "$(edit_payload /app/README.md)")" = "0"
check "the wired dirty-merge-protection blocks a merge in a dirty repo" \
  test "$(run_wired_hook dirty-merge-protection.sh "$(bash_payload 'git merge main' "$TMP/dirty")")" = "2"
check "the wired dirty-merge-protection allows a merge in a clean repo" \
  test "$(run_wired_hook dirty-merge-protection.sh "$(bash_payload 'git merge main' "$TMP/clean")")" = "0"
check "the wired notification exits 0" \
  test "$(run_wired_hook notification.sh '{"hookEventName":"Notification","message":"hi"}')" = "0"
check "the wired notification plays the sound" test -e "$TMP/afplay-ran"

# --- claude plugin validate, when the CLI is installed ---
only_version_warnings() {
  claude plugin validate --json "$1" 2>/dev/null \
    | jq -e '.success and (.manifest.errors | length == 0) and ([.manifest.warnings[] | select(.path | test("version$") | not)] | length == 0)' >/dev/null
}

if command -v claude >/dev/null 2>&1; then
  check "claude plugin validate passes for the marketplace" only_version_warnings "$REPO_ROOT"
  check "claude plugin validate passes for the core plugin" only_version_warnings "$PLUGIN"
else
  echo "SKIP: claude is not installed, so claude plugin validate did not run"
fi

echo ""
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "All tests passed"
