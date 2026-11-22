# Extension Architecture

Agents, skills and hooks ship as the `core` plugin in `plugins/core/`. The
marketplace in `.claude-plugin/marketplace.json` lists it.

## Two-Tier Extension Model

```
┌─────────────────────────────────────────────────────┐
│                    User Input                       │
│              /docs all  or  /core:docs all          │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│          Skills Layer (skills/*/SKILL.md)           │
│  • Parses command arguments                         │
│  • Determines invocation mode                       │
│  • Dispatches core:<agent> via the Task tool        │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│             Agents Layer (agents/*.md)              │
│  • Contains domain expertise                        │
│  • Defines workflows and rules                      │
│  • Executes actual work                             │
└─────────────────────────────────────────────────────┘
```

**Skills** provide the `/command` interface and dispatch logic. SKILL.md stays
a lean dispatch layer. Detailed mode content (checklists, patterns, execution
flows) lives in the skill's `references/` folder.
**Agents** contain the specialized knowledge and execution workflows.

## Names

| Kind | Loads as | Example |
|------|----------|---------|
| Agent | `core:<name>` | `subagent_type="core:docs"` |
| Skill | `/<name>`, or `/core:<name>` | `/docs`, `/core:docs` |

The bare skill name works unless another command has the same name.
`/core:<name>` always works. A skill must never take the name of a built-in
command. That is why the security skill is `/security-audit`, not
`/security-review`. `tests/plugin-manifest.test.sh` keeps the list of built-in
names.

One skill calls another with the Skill tool and the `core:` name, as
`/release-tag` does with `core:changelog`.

## Path Resolution

Plugin files are installed into a cache folder, so no path may point at
`~/.claude`. Two variables give the real location:

| Variable | Points at | Used in |
|----------|-----------|---------|
| `${CLAUDE_SKILL_DIR}` | The running skill's folder | SKILL.md, for its own `references/` |
| `${CLAUDE_PLUGIN_ROOT}` | `plugins/core/` as installed | SKILL.md for another skill's files, agents, `hooks.json` |

Claude Code replaces both in a skill when it loads it, so the prompt a skill
passes to an agent already holds the full path. For example:

```
Consult ${CLAUDE_SKILL_DIR}/references/comprehensive-mode.md
Consult ${CLAUDE_PLUGIN_ROOT}/skills/code-slop-cleaner/references/change-patterns.md
```

## Hook System

Hooks are wired in `plugins/core/hooks/hooks.json`, not in `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/sensitive-file-protection.sh\""}]
    }]
  }
}
```

Quote the command, because the plugin path can hold spaces. PreToolUse hooks
get the tool call as JSON on stdin and exit with code 2 to block it. Scripts
must be executable and run on macOS and Linux.

### Current Hooks

| Hook | Event and matcher | Purpose | Platform Support |
|------|-------------------|---------|------------------|
| `sensitive-file-protection` | PreToolUse, `Edit\|Write` | Blocks writes to protected files (.env, credentials, secrets, lock files; .env.example is allowed) via exit code 2 | All |
| `dirty-merge-protection` | PreToolUse, `Bash` | Blocks `git merge` and `gh pr merge` while the repo has uncommitted changes (merge `--abort`, `--continue`, and `--quit` are allowed) via exit code 2 | All |
| `notification` | Notification, any | Plays a sound when Claude Code sends a notification | macOS (afplay), Linux (paplay/aplay) |

The notification hook tries each player in turn and stays silent when none
works:

- macOS: `afplay /System/Library/Sounds/Glass.aiff`
- Linux (PulseAudio): `paplay /usr/share/sounds/freedesktop/stereo/complete.oga`
- Linux (ALSA): `aplay /usr/share/sounds/alsa/Front_Center.wav`

[Configuration](../guides/configuration.md#current-hooks) has the details of
each hook.

## Directory Structure

```
.claude-plugin/
└── marketplace.json            # Marketplace "claude-code-setup", lists core
plugins/core/
├── .claude-plugin/plugin.json  # Plugin manifest, no version
├── agents/<name>.md            # 12 agents, loaded as core:<name>
├── skills/<name>/              # 12 skills
│   ├── SKILL.md
│   └── references/             # Mode checklists and patterns (not in changelog or release-tag)
├── hooks/
│   ├── hooks.json              # Hook wiring
│   └── *.sh                    # 3 hook scripts
└── README.md
config/
├── settings.json               # Base settings, synced by make update-config
└── CLAUDE.md                   # Global conventions, synced by make update-config
```

A plugin cannot ship `settings.json` or `CLAUDE.md`, so those two live in
`config/`. The status line in `config/settings.json` is described in
[Configuration](../guides/configuration.md#statusline-configuration).

## Flow Example

1. User invokes `/docs all`
2. The skill (`skills/docs/SKILL.md`) parses the arguments and picks comprehensive mode
3. The skill dispatches `core:docs` via the Task tool. The prompt points at
   `${CLAUDE_SKILL_DIR}/references/comprehensive-mode.md`, already resolved
   to the full path
4. The agent (`agents/docs.md`) reads that checklist, creates a TodoWrite plan, and runs the documentation tasks
5. The agent completes the work and returns a summary
