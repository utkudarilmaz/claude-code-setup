# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains Claude Code configuration files (`.claude/`) designed to extend Claude Code functionality with custom agents, skills, hooks, and plugin configurations. The `.claude/` directory is intended to be used as `~/.claude` (symlinked or copied).

## Repository Structure

```
claude-code-setup/              # This repository (shareable)
├── .claude/                    # Claude Code config (becomes ~/.claude)
│   ├── agents/                 # Agent definitions
│   ├── skills/                 # Skill commands
│   ├── settings.json           # Configuration
│   └── CLAUDE.md               # Global AI conventions (applied to all projects)
├── Makefile                    # Sync management between repo and ~/.claude
├── CLAUDE.md                   # This file (repo-specific guidance)
└── README.md                   # Project documentation
```

## Two CLAUDE.md Files

| File | Purpose | Scope |
|------|---------|-------|
| `CLAUDE.md` (root) | Repository documentation for contributors | This repo only |
| `.claude/CLAUDE.md` | Global conventions for Claude Code | All projects when used as ~/.claude |

## Architecture

### Two-Tier Extension Model

```
.claude/skills/       → User-facing invocation layer (slash commands)
  └── */SKILL.md      → Defines /command interface and dispatch logic

.claude/agents/       → Business logic layer (agent definitions)
  └── *.md            → Agent persona, workflow, and behavior rules
```

**Skills** provide the `/command` interface and determine how to dispatch to agents. **Agents** contain the specialized knowledge, workflows, and rules for task execution.

### Hook System

Hooks in `.claude/settings.json` intercept tool calls for pre/post processing:
- `PreToolUse` hooks run before specified tools execute
- Configured via `matcher` regex patterns (e.g., `Edit|Write`)

### Current Extensions

| Extension | Type | Purpose |
|-----------|------|---------|
| `/docs` | skill | Documentation synchronization after code changes |
| `/tester` | skill | Test coverage verification and creation |
| `/pr-check` | skill | PR quality review against checklist |
| `/security-review` | skill | Security-focused code review |
| `/changelog` | skill | Changelog and release notes generation |
| `docs` | agent | Documentation architect (README, CLAUDE.md, API docs) |
| `tester` | agent | Test specialist (coverage, AAA pattern, table-driven) |
| `pr-check` | agent | PR quality reviewer (tests, secrets, error handling) |
| `security-reviewer` | agent | Security expert (auth, injection, OWASP Top 10) |
| `release-notes` | agent | Release documentation specialist |
| `changelog-generator` | agent | CHANGELOG.md generation from git history |
| `suggest-compact.sh` | hook | Context compaction suggestions at logical intervals |
| `sensitive-file-protection` | hook | Blocks writes to protected files (.env, credentials) |
| `notification` | hook | Audio notification on idle/permission prompts |

### Quick Command Reference

```
/docs                    # Document recent changes
/docs <scope>            # Document specific module/file
/docs all                # Full documentation audit

/tester                  # Test recent changes
/tester <scope>          # Test specific module/file
/tester all              # Full test coverage audit

/pr-check                # Review current PR against quality checklist
/pr-check <focus>        # Review PR with specific focus (tests, security, docs)

/security-review         # Security review of recent changes
/security-review <path>  # Security review of specific file/module
/security-review all     # Full security audit

/changelog               # Update CHANGELOG.md from git history
/changelog release       # Generate release notes for announcement
/changelog <version>     # Generate notes for specific version
```

## Conventions

See `.claude/CLAUDE.md` for global conventions that apply when this config is used.

Key conventions for this repository:
- **Conventional commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `perf:`, `test:`, `chore:`
- **Tags without v-prefix**: Use `1.0.0`, not `v1.0.0`
- **No AI attribution**: Never add Co-Authored-By Claude or AI references
- **JSON fields**: Always use camelCase
- **Agent/Skill files**: YAML frontmatter with `name`, `description`, optional `model`, `color`

### Skill/Agent Patterns

Skills support three invocation modes:
1. **Default** (`/command`): Process recent changes
2. **Scoped** (`/command <scope>`): Target specific file/module/feature
3. **Comprehensive** (`/command all`): Full project audit with TodoWrite planning

Agent frontmatter structure:
```yaml
---
name: agent-name
description: "When to invoke this agent..."
model: sonnet  # optional: sonnet, opus, haiku
color: blue    # optional: for UI display
---
```

## Adding New Extensions

### New Agent
1. Create `.claude/agents/<name>.md` with YAML frontmatter
2. Define persona, responsibilities, workflow, and output format
3. Agent is automatically available via Task tool with `subagent_type="<name>"`

### New Skill
1. Create `.claude/skills/<name>/SKILL.md` with YAML frontmatter
2. Define invocation modes and dispatch logic
3. Skill is available as `/<name>` command

### New Hook
Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "ToolPattern",
      "hooks": [{"type": "command", "command": "path/to/script"}]
    }]
  }
}
```

## Makefile Sync Management

The Makefile provides commands to synchronize this repository's `.claude/` directory with `~/.claude`:

**Update commands** (non-destructive):
- Add missing files from repo to `~/.claude`
- Update changed files in `~/.claude` with repo versions
- Keep extra files in `~/.claude` that aren't in repo

**Remove commands**:
- Remove files from `~/.claude` that match files in repo
- Useful for uninstalling repo-managed extensions

**Key commands**:
- `make update-all` - Sync all agents, skills, and config files
- `make status` - View sync status with color-coded indicators
- `make diff` - See detailed differences between repo and `~/.claude`
- `make backup` - Create timestamped backup before making changes

See README.md for complete Makefile documentation.
