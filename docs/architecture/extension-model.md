# Extension Architecture

## Two-Tier Extension Model

```
┌─────────────────────────────────────────────────────┐
│                    User Input                        │
│                   /docs all                          │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              Skills Layer (SKILL.md)                 │
│  • Parses command arguments                          │
│  • Determines invocation mode                        │
│  • Dispatches to agent via Task tool                 │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              Agents Layer (*.md)                     │
│  • Contains domain expertise                         │
│  • Defines workflows and rules                       │
│  • Executes actual work                              │
└─────────────────────────────────────────────────────┘
```

**Skills** provide the `/command` interface and dispatch logic.
**Agents** contain the specialized knowledge and execution workflows.

## Hook System

Hooks intercept tool calls for pre/post processing:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "script.sh"}]
    }]
  }
}
```

### Current Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `suggest-compact.sh` | Every 50 tool calls | Suggests `/compact` at logical intervals |
| `sensitive-file-protection` | Edit\|Write | Blocks writes to protected files (.env, credentials, secrets, lock files) |
| `notification` | Idle/permission | Plays audio notification on idle or permission prompts |

## Directory Structure

```
.claude/
├── agents/           # Agent definitions (domain expertise)
│   ├── docs.md
│   ├── tester.md
│   ├── pr-check.md
│   ├── security-reviewer.md
│   ├── simplifier.md
│   ├── release-notes.md
│   ├── changelog-generator.md
│   └── devops.md
├── hooks/            # Hook scripts (tool call interception)
│   └── suggest-compact.sh
├── skills/           # Skill commands (user interface)
│   ├── docs/SKILL.md
│   ├── tester/SKILL.md
│   ├── pr-check/SKILL.md
│   ├── security-review/SKILL.md
│   ├── simplifier/SKILL.md
│   ├── changelog/SKILL.md
│   └── devops/SKILL.md
├── settings.json     # Hooks, plugins, statusLine
└── CLAUDE.md         # Global conventions
```

## Flow Example

1. User invokes `/docs all`
2. Skills layer (SKILL.md) parses arguments, determines "comprehensive" mode
3. Skills layer dispatches to `docs` agent via Task tool
4. Agent layer (docs.md) creates TodoWrite plan, executes documentation tasks
5. Agent completes work, returns summary
