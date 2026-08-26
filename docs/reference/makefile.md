# Makefile Commands

The Makefile provides granular control over syncing between this repo and `~/.claude`.

## Update Commands (non-destructive)

Add missing files and update changed files, keep extras:

```bash
make update-all       # Update agents, skills, hooks, and config
make update-agents    # Update .claude/agents/ only
make update-skills    # Update .claude/skills/ only
make update-hooks     # Update .claude/hooks/ only
make update-config    # Update settings.json (merged), CLAUDE.md, and MCP servers
make update-mcp       # Update MCP servers in .claude.json only
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

### MCP Server Sync

Claude Code does not read MCP servers from `settings.json` or from any file
inside `~/.claude/`. User-scoped servers live in `.claude.json`:

- Default home: `~/.claude.json` (next to `~/.claude`)
- Custom home (`CLAUDE_CONFIG_DIR`, e.g. `TARGET_DIR=$HOME/.claude-personal`):
  `<target dir>/.claude.json`

`update-config` merges the `mcpServers` block from the repo's
`.claude/mcp-servers.json` into that file. `update-mcp` runs that same merge on
its own, without touching `settings.json` or `CLAUDE.md`:

- Servers defined in the repo replace the local definition of the same name
  wholesale (no stale keys survive inside a repo-managed server)
- Servers that exist only locally are kept
- Everything else in `.claude.json` (session state, auth, projects) is
  untouched

The merge requires `jq`; without it the MCP sync is skipped with a warning.
The servers themselves are documented in [MCP Servers](mcp-servers.md).
`make status` and `make diff` report each repo-managed server as synced,
differing, or missing against the resolved `.claude.json`.

## Install Commands

Install external tools and the requirements they need to run, from a registry
of named targets split into groups:

```bash
make install                    # Install every registered target
make install skills             # Skill installs only
make install plugins            # Plugin requirements only
make install mcps               # MCP server requirements only
make install <target>           # Install a single target
make DRY_RUN=1 install claudish # Preview without installing
```

Registered targets:

| Group | Target | Action |
|-------|--------|--------|
| skills | `google-maps-scraper` | `npx skills add gosom/google-maps-scraper` |
| plugins | `claudish` | `ollama` and `jq` via brew, a 30m idle keep-alive for loaded models, the ollama service started and enabled at login, and the `CLAUDISH_MODEL` named in `.claude/settings.json` pulled |
| plugins | `claude-hud` | `node` via brew, needed by the statusline |
| plugins | `claude-pray` | `node` via brew, needed by the statusline |
| mcps | `build123d-mcp` | `uv` via brew |
| mcps | `terraform-mcp` | Docker Desktop via brew cask, the `hashicorp/terraform-mcp-server` image pulled, and a warning when `TFE_TOKEN` is not exported |

The remaining enabled plugins need no local installs: superpowers,
commit-commands, explanatory-output-style, and code-review are skills and
commands only, and context7 is a remote HTTP MCP server (set
`CONTEXT7_API_KEY` in the environment if you have one; it works without it).

Each step is skipped when the requirement is already present, and each asks
for approval first, only when actually needed: keeping ollama models loaded
for 30m of idle time, installing missing brew packages, starting the ollama
server now, enabling autostart at login for the ollama service (asked even when
the server is already running some other way), pulling the claudish model (a
multi-GB download), and pulling the terraform server image. Answering no to
autostart when starting the ollama server uses `brew services run` instead of
`brew services start`, so the server runs now without a login item. Declining a
step skips it and the run continues. `FORCE=1` skips all prompts.

The keep-alive is asked first, so the setting is in place before the recipe
starts the service. It writes `OLLAMA_KEEP_ALIVE` to
`~/.homebrew/services/ollama.env`, the env override file `brew services` merges
into the generated launchd plist on every start, so it survives `brew upgrade`
where a hand-edited plist would not. ollama's own default is 5m, short enough
that a model unloads during a normal reading gap and the next claudish rewrite
waits for a multi-second reload. When the server is already running, the step
prints the `brew services restart ollama` needed to apply it.

To add a new target, append its name to the matching group variable in the
Makefile (`INSTALL_SKILLS`, `INSTALL_PLUGINS`, or `INSTALL_MCPS`) and add a
matching `install-<name>` recipe in the INSTALL COMMANDS section.

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
| `OLLAMA_KEEP_ALIVE=<duration>` | Idle time before ollama unloads a model, asked during `install claudish` (default `30m`) |

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
`NO_RSYNC=1` fallback path, the settings.json merge, and the MCP server
merge into `.claude.json` from both `update-config` and `update-mcp`.

## Status Legend

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)
