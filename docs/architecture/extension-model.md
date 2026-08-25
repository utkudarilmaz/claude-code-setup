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

**Skills** provide the `/command` interface and dispatch logic. Skills follow a progressive disclosure pattern: SKILL.md is a lean dispatch layer; detailed mode content (checklists, patterns, execution flows) lives in `references/` subdirectories.
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

| Hook | Trigger | Purpose | Platform Support |
|------|---------|---------|------------------|
| `sensitive-file-protection` | Edit\|Write | Blocks writes to protected files (.env, credentials, secrets, lock files) via exit code 2 | All |
| `notification` | All notifications | Plays audio notification when Claude Code sends a notification | macOS (afplay), Linux (paplay/aplay) |

**Cross-platform notification implementation:**
- macOS: `afplay /System/Library/Sounds/Glass.aiff`
- Linux (PulseAudio): `paplay /usr/share/sounds/freedesktop/stereo/complete.oga`
- Linux (ALSA): `aplay /usr/share/sounds/alsa/Front_Center.wav`
- Fallback chain ensures compatibility across platforms

## Directory Structure

```
.claude/
├── agents/           # Agent definitions (domain expertise)
│   ├── docs.md
│   ├── tester.md
│   ├── security-reviewer.md
│   ├── simplifier.md
│   ├── release-notes.md
│   ├── changelog-generator.md
│   ├── seo-optimizer.md
│   ├── create-pr.md
│   ├── text-slop-cleaner.md
│   ├── code-slop-cleaner.md
│   ├── explain.md
│   ├── review-analyzer.md
│   └── pr-comment-cleaner.md
├── hooks/            # Hook scripts (tool call interception)
│   ├── sensitive-file-protection.sh
│   └── notification.sh
├── skills/           # Skill commands (user interface)
│   ├── docs/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── comprehensive-mode.md
│   │       └── simplifier-mode.md
│   ├── tester/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── comprehensive-mode.md
│   ├── security-review/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── comprehensive-mode.md
│   ├── simplifier/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── go-patterns.md
│   │       ├── js-ts-patterns.md
│   │       └── python-patterns.md
│   ├── changelog/SKILL.md
│   ├── release-tag/SKILL.md
│   ├── seo/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── comprehensive-mode.md
│   │       └── audit-mode.md
│   ├── create-pr/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── pr-creation.md
│   ├── text-slop-cleaner/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── slop-patterns.md
│   ├── code-slop-cleaner/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── change-patterns.md
│   ├── explain/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── deep-mode.md
│   ├── review-analyzer/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── fix-validity-patterns.md
│   └── pr-comment-cleaner/
│       ├── SKILL.md
│       └── references/
│           └── comment-necessity.md
├── settings.json     # Hooks, plugins, statusLine (cross-platform)
└── CLAUDE.md         # Global conventions
```

## Platform Compatibility

### Node.js Path Resolution

The `statusLine` configuration uses dynamic node path resolution for cross-platform compatibility:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash -c '... $(\"$(command -v node)\" ...) ...'"
  }
}
```

This avoids hardcoding `/usr/bin/node` and works on:
- macOS (Homebrew): `/opt/homebrew/bin/node`
- macOS (nvm): `~/.nvm/versions/node/*/bin/node`
- Linux: `/usr/bin/node`
- Any custom installation location

### Audio Notification Support

The notification hook uses a fallback chain to support multiple platforms and audio systems. See **Current Hooks** section above for details.

## Flow Example

1. User invokes `/docs all`
2. Skills layer (SKILL.md) parses arguments, determines "comprehensive" mode
3. Skills layer reads `references/comprehensive-mode.md` for the full aspect checklist
4. Skills layer dispatches to `docs` agent via Task tool with checklist embedded in prompt
5. Agent layer (docs.md) creates TodoWrite plan, executes documentation tasks
6. Agent completes work, returns summary
