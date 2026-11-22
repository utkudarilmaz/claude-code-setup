# Makefile Commands

Agents, skills and hooks reach each machine through the `core` plugin, so the
Makefile only syncs the two files a plugin cannot ship: `settings.json` and
`CLAUDE.md`. It also cleans up homes that were synced the old way.

## Sync Commands

```bash
make update-config    # Run update-settings and update-claude-md
make update-settings  # Merge config/settings.json into the home's settings.json
make update-claude-md # Copy config/CLAUDE.md
```

Each of the two targets under `update-config` can be run alone and touches
only its own file.

### settings.json Merge

`update-settings` builds the target `settings.json` from three layers with
`scripts/apply-settings.sh`. Later layers win:

1. The current target `settings.json`, with its machine-local keys
2. The repo base, `config/settings.json`
3. The home's own `settings.overrides.json`, if it exists

The rules:

- Keys that only the target has are kept, such as secrets in `env` and keys
  Claude Code writes itself.
- Repo keys win over the target, and overrides win over the repo.
- A key set to `null` in the overrides file is removed from the result, even
  when only the target has it.
- A key that the repo or the overrides file stops setting is deleted from the
  target on the next run. An object left empty by that is deleted too.
- Arrays are replaced whole, never merged item by item.

To know what it set last time, the script saves the key paths of the merged
repo and override layers to `.settings.managed.json` in the target. It saves
no values. Leave that file alone. On the first run it does not exist yet, so
no dropped keys are deleted. [Clearing Old Keys](#clearing-old-keys) covers
those.

`jq` is required. The script prints `Updated: settings.json` or
`Unchanged: settings.json`, and `Removed: <key path>` for each deleted key.
`DRY_RUN=1` writes nothing. It prints `Would update: settings.json` with a diff,
and `Would remove: <key path>` for each key. In the diff, values under `env`
show as `<hidden>`, or `<hidden, changed>` when the update adds or changes them.

The script stops without writing when the repo base is missing, when the base,
`settings.json`, the overrides file or `.settings.managed.json` is not one JSON
object, or when the repo or the overrides set `env` to anything but an object.

It writes `settings.json` in place, so a symlink stays a symlink and the file
keeps its mode. New files are readable only by you. If the write fails, the
script puts the old file back, or prints where it saved a copy.

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
keys that neither the repo nor the overrides file sets. Split the keys with
spaces or commas:

```bash
make update-settings DRY_RUN=1 PRUNE="modelSettings enabledPlugins"  # Preview
make update-settings PRUNE="modelSettings enabledPlugins"
```

Move anything you want to keep into the overrides file first. `PRUNE` refuses
`env`, because that is where local secrets live.

## What the Makefile Does Not Do

The Makefile writes only inside `TARGET_DIR`, plus `~/.claude-backups` for
`make backup`. It does not install programs, third-party skills, or MCP
servers, and it never touches `.claude.json`. Set those up by hand:

- [External Tools](../guides/external-tools.md) - Node.js, language servers,
  the claudish model server, and third-party skills
- [MCP Servers](mcp-servers.md) - `claude mcp add` steps for each server

## Moving From the Old File Sync

```bash
make migrate DRY_RUN=1   # List what would go
make migrate             # Ask, back up the home, then remove the old copies
```

Before the plugin, the Makefile copied agents, skills and hooks into the home
and wired the hooks in `settings.json`. `make migrate` asks first, makes a
backup with `make backup`, then runs `scripts/migrate.sh`, which:

- removes each `agents/`, `skills/` and `hooks/` entry in the home whose name
  the plugin ships, plus the old `agents/security-review.md` and
  `skills/security-review/`
- removes the hook entries in `settings.json` whose command runs one of the
  plugin's scripts from `<home>/hooks/`, then any matcher group or event left
  empty

Anything else in the home stays, including your own agents, skills and hooks.
`FORCE=1` skips the question. Running it again does nothing.

## Utility Commands

```bash
make status    # Show whether settings.json and CLAUDE.md match, and whether migrate is needed
make diff      # Show what update-config would change
make backup    # Create a timestamped backup of the home in ~/.claude-backups
make test      # Run all tests/*.test.sh suites
make help      # Display all commands
```

`make status` calls `settings.json` synced when an update would change
nothing, so local keys and overrides do not count as a difference. `make diff`
prints the same diff as `make update-settings DRY_RUN=1`, with `env` values
hidden, then the `CLAUDE.md` diff.

## Options

| Option | Description |
|--------|-------------|
| `TARGET_DIR=<path>` | Sync a Claude home other than `~/.claude` |
| `DRY_RUN=1` | Preview changes without writing |
| `FORCE=1` | Skip confirmation prompts |
| `PRUNE="<keys>"` | With `update-settings`, clear stale leaves under these top-level keys once |
| `BACKUP_DIR=<path>` | Where `make backup` and `make migrate` put backups (default `~/.claude-backups`) |

To keep more than one Claude home, such as a work and a personal profile, sync
each one with its own `TARGET_DIR`:

```bash
make update-config TARGET_DIR=$HOME/.claude-personal
```

## Status Legend

- **Green (●)** - In sync with the repo
- **Yellow (●)** - Differs from the repo, or old copies are still there
- **Red (●)** - Missing from the home
