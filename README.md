# Claude Code Configuration

Personal Claude Code configuration: custom agents, skills, hooks, MCP servers, and plugin settings.

## Overview

- **Skills** - slash commands such as `/docs` and `/tester`, each with several invocation modes. See [Skills Reference](docs/reference/skills.md) for every command and mode.
- **Agents** - the specialized assistants the skills dispatch to. See [Agents Reference](docs/reference/agents.md).
- **Hooks** - tool call interception for sensitive file protection and cross-platform notifications.
- **Plugin Management** - centralized plugin enable/disable configuration.
- **MCP Servers** - declared in `.claude/mcp-servers.json` and merged into `.claude.json` on sync. See [MCP Servers](docs/reference/mcp-servers.md).
- **Cross-Platform Support** - works on macOS and Linux with dynamic path resolution.

## Quick Start

```bash
# Clone and sync
git clone https://github.com/utkudarilmaz/claude-code-setup
cd claude-code-setup
make update-all
```

Keep more than one Claude home directory (for example a work and a personal
profile)? Override `TARGET_DIR` to sync the same repo into either one:

```bash
make update-all TARGET_DIR=$HOME/.claude-personal
```

**Platform Support:** macOS and Linux with automatic Node.js path detection and cross-platform audio notifications.

See [Installation Guide](docs/guides/installation.md) for detailed setup instructions and requirements.
`make update-all` is one of several sync targets; see [Makefile Commands](docs/reference/makefile.md) for the rest.

## Repository Structure

```
claude-code-setup/
├── .claude/                    # Claude Code config (becomes ~/.claude)
│   ├── agents/                 # Agent definitions
│   ├── hooks/                  # Hook scripts (PreToolUse, PostToolUse, etc.)
│   ├── skills/                 # Skill commands
│   ├── settings.json           # Hooks, plugins, statusLine
│   ├── mcp-servers.json        # Shared MCP server definitions
│   └── CLAUDE.md               # Global conventions
├── docs/                       # Documentation
│   ├── architecture/           # Extension model, diagrams
│   ├── guides/                 # Installation, configuration, contributing
│   └── reference/              # Agents, skills, MCP servers, makefile
├── tests/                      # Tests for hook scripts and Makefile
├── CLAUDE.md                   # Repo guidance for contributors
├── LICENSE                     # MIT license
├── Makefile                    # Sync management
└── README.md                   # This file
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Installation](docs/guides/installation.md) | Setup and verification |
| [Configuration](docs/guides/configuration.md) | settings.json, plugins, hooks |
| [Contributing](docs/guides/contributing.md) | Adding agents, skills, hooks |
| [Extension Model](docs/architecture/extension-model.md) | Two-tier architecture |
| [Agents Reference](docs/reference/agents.md) | Every agent and what it does |
| [Skills Reference](docs/reference/skills.md) | Every slash command and its modes |
| [MCP Servers](docs/reference/mcp-servers.md) | Shipped servers and the environment each needs |
| [Makefile Commands](docs/reference/makefile.md) | Sync utilities |

## License

MIT
