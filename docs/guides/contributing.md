# Contributing

## Adding New Extensions

### New Agent

1. Create `plugins/core/agents/<name>.md`:
   ```yaml
   ---
   name: agent-name
   description: "When to invoke..."
   model: sonnet  # optional
   color: blue    # optional
   ---

   [Agent persona, responsibilities, workflow]
   ```

2. The agent loads as `core:<name>`. Dispatch it from a skill with `subagent_type="core:<name>"`

### New Skill

1. Create `plugins/core/skills/<name>/SKILL.md`. The `name` must match the folder and must not be a built-in command such as `review` or `security-review`:
   ```yaml
   ---
   name: skill-name
   description: When to use this skill
   ---

   [Invocation modes, dispatch logic, examples]
   ```

2. The skill is available as `/<name>`, and as `/core:<name>` when another
   command has the same name
3. In a prompt passed to an agent, point at reference files with
   `${CLAUDE_SKILL_DIR}/references/<file>.md`, or
   `${CLAUDE_PLUGIN_ROOT}/skills/<other skill>/references/<file>.md` for another
   skill's files. Claude Code replaces both when it loads the skill

### New Hook

1. Create the hook script in `plugins/core/hooks/<script>.sh`
2. Make it executable: `chmod +x plugins/core/hooks/<script>.sh`
3. Add it to `plugins/core/hooks/hooks.json`:
   ```json
   {
     "hooks": {
       "PreToolUse": [{
         "matcher": "ToolPattern",
         "hooks": [{"type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh\""}]
       }]
     }
   }
   ```

**Cross-platform considerations:**
- Use bash scripts with `#!/bin/bash` shebang
- Avoid hardcoded paths (use `$(command -v <tool>)` for executables)
- For platform-specific features, use fallback chains:
  ```bash
  command_mac || command_linux || true
  ```
- Test on both macOS and Linux when possible

### New External Tool or MCP Server

The Makefile does not install programs or MCP servers. When a plugin or skill
needs a program, add its setup steps to [External Tools](external-tools.md).
Add MCP server steps to [MCP Servers](../reference/mcp-servers.md).

## Code Guidelines

1. Follow existing patterns for agents/skills
2. Use conventional commits
3. Update the docs when adding new extensions
4. Try skills before committing with `claude --plugin-dir ./plugins/core`
5. Ensure cross-platform compatibility (macOS and Linux)
6. Avoid hardcoded paths in hooks and statusLine configurations
7. Run `make test` before committing; add tests when changing hook scripts, the scripts in `scripts/`, the Makefile, or the plugin layout

## Conventional Commits

Format: `<type>: <description>`

| Type | Purpose |
|------|---------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `refactor:` | Code restructure |
| `perf:` | Performance improvement |
| `test:` | Adding tests |
| `chore:` | Maintenance tasks |

## File Structure Conventions

- Agent files: `plugins/core/agents/<name>.md`
- Skill files: `plugins/core/skills/<name>/SKILL.md`
- When a skill dispatches to exactly one agent, the skill directory and the agent file share the same name (e.g. `skills/seo/` and `agents/seo.md`)
- Hook scripts: `plugins/core/hooks/<script>.sh`, wired in `plugins/core/hooks/hooks.json`
- Leave `version` out of `plugins/core/.claude-plugin/plugin.json`, so every commit on `main` reaches users
- JSON fields: always camelCase
