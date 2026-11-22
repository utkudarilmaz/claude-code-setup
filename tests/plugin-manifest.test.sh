#!/bin/bash
# Tests for the marketplace and the core plugin layout

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO_ROOT/plugins/core"
FAILURES=0
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
  test "$(jq -c '[.plugins[] | select(.name == "core") | .source]' "$REPO_ROOT/.claude-plugin/marketplace.json")" = '["./plugins/core"]'
check "the plugin is named core" test "$(jq -r .name "$PLUGIN/.claude-plugin/plugin.json")" = "core"
check "the plugin pins no version, so every commit reaches users" \
  test "$(jq 'has("version")' "$PLUGIN/.claude-plugin/plugin.json")" = "false"

# --- skills ---
for skill in "$PLUGIN"/skills/*/; do
  dir=$(basename "$skill")
  name=$(frontmatter_name "$skill/SKILL.md")
  check "skill $dir has a frontmatter name matching its folder" test "$name" = "$dir"
  check "skill $dir does not take the name of a built-in command" \
    bash -c 'case " $1 " in *" $0 "*) exit 1 ;; esac' "$name" "$BUILTIN_COMMANDS"
done

# --- agents ---
for agent in "$PLUGIN"/agents/*.md; do
  file=$(basename "$agent" .md)
  check "agent $file has a frontmatter name matching its file" test "$(frontmatter_name "$agent")" = "$file"
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
