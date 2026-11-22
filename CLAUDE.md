# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository is a Claude Code plugin marketplace plus a shared base configuration. Agents, skills and hooks ship as the `core` plugin, which every machine installs and updates through the marketplace. `config/settings.json` and `config/CLAUDE.md` are synced into each Claude home with the Makefile, which merges them with that home's own keys and overrides.

## Repository Structure

```
claude-code-setup/
├── .claude-plugin/marketplace.json  # Marketplace "claude-code-setup", lists the core plugin
├── plugins/core/                    # The core plugin
│   ├── .claude-plugin/plugin.json   # Plugin manifest, no pinned version
│   ├── agents/                      # Agent definitions, loaded as core:<name>
│   ├── skills/                      # Skills, each with SKILL.md and references/
│   ├── hooks/                       # hooks.json and the hook scripts
│   └── README.md
├── config/
│   ├── settings.json                # Base settings merged into each home
│   └── CLAUDE.md                    # Global conventions copied into each home
├── scripts/                         # apply-settings.sh, settings-merge.jq, migrate.sh
├── tests/                           # Tests for hooks, scripts, Makefile and plugin layout
├── docs/                            # Guides and references
├── .claude/settings.local.json      # Project settings for working on this repo only
├── .github/workflows/test.yml       # Runs make test on Linux and macOS
├── Makefile                         # Syncs config/ into a Claude home
└── README.md
```

## Two CLAUDE.md Files

| File | Purpose | Scope |
|------|---------|-------|
| `CLAUDE.md` (root) | Repository documentation for contributors | This repo only |
| `config/CLAUDE.md` | Global conventions for Claude Code | All projects, once copied into a Claude home |

A plugin cannot ship a `CLAUDE.md` or a `settings.json`, which is why these two live in `config/` and are synced by the Makefile.

## Architecture

**Two-tier extension model**: Skills (`plugins/core/skills/*/SKILL.md`) are the user-facing invocation layer (slash commands) and dispatch to agents (`plugins/core/agents/*.md`), which hold the specialized knowledge, workflows, and rules. Detailed mode content lives in `references/` subdirectories within each skill so SKILL.md stays a lean dispatch layer (progressive disclosure).

**Names**: plugin agents load as `core:<agent>`, so every `subagent_type` in a skill must use that form. Skills work as bare `/<name>` unless another command has the name, and always as `/core:<name>`. Never give a skill the name of a built-in command; `tests/plugin-manifest.test.sh` keeps a list.

**Paths**: a prompt that a skill passes to an agent must point at files with `${CLAUDE_SKILL_DIR}/references/...` (the skill's own files) or `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/references/...` (another skill's files). Claude Code replaces both when it loads the skill. Agents use the `${CLAUDE_PLUGIN_ROOT}` form.

**Hooks**: scripts in `plugins/core/hooks/`, wired up in `plugins/core/hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}`. PreToolUse hooks receive the tool call as JSON on stdin and must exit with code 2 to block it. Hook scripts must be executable and cross-platform (macOS and Linux).

The full extension inventory and command list live in [README.md](README.md), [docs/reference/agents.md](docs/reference/agents.md), and [docs/reference/skills.md](docs/reference/skills.md). The architecture details live in [docs/architecture/extension-model.md](docs/architecture/extension-model.md).

## Conventions

See `config/CLAUDE.md` for global conventions that apply when this config is used.

Key conventions for this repository:
- **Conventional commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `perf:`, `test:`, `chore:`
- **No AI attribution**: Never add Co-Authored-By Claude or AI references
- **JSON fields**: Always use camelCase
- **Agent/Skill files**: YAML frontmatter with `name`, `description`, optional `model`, `color`. The `name` matches the file or folder name
- **Never split agent/skill files**: Keep `plugins/core/agents/*.md` and `plugins/core/skills/*/SKILL.md` as single files - they are loaded as complete context for AI, not user documentation. Detailed reference content belongs in `plugins/core/skills/*/references/` files, not in the main SKILL.md
- **No plugin version**: leave `version` out of `plugin.json`, so the commit SHA is the version and every push to `main` reaches users

Skills support four invocation modes: default (`/command` for recent changes), scoped (`/command <scope>`), comprehensive (`/command all`), and skill-specific special modes. Agent descriptions use concise third-person trigger phrases rather than verbose conversation examples.

To add a new agent, skill, or hook, follow [docs/guides/contributing.md](docs/guides/contributing.md).

## Testing

Run `make test` to execute every `tests/*.test.sh` suite. They cover the hook scripts, the settings merge, `make migrate`, the Makefile targets, and the plugin layout (`claude plugin validate` runs when the CLI is installed). Add tests when changing any of them. CI runs the same suite on Linux and macOS.

To try plugin changes in a session before they are on `main`, run `claude --plugin-dir ./plugins/core`.

## Makefile Sync Management

The Makefile syncs `config/` into `~/.claude` (or any `TARGET_DIR`):

- `make update-config` - Run `update-settings` and `update-claude-md`
- `make update-settings` - Build `settings.json` from the home's file, `config/settings.json`, and the home's `settings.overrides.json`; local keys survive and keys dropped from the repo are deleted
- `make update-claude-md` - Copy `config/CLAUDE.md`
- `make migrate` - Back up, then remove agents, skills, hooks and hook entries left by the old file sync
- `make status` / `make diff` - Inspect sync state
- `make backup` - Timestamped backup of the target before changes
- `make update-config TARGET_DIR=$HOME/.claude-personal` - Sync a second Claude home from the same repo

The Makefile installs no programs and never touches `.claude.json`. Set up external tools and MCP servers by hand from [docs/guides/external-tools.md](docs/guides/external-tools.md) and [docs/reference/mcp-servers.md](docs/reference/mcp-servers.md).

See [docs/reference/makefile.md](docs/reference/makefile.md) for the complete command reference.
