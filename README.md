# Claude Code Configuration

Personal Claude Code configuration: custom agents, skills, hooks, MCP servers, and plugin settings.

## Overview

- **Agents** - Specialized AI assistants for documentation, testing, security review, code quality, changelog generation, infrastructure, SEO/GEO/AIO optimization, plain-English explanation, pull request creation, slop cleanup in text and changes, review analysis, and PR code comment cleanup
- **Skills** - User-facing slash commands (`/docs`, `/tester`, `/security-review`, `/simplifier`, `/devops`, `/changelog`, `/release-tag`, `/seo`, `/create-pr`, `/text-slop-cleaner`, `/code-slop-cleaner`, `/explain`, `/review-analyzer`, `/pr-comment-cleaner`) with multiple invocation modes
- **Hooks** - Tool call interception for automation (sensitive file protection, cross-platform notifications)
- **Plugin Management** - Centralized plugin enable/disable configuration
- **MCP Servers** - build123d and terraform servers in `.claude/mcp-servers.json`, merged into `.claude.json` on sync
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
| create-pr | `/create-pr` | Commit, push, and open the PR for this branch |
| create-pr | `/create-pr draft` | Same, opened as a draft PR |
| create-pr | `/create-pr show` | Print the title and body, change nothing |
| create-pr | `/create-pr refresh` | Update the existing PR, keep hand-written notes |
| create-pr | `/create-pr <number>` | Update the title and body of a specific PR |
| text-slop-cleaner | `/text-slop-cleaner` | Clean the uncommitted changes, branch commits, or open PR, whichever comes first |
| text-slop-cleaner | `/text-slop-cleaner <path>` | Clean a file or directory |
| text-slop-cleaner | `/text-slop-cleaner <number>` | Clean a PR body and your own comments |
| text-slop-cleaner | `/text-slop-cleaner all` | Clean every markdown file |
| text-slop-cleaner | `/text-slop-cleaner check` | Report what would change, change nothing |
| code-slop-cleaner | `/code-slop-cleaner` | Check whatever is in flight against its ticket or purpose, both directions |
| code-slop-cleaner | `/code-slop-cleaner <path>` | Check the changes under a path |
| code-slop-cleaner | `/code-slop-cleaner <ticket-url>` | Check the current changes against an explicit ticket |
| code-slop-cleaner | `/code-slop-cleaner branch` | Check the whole branch against the default branch |
| code-slop-cleaner | `/code-slop-cleaner apply` | Remove what is unnecessary, then run the tests |
| explain | `/explain` | Explain the current changes, or the last commit |
| explain | `/explain <target>` | Explain a file, PR, symbol, or concept |
| explain | `/explain <target> deep` | Full walkthrough with anchors and a worked example |
| review-analyzer | `/review-analyzer` | Check a pasted code review against the actual code |
| review-analyzer | `/review-analyzer <file>` | Check a review stored in a file |
| pr-comment-cleaner | `/pr-comment-cleaner` | Clean comments in the current branch's PR |
| pr-comment-cleaner | `/pr-comment-cleaner <number>` | Check out a PR and clean its comments |
| pr-comment-cleaner | `/pr-comment-cleaner <path>` | Clean only the PR's changed files under a path |
| pr-comment-cleaner | `/pr-comment-cleaner check` | Report what would change, change nothing |

See [Skills Reference](docs/reference/skills.md) for complete documentation.

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
| [Agents Reference](docs/reference/agents.md) | All 14 agents |
| [Skills Reference](docs/reference/skills.md) | All 14 skills with modes |
| [MCP Servers](docs/reference/mcp-servers.md) | Shipped servers and the environment each needs |
| [Makefile Commands](docs/reference/makefile.md) | Sync utilities |

## License

MIT
