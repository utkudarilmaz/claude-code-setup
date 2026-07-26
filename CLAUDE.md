# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains Claude Code configuration files (`.claude/`) designed to extend Claude Code functionality with custom agents, skills, hooks, and plugin configurations. The `.claude/` directory is intended to be used as `~/.claude` (symlinked or copied).

## Repository Structure

```
claude-code-setup/              # This repository (shareable)
├── .claude/                    # Claude Code config (becomes ~/.claude)
│   ├── agents/                 # Agent definitions
│   ├── hooks/                  # Hook scripts (PreToolUse, Notification)
│   ├── skills/                 # Skill commands
│   ├── settings.json           # Configuration
│   └── CLAUDE.md               # Global AI conventions (applied to all projects)
├── docs/                       # Detailed documentation
├── tests/                      # Tests for hook scripts and Makefile
├── Makefile                    # Sync management between repo and ~/.claude
├── CLAUDE.md                   # This file (repo-specific guidance)
├── LICENSE                     # MIT license
└── README.md                   # Project documentation
```

## Two CLAUDE.md Files

| File | Purpose | Scope |
|------|---------|-------|
| `CLAUDE.md` (root) | Repository documentation for contributors | This repo only |
| `.claude/CLAUDE.md` | Global conventions for Claude Code | All projects when used as ~/.claude |

## Architecture

**Two-tier extension model**: Skills (`.claude/skills/*/SKILL.md`) are the user-facing invocation layer (slash commands) and dispatch to agents (`.claude/agents/*.md`), which hold the specialized knowledge, workflows, and rules. Detailed mode content lives in `references/` subdirectories within each skill so SKILL.md stays a lean dispatch layer (progressive disclosure).

**Hooks**: scripts in `.claude/hooks/`, wired up in `.claude/settings.json`. PreToolUse hooks receive the tool call as JSON on stdin and must exit with code 2 to block it. Hook scripts must be cross-platform (macOS and Linux).

The full extension inventory and command list live in [README.md](README.md), [docs/reference/agents.md](docs/reference/agents.md), and [docs/reference/skills.md](docs/reference/skills.md). The architecture details live in [docs/architecture/extension-model.md](docs/architecture/extension-model.md).

## Conventions

See `.claude/CLAUDE.md` for global conventions that apply when this config is used.

Key conventions for this repository:
- **Conventional commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `perf:`, `test:`, `chore:`
- **Tags without v-prefix**: Use `1.0.0`, not `v1.0.0`
- **No AI attribution**: Never add Co-Authored-By Claude or AI references
- **JSON fields**: Always use camelCase
- **Agent/Skill files**: YAML frontmatter with `name`, `description`, optional `model`, `color`
- **Never split agent/skill files**: Keep `.claude/agents/*.md` and `.claude/skills/*/SKILL.md` as single files - they are loaded as complete context for AI, not user documentation. Detailed reference content belongs in `.claude/skills/*/references/` files, not in the main SKILL.md

Skills support four invocation modes: default (`/command` for recent changes), scoped (`/command <scope>`), comprehensive (`/command all`), and skill-specific special modes. Agent descriptions use concise third-person trigger phrases rather than verbose conversation examples.

To add a new agent, skill, or hook, follow [docs/guides/contributing.md](docs/guides/contributing.md).

## Testing

Run `make test` to execute every `tests/*.test.sh` suite. Hook scripts and Makefile sync behavior are covered; add tests when changing either.

## Makefile Sync Management

The Makefile syncs `.claude/` into `~/.claude` (or any `TARGET_DIR`):

- `make update-all` - Add missing and update changed files, keep extras; `settings.json` is merged with `jq` so machine-local keys survive (repo values win on conflicts)
- `make status` / `make diff` - Inspect sync state; in `make diff`, green lines are what update would add, red lines what it would remove
- `make backup` - Timestamped backup of the target before changes
- `make update-all TARGET_DIR=$HOME/.claude-personal` - Sync a second Claude home from the same repo

See [docs/reference/makefile.md](docs/reference/makefile.md) for the complete command reference.
