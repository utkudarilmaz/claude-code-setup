# Claude Code Configuration

Personal Claude Code configuration repository containing custom agents, skills, hooks, and plugin settings for extending Claude Code functionality.

## Overview

This repository provides a modular extension framework for Claude Code with:

- **Agents** - Specialized AI assistants for documentation, testing, and changelog generation
- **Skills** - User-facing slash commands (`/docs`, `/tester`) with multiple invocation modes
- **Hooks** - Tool call interception for automation (strategic context compaction)
- **Plugin Management** - Centralized plugin enable/disable configuration

## Quick Start

### Option 1: Symlink (recommended)

```bash
git clone https://github.com/yourusername/claude-code-setup ~/claude-code-setup
ln -s ~/claude-code-setup/.claude ~/.claude
```

### Option 2: Direct clone

```bash
git clone https://github.com/yourusername/claude-code-setup
cp -r claude-code-setup/.claude ~/.claude
```

### Option 3: Makefile update (selective)

```bash
git clone https://github.com/yourusername/claude-code-setup ~/claude-code-setup
cd ~/claude-code-setup
make update-all       # Add missing + update changed files
make status           # Check sync status
```

### Verify installation

```
~/.claude/
├── agents/           # Agent definitions
├── skills/           # Skill commands
├── settings.json     # Configuration
└── CLAUDE.md         # Global AI conventions
```

### Use skills

```
/docs          # Update documentation for recent changes
/docs all      # Full documentation audit
/tester        # Verify test coverage for recent changes
/tester all    # Full test audit
```

## Makefile Commands

The Makefile provides granular control over syncing between this repo and `~/.claude`.

### Update Commands (non-destructive)

Add missing files and update changed files, keep extras:

```bash
make update-all       # Update agents, skills, and config
make update-agents    # Update .claude/agents/ only
make update-skills    # Update .claude/skills/ only
make update-config    # Update settings.json and CLAUDE.md
```

### Remove Commands

Remove repo-managed files from `~/.claude`:

```bash
make rm-agents    # Remove matching agents
make rm-skills    # Remove matching skills
```

### Utility Commands

```bash
make status    # Show sync status with colored indicators
make diff      # Show file differences
make backup    # Create timestamped backup of ~/.claude
make help      # Display all commands
```

### Options

| Option | Description |
|--------|-------------|
| `DRY_RUN=1` | Preview changes without executing |
| `FORCE=1` | Skip confirmation prompts |

Examples:
```bash
make update-all               # Add missing + update changed
make DRY_RUN=1 rm-agents      # Preview agent removal
make status                   # Check what needs updating
```

### Status Legend

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)

## Repository Structure

```
claude-code-setup/              # This repository
├── .claude/                    # Claude Code config (becomes ~/.claude)
│   ├── agents/
│   │   ├── docs.md             # Documentation agent
│   │   ├── tester.md           # Test coverage agent
│   │   └── changelog-generator.md
│   ├── skills/
│   │   ├── docs/SKILL.md       # /docs command
│   │   ├── tester/SKILL.md     # /tester command
│   │   └── strategic-compact/
│   │       └── suggest-compact.sh
│   ├── settings.json           # Hooks, plugins, statusLine
│   └── CLAUDE.md               # Global conventions
├── CLAUDE.md                   # Repo guidance for contributors
└── README.md                   # This file
```

## Architecture

### Two-Tier Extension Model

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

### Hook System

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

Current hooks:
- `suggest-compact.sh` - Suggests `/compact` at logical intervals (every 50 tool calls)

## Configuration

### settings.json Structure

```json
{
  "hooks": {
    "PreToolUse": [...]     // Tool call interception
  },
  "statusLine": {...},       // Status bar configuration
  "enabledPlugins": {...}    // Plugin enable/disable map
}
```

### Plugin Management

Plugins are toggled via `enabledPlugins` map:

```json
{
  "enabledPlugins": {
    "plugin-name@source": true,   // enabled
    "other-plugin@source": false  // disabled
  }
}
```

**Currently Enabled:**
- `claude-hud` - Status line UI
- `commit-commands` - Git commit helpers
- `explanatory-output-style` - Output formatting
- `context7` - Documentation queries
- `superpowers` - Advanced skill framework

## Agents

### docs

Documentation architect that manages README.md, CLAUDE.md, API docs, and postman collections.

**Trigger:** After code changes affecting documentation

**Responsibilities:**
- Analyze code changes and identify affected docs
- Update documentation files for accuracy
- Maintain consistent formatting and style
- Use camelCase for JSON field names

### tester

Test specialist ensuring comprehensive coverage.

**Trigger:** After implementing features, fixing bugs, or refactoring

**Responsibilities:**
- Write new tests (happy path, edge cases, errors)
- Update existing tests when code changes
- Run test suites and report results
- Follow Arrange-Act-Assert pattern

**Go Testing Commands:**
```bash
go test -v ./path/to/package/...           # Run tests
go test -v ./package -run TestName         # Single test
go test -coverprofile=coverage.out ./...   # Coverage
```

### changelog-generator

Generates CHANGELOG.md from git history using Keep a Changelog format.

**Trigger:** When explicitly requested

**Commit Type Mapping:**
| Prefix | Changelog Section |
|--------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:`, `perf:` | Changed |
| `BREAKING CHANGE:` | Breaking Changes |
| `deprecate:` | Deprecated |
| `remove:` | Removed |
| `security:` | Security |

## Skills

### /docs

Synchronize documentation with code changes.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/docs` | Document recent changes |
| Scoped | `/docs <scope>` | Document specific area |
| Full Audit | `/docs all` | Complete repository documentation |

**Scope Examples:**
- `/docs src/auth` - Authentication module
- `/docs API` - API endpoints only
- `/docs README` - README.md only

### /tester

Verify and create test coverage.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/tester` | Test recent changes |
| Scoped | `/tester <scope>` | Test specific area |
| Full Audit | `/tester all` | Complete test coverage audit |

**Scope Examples:**
- `/tester src/services/payment` - Payment service
- `/tester utils/parser.ts` - Specific file
- `/tester API endpoints` - All API routes

### strategic-compact

Hook that suggests context compaction at logical intervals.

**Why Manual Compaction:**
- Auto-compact happens at arbitrary points, often mid-task
- Strategic compacting preserves context through logical phases
- Compact after exploration, before execution

**Trigger Points:**
- After 50 tool calls (configurable via `COMPACT_THRESHOLD`)
- Every 25 calls thereafter

## Global Conventions

The `.claude/CLAUDE.md` file contains conventions applied to all projects when this config is used:

- No AI attribution in commits
- Conventional commits format
- Tags without `v` prefix
- camelCase for JSON field names
- Check available skills/agents when planning tasks

## Adding Extensions

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

## Contributing

1. Follow existing patterns for agents/skills
2. Use conventional commits
3. Update CLAUDE.md when adding new extensions
4. Test skills before committing

## License

MIT
