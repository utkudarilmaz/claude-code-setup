# Contributing

## Adding New Extensions

### New Agent

1. Create `.claude/agents/<name>.md`:
   ```yaml
   ---
   name: agent-name
   description: "When to invoke..."
   model: sonnet  # optional
   color: blue    # optional
   ---

   [Agent persona, responsibilities, workflow]
   ```

2. Agent is available via `Task` tool with `subagent_type="<name>"`

### New Skill

1. Create `.claude/skills/<name>/SKILL.md`:
   ```yaml
   ---
   name: skill-name
   description: When to use this skill
   ---

   [Invocation modes, dispatch logic, examples]
   ```

2. Skill is available as `/<name>` command

### New Hook

Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "ToolPattern",
      "hooks": [{"type": "command", "command": "path/to/script.sh"}]
    }]
  }
}
```

## Code Guidelines

1. Follow existing patterns for agents/skills
2. Use conventional commits
3. Update CLAUDE.md when adding new extensions
4. Test skills before committing

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

- Agent files: `.claude/agents/<name>.md`
- Skill files: `.claude/skills/<name>/SKILL.md`
- Hook scripts: `.claude/skills/<name>/<script>.sh`
- JSON fields: always camelCase
- Tags: without `v` prefix (e.g., `1.0.0`, not `v1.0.0`)
