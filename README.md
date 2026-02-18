# Claude Code Configuration

Personal Claude Code configuration repository containing custom agents, skills, hooks, and plugin settings for extending Claude Code functionality.

## Overview

This repository provides a modular extension framework for Claude Code with:

- **Agents** - Specialized AI assistants for documentation, testing, security review, code quality, changelog generation, and infrastructure
- **Skills** - User-facing slash commands (`/docs`, `/tester`, `/security-review`, `/simplifier`, `/devops`, `/changelog`, `/pr-check`) with multiple invocation modes
- **Hooks** - Tool call interception for automation (context compaction suggestions, sensitive file protection, notifications)
- **Plugin Management** - Centralized plugin enable/disable configuration

## Quick Start

```bash
# Clone and sync
git clone https://github.com/yourusername/claude-code-setup
cd claude-code-setup
make update-all
```

See [Installation Guide](docs/guides/installation.md) for detailed setup instructions.

## Skill Commands

| Skill | Command | Description |
|-------|---------|-------------|
| docs | `/docs` | Document recent changes |
| docs | `/docs <scope>` | Document specific area |
| docs | `/docs all` | Full documentation audit |
| docs | `/docs simplifier` | Restructure large docs |
| tester | `/tester` | Test recent changes |
| tester | `/tester <scope>` | Test specific area |
| tester | `/tester all` | Full test audit (50% coverage minimum) |
| pr-check | `/pr-check` | Review PR quality |
| security-review | `/security-review` | Security review |
| security-review | `/security-review all` | Full security audit |
| simplifier | `/simplifier` | Cleanup code quality |
| simplifier | `/simplifier <scope>` | Cleanup specific area |
| simplifier | `/simplifier all` | Full code quality audit |
| changelog | `/changelog` | Update CHANGELOG.md |
| changelog | `/changelog release` | Generate release notes |
| devops | `/devops` | Review infrastructure changes |
| devops | `/devops <context>` | Review/design IaC |
| devops | `/devops all` | Full infrastructure audit |

See [Skills Reference](docs/reference/skills.md) for complete documentation.

## Repository Structure

```
claude-code-setup/
├── .claude/                    # Claude Code config (becomes ~/.claude)
│   ├── agents/                 # Agent definitions
│   ├── hooks/                  # Hook scripts (PreToolUse, PostToolUse, etc.)
│   ├── skills/                 # Skill commands
│   ├── settings.json           # Hooks, plugins, statusLine
│   └── CLAUDE.md               # Global conventions
├── docs/                       # Documentation
│   ├── architecture/           # Extension model, diagrams
│   ├── guides/                 # Installation, configuration, contributing
│   └── reference/              # Agents, skills, makefile commands
├── CLAUDE.md                   # Repo guidance for contributors
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
| [Agents Reference](docs/reference/agents.md) | All 8 agents |
| [Skills Reference](docs/reference/skills.md) | All 7 skills with modes |
| [Makefile Commands](docs/reference/makefile.md) | Sync utilities |

## License

MIT
