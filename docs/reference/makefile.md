# Makefile Commands

The Makefile provides granular control over syncing between this repo and `~/.claude`.

## Update Commands (non-destructive)

Add missing files and update changed files, keep extras:

```bash
make update-all       # Update agents, skills, hooks, and config
make update-agents    # Update .claude/agents/ only
make update-skills    # Update .claude/skills/ only
make update-hooks     # Update .claude/hooks/ only
make update-config    # Update settings.json and CLAUDE.md
```

## Install Commands

Install external tools and skills from a registry of named targets:

```bash
make install                    # Install all registered targets
make install all                # Install all registered targets
make install <target>           # Install a specific target
```

Registered targets:

| Target | Action |
|--------|--------|
| `google-maps-scraper` | `npx skills add gosom/google-maps-scraper` |

To add a new target, append its name to `INSTALL_TARGETS` in the Makefile and
add a matching `install-<name>` recipe in the INSTALL COMMANDS section.

## Remove Commands

Remove repo-managed files from `~/.claude`:

```bash
make rm-agents    # Remove matching agents
make rm-skills    # Remove matching skills
make rm-hooks     # Remove matching hooks
```

## Utility Commands

```bash
make status    # Show sync status with colored indicators
make diff      # Show file differences
make backup    # Create timestamped backup of ~/.claude
make help      # Display all commands
```

## Options

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

## Status Legend

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)
