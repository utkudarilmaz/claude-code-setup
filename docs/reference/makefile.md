# Makefile Commands

The Makefile provides granular control over syncing between this repo and `~/.claude`.

## Update Commands (non-destructive)

Add missing files and update changed files, keep extras:

```bash
make update-all       # Update agents, skills, hooks, and config
make update-agents    # Update .claude/agents/ only
make update-skills    # Update .claude/skills/ only
make update-hooks     # Update .claude/hooks/ only
make update-config    # Update settings.json (merged) and CLAUDE.md
```

### settings.json Merge

`update-config` does not overwrite the target `settings.json`. When `jq` is
available, it deep-merges the repo file into the target file:

- Keys that exist only in the target (machine-local state) are kept
- Keys present in the repo win on conflicts
- Keys deleted from the repo file are NOT removed from the target; delete
  them manually if needed

Without `jq`, the old copy behavior is used and a warning is printed because
local-only keys are lost. `CLAUDE.md` is always a plain copy.

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
make test      # Run all tests/*.test.sh suites
make help      # Display all commands
```

## Options

| Option | Description |
|--------|-------------|
| `DRY_RUN=1` | Preview changes without executing |
| `FORCE=1` | Skip confirmation prompts |
| `TARGET_DIR=<path>` | Sync to a directory other than `~/.claude` |
| `NO_RSYNC=1` | Force the plain-copy fallback path even when rsync exists |

Examples:
```bash
make update-all               # Add missing + update changed
make DRY_RUN=1 rm-agents      # Preview agent removal
make status                   # Check what needs updating
make update-all TARGET_DIR=$HOME/.claude-personal   # Sync a second Claude home
```

`TARGET_DIR` defaults to `~/.claude` but can be overridden on the command
line. This is useful if you keep more than one Claude home directory (for
example a work profile and a personal profile) and want to sync the same
repo into both.

## Diff Output (`make diff`)

`make diff` compares `TARGET_DIR` against `REPO_DIR` in that order, so the
colors match what `make update` would do to the target:

- **Green** lines are lines `make update` would add to the target
- **Red** lines are lines `make update` would remove from the target

A legend line is printed at the top of the output as a reminder. The
Makefile detects once, via the `DIFF_COLOR` variable, whether the local
`diff` supports `--color=always`, and reuses that result for every file
comparison instead of retrying colored diff on each call, which used to
print the same diff twice when color wasn't supported.

## Implementation Notes

The update, remove, status, and diff logic for agents, skills, and hooks is
shared through parameterized `define` blocks in the Makefile (`sync_dir`,
`rm_dir`, `status_dir`, `diff_dir`), so all three directories behave the
same way. `make test` runs `tests/makefile-sync.test.sh`, which exercises
the sync commands against a temporary `TARGET_DIR`, including the
`NO_RSYNC=1` fallback path and the settings.json merge.

## Status Legend

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)
