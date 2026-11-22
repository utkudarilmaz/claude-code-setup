# Makefile Commands

The Makefile provides granular control over syncing between this repo and `~/.claude`.

## Update Commands (non-destructive)

Add missing files and update changed files, keep extras:

```bash
make update-all       # Update agents, skills, hooks, and config
make update-agents    # Update .claude/agents/ only
make update-skills    # Update .claude/skills/ only
make update-hooks     # Update .claude/hooks/ only
make update-config    # Run update-settings and update-claude-md
make update-settings  # Update settings.json only (merged)
make update-claude-md # Update CLAUDE.md only
```

`update-config` is a group target. Each of the two targets under it can be
run alone and touches only its own file.

### settings.json Merge

`update-settings` builds the target `settings.json` from three layers with
`scripts/apply-settings.sh`. Later layers win:

1. The current target `settings.json`, with its machine-local keys
2. The repo base, `.claude/settings.json`
3. The home's own `settings.overrides.json`, if it exists

The rules:

- Keys that only the target has are kept. Secrets in `env` and keys Claude
  Code writes itself stay as they are.
- Repo keys win over the target, and overrides win over the repo.
- A key set to `null` in the overrides file is removed from the result.
- A key that the repo or the overrides file stops setting is deleted from the
  target on the next run. An object left empty by that is deleted too.
- Arrays are replaced whole, never merged item by item.

To know what it set last time, the script saves the key paths of the merged
repo and override layers to `.settings.managed.json` in the target. It saves
no values. Leave that file alone. On the first run it does not exist yet, so
nothing is deleted.

`jq` is required. `DRY_RUN=1` prints a diff of the change and writes nothing.
Values under `env` show as `<hidden>`, or `<hidden, changed>` when the update
changes them. Each deleted key is printed as `Removed: <key path>`.

The script stops without writing when `settings.json`, the overrides file or
`.settings.managed.json` is not one JSON object, or when the repo or the
overrides set `env` to anything but an object.

### Per-Machine Overrides

Put values that differ on one machine in `<target>/settings.overrides.json`.
It is never in the repo. For example, a machine that wants a higher effort
level and no status line:

```json
{
  "effortLevel": "high",
  "statusLine": null
}
```

Settings that Claude Code saves for you, such as `/effort` or a plugin you
turn on in `/plugin`, are written to `settings.json`. If the repo also sets
that key, the next `make update-settings` puts the repo value back. Move the
value into the overrides file to keep it.

### Clearing Old Keys

A home synced before `.settings.managed.json` existed can still hold keys the
repo dropped long ago. `PRUNE` deletes every leaf under the named top-level
keys that neither the repo nor the overrides file sets:

```bash
make update-settings DRY_RUN=1 PRUNE="modelSettings enabledPlugins"  # Preview
make update-settings PRUNE="modelSettings enabledPlugins"
```

Move anything you want to keep into the overrides file first. `PRUNE` refuses
`env`, because that is where local secrets live.

`update-claude-md` always makes a plain copy of `CLAUDE.md`.

## What the Makefile Does Not Do

The Makefile writes only inside `TARGET_DIR`, plus `~/.claude-backups` for
`make backup`. It does not install programs, third-party skills, or MCP
servers, and it never touches `.claude.json`. Set those up by hand:

- [External Tools](../guides/external-tools.md) - Node.js, language servers,
  the claudish model server, and third-party skills
- [MCP Servers](mcp-servers.md) - `claude mcp add` steps for each server

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
colors match what `make update-all` would do to the target:

- **Green** lines are lines `make update-all` would add to the target
- **Red** lines are lines `make update-all` would remove from the target

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
`NO_RSYNC=1` fallback path and the settings.json merge. It checks that
`update-settings` and `update-claude-md` each leave the other config file
alone, and that `update-all` does not write `.claude.json`.

## Status Legend

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)
