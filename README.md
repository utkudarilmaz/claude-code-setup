# Claude Code Configuration

Personal Claude Code configuration repository containing custom agents, skills, hooks, and plugin settings for extending Claude Code functionality.

## Overview

This repository provides a modular extension framework for Claude Code with:

- **Agents** - Specialized AI assistants for documentation, testing, security review, code quality, changelog generation, infrastructure, SEO/GEO/AIO optimization, plain-English explanation, and slop cleanup in text and changes
- **Skills** - User-facing slash commands (`/docs`, `/tester`, `/security-review`, `/simplifier`, `/devops`, `/changelog`, `/release-tag`, `/seo`, `/pr-body`, `/text-slop-cleaner`, `/code-slop-cleaner`, `/explain`) with multiple invocation modes
- **Hooks** - Tool call interception for automation (sensitive file protection, cross-platform notifications)
- **Plugin Management** - Centralized plugin enable/disable configuration
- **MCP Servers** - Shared server definitions in `.claude/mcp-servers.json`, merged into `.claude.json` on sync
- **Cross-Platform Support** - Works on macOS and Linux with dynamic path resolution

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
| release-tag | `/release-tag patch` | Bump patch version and create annotated tag |
| release-tag | `/release-tag minor` | Bump minor version and create annotated tag |
| release-tag | `/release-tag major` | Bump major version and create annotated tag |
| seo | `/seo` | Optimize recent web content changes for SEO/GEO/AIO |
| seo | `/seo <scope>` | Optimize specific page or directory |
| seo | `/seo all` | Full project SEO/GEO/AIO optimization |
| seo | `/seo audit` | Score-only report card (no file edits) |
| pr-body | `/pr-body` | Write and apply this branch's PR description |
| pr-body | `/pr-body <number>` | Rewrite a specific PR description |
| pr-body | `/pr-body draft` | Print a draft description, change nothing |
| pr-body | `/pr-body refresh` | Update the body, keep hand-written notes |
| text-slop-cleaner | `/text-slop-cleaner` | Clean prose and comments in the uncommitted changes |
| text-slop-cleaner | `/text-slop-cleaner <path>` | Clean a file or directory |
| text-slop-cleaner | `/text-slop-cleaner <number>` | Clean a PR body and your own comments |
| text-slop-cleaner | `/text-slop-cleaner all` | Clean every markdown file |
| text-slop-cleaner | `/text-slop-cleaner check` | Report what would change, change nothing |
| code-slop-cleaner | `/code-slop-cleaner` | Check whether the uncommitted changes were necessary |
| code-slop-cleaner | `/code-slop-cleaner <path>` | Check the changes under a path |
| code-slop-cleaner | `/code-slop-cleaner branch` | Check the whole branch against the default branch |
| code-slop-cleaner | `/code-slop-cleaner apply` | Remove what is unnecessary, then run the tests |
| explain | `/explain` | Explain the current changes, or the last commit |
| explain | `/explain <target>` | Explain a file, PR, symbol, or concept |
| explain | `/explain <target> deep` | Full walkthrough with anchors and a worked example |

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
| [Agents Reference](docs/reference/agents.md) | All 12 agents |
| [Skills Reference](docs/reference/skills.md) | All 12 skills with modes |
| [Makefile Commands](docs/reference/makefile.md) | Sync utilities |

## License

MIT
