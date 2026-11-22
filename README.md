# Claude Code Setup

One Claude Code setup for every machine you use. Agents, skills and hooks ship
as the `core` plugin from a marketplace in this repo, so each machine updates
them by itself. A shared base `settings.json` and `CLAUDE.md` are merged into
each Claude home, and each machine keeps its own keys, secrets and overrides.

## What You Get

- **Skills** - slash commands such as `/docs`, `/tester`, `/simplifier` and
  `/create-pr`, each with several modes. See [Skills Reference](docs/reference/skills.md).
- **Agents** - the specialists the skills dispatch to, named `core:<agent>`.
  See [Agents Reference](docs/reference/agents.md).
- **Hooks** - block edits to secret files, block merges with uncommitted
  changes, and play a sound on notifications.
- **Base settings** - plugins, marketplaces, status line and skill toggles,
  merged into each home without touching its own keys.

MCP servers and the programs some plugins need are not installed by the repo.
See [External Tools](docs/guides/external-tools.md) and
[MCP Servers](docs/reference/mcp-servers.md).

## Quick Start

Only the plugin, without the shared settings:

```
/plugin install core --marketplace utkudarilmaz/claude-code-setup
```

The full setup on a new machine:

```bash
git clone https://github.com/utkudarilmaz/claude-code-setup
cd claude-code-setup
make update-config
```

Start Claude Code. The base settings declare this marketplace and enable
`core`, so Claude Code installs the plugin in the background. Run
`/reload-plugins` or start a new session if the skills are not there yet.

A second Claude home, such as a personal profile:

```bash
make update-config TARGET_DIR=$HOME/.claude-personal
```

## Keeping Machines in Sync

| You changed | What reaches the other machines |
|-------------|---------------------------------|
| An agent, skill or hook | Every machine, at its next session start, after the change is on `main` |
| `config/settings.json` or `config/CLAUDE.md` | Each machine after `git pull` and `make update-config` |
| A setting for one machine only | Nothing. Put it in that home's `settings.overrides.json` |

See [Installation](docs/guides/installation.md) for moving a machine from the
old file sync, and [Makefile Commands](docs/reference/makefile.md) for how the
settings merge works.

## Repository Structure

```
claude-code-setup/
├── .claude-plugin/
│   └── marketplace.json        # Marketplace "claude-code-setup"
├── plugins/core/               # The core plugin
│   ├── .claude-plugin/plugin.json
│   ├── agents/                 # Agent definitions
│   ├── skills/                 # Skills, each with a references/ folder
│   └── hooks/                  # hooks.json and the hook scripts
├── config/
│   ├── settings.json           # Base settings merged into each home
│   └── CLAUDE.md               # Global conventions copied into each home
├── scripts/                    # Settings merge and migrate scripts used by the Makefile
├── tests/                      # Tests for hooks, scripts, Makefile and plugin layout
├── docs/                       # Guides and references
├── .claude/                    # Project settings for working on this repo only
├── Makefile                    # Syncs config/ into a Claude home
└── CLAUDE.md                   # Guidance for contributors
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Installation](docs/guides/installation.md) | New machines, updates, and moving from the old sync |
| [Configuration](docs/guides/configuration.md) | settings.json, plugins, hooks |
| [External Tools](docs/guides/external-tools.md) | Programs the plugins and skills need, set up by hand |
| [Contributing](docs/guides/contributing.md) | Adding agents, skills, hooks |
| [Extension Model](docs/architecture/extension-model.md) | How skills, agents and hooks fit together |
| [Agents Reference](docs/reference/agents.md) | Every agent and what it does |
| [Skills Reference](docs/reference/skills.md) | Every slash command and its modes |
| [MCP Servers](docs/reference/mcp-servers.md) | Servers to add by hand and the environment each needs |
| [Makefile Commands](docs/reference/makefile.md) | Settings sync and migrate |

## License

MIT
