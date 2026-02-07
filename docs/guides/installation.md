# Installation

## Quick Start

```bash
# Clone to any location
git clone https://github.com/yourusername/claude-code-setup
cd claude-code-setup

# Sync to ~/.claude
make update-all       # Add missing + update changed files
make status           # Check sync status
```

## Verify Installation

After installation, your `~/.claude` directory should contain:

```
~/.claude/
├── agents/           # Agent definitions
├── hooks/            # Hook scripts
├── skills/           # Skill commands
├── settings.json     # Configuration
└── CLAUDE.md         # Global AI conventions
```

## Basic Usage

Once installed, you can use skills in Claude Code:

```
/docs                    # Document recent changes
/tester                  # Test recent changes
/pr-check                # Review current PR
/security-review         # Security review
/changelog               # Update changelog
```

See [Skills Reference](../reference/skills.md) for full command documentation.

## Updating

To update to the latest version:

```bash
cd claude-code-setup
git pull
make update-all
```

## Backup Before Changes

```bash
make backup    # Creates timestamped backup of ~/.claude
```

## Troubleshooting

Check sync status with color-coded indicators:

```bash
make status
```

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)

See [Makefile Commands](../reference/makefile.md) for all available commands.
