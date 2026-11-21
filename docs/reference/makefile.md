# Makefile Commands

The Makefile provides granular control over syncing between this repo and `~/.claude`.

## Update Commands (non-destructive)

Add missing files and update changed files, keep extras:

```bash
make update-all       # Update agents, skills, hooks, and config
make update-agents    # Update .claude/agents/ only
make update-skills    # Update .claude/skills/ only
make update-hooks     # Update .claude/hooks/ only
make update-config    # Run update-settings, update-claude-md, and update-mcp
make update-settings  # Update settings.json only (merged)
make update-claude-md # Update CLAUDE.md only
make update-mcp       # Update MCP servers in .claude.json only
```

`update-config` is a group target. Each of the three targets under it can be
run alone and touches only its own file.

### settings.json Merge

`update-settings` does not overwrite the target `settings.json`. When `jq` is
available, it deep-merges the repo file into the target file:

- Keys that exist only in the target (machine-local state) are kept
- Keys present in the repo win on conflicts
- Keys deleted from the repo file are NOT removed from the target; delete
  them manually if needed

Without `jq`, the old copy behavior is used and a warning is printed because
local-only keys are lost.

`update-claude-md` always makes a plain copy of `CLAUDE.md`.

### MCP Server Sync

Claude Code does not read MCP servers from `settings.json` or from any file
inside `~/.claude/`. User-scoped servers live in `.claude.json`:

- Default home: `~/.claude.json` (next to `~/.claude`)
- Custom home (`CLAUDE_CONFIG_DIR`, e.g. `TARGET_DIR=$HOME/.claude-personal`):
  `<target dir>/.claude.json`

`update-mcp` merges the `mcpServers` block from the repo's
`.claude/mcp-servers.json` into that file, without touching `settings.json` or
`CLAUDE.md`. `update-config` runs it as its last step:

- Servers defined in the repo replace the local definition of the same name
  wholesale (no stale keys survive inside a repo-managed server)
- Servers that exist only locally are kept
- Everything else in `.claude.json` (session state, auth, projects) is
  untouched

Removing a server from `.claude/mcp-servers.json` does not remove it from an
already synced `.claude.json`. Run `claude mcp remove <name> -s user` to remove
it there, with `CLAUDE_CONFIG_DIR` set when the target is a custom home.

The merge requires `jq`; without it the MCP sync is skipped with a warning.
The servers themselves are documented in [MCP Servers](mcp-servers.md).
`make status` and `make diff` report each repo-managed server as synced,
differing, or missing against the resolved `.claude.json`.

## Install Commands

Install external tools and the requirements they need to run, from a registry
of named targets split into groups:

```bash
make install                    # Ask for each registered target
make install sync               # Ask for hooks and config
make install skills             # Ask for each skill install
make install plugins            # Ask for each plugin requirement
make install mcps               # Ask for each MCP server requirement
make install <target>           # Install a single target without asking
make DRY_RUN=1 install claudish # Preview without installing
```

`make install`, `make install all`, and the group forms ask `Install <target>?
[y/N]` before each target and install only the ones you approve. A declined
target is skipped and the run moves on to the next one. Naming a target
yourself (`make install anatomy`) installs it without that question. `FORCE=1`
installs everything without asking, and `DRY_RUN=1` previews every target
without asking.

Registered targets:

| Group | Target | Action |
|-------|--------|--------|
| sync | `hooks` | Same as `make update-hooks`: copies the hook scripts into `TARGET_DIR/hooks` |
| sync | `config` | Same as `make update-config`: merges `settings.json` (repo values win), copies `CLAUDE.md`, and merges the MCP servers |
| skills | `google-maps-scraper` | `npx skills add gosom/google-maps-scraper` |
| skills | `anatomy` | `npx skills add wheresryan22/anatomy -g -a claude-code` into `TARGET_DIR/skills`; turned off by default in `skillOverrides` |
| plugins | `claudish` | `llama.cpp` and `jq` via brew, the Gemma 4 model and its helper file downloaded, an API key, a `llama-server` login service on macOS, and the server URL and key written to `TARGET_DIR/settings.json` |
| plugins | `claude-hud` | `node` via brew, needed by the statusline |
| plugins | `claude-pray` | `node` via brew, needed by the statusline |
| plugins | `typescript-lsp` | `typescript-language-server` via brew, the language server the TypeScript LSP plugin talks to |
| plugins | `gopls-lsp` | `gopls` via brew, the language server the Go LSP plugin talks to |
| mcps | `terraform-mcp` | Docker Desktop via brew cask, the `hashicorp/terraform-mcp-server` image pulled, and a warning when `TFE_TOKEN` is not exported |

The remaining enabled plugins need no local installs: superpowers,
commit-commands, explanatory-output-style, and code-review are skills and
commands only.

Inside a target, each step is skipped when the requirement is already present, and each asks
for approval first, only when actually needed: installing missing brew
packages, downloading the claudish model files (a multi-GB download), starting
the `llama-server` login service, and pulling the terraform server image.
Declining a step skips it and the run continues. `FORCE=1` skips all prompts.

### The claudish server

The claudish plugin rewrites each message with a local model. `install claudish`
sets up a `llama-server` from llama.cpp for it:

- The model is Gemma 4 26B-A4B (Google QAT Q4_0, 14.4 GB) with a small MTP
  helper file. Both go to `LLAMA_MODEL_DIR`.
- A random API key is written to `LLAMA_KEY_FILE`, readable by the owner only.
  The server refuses requests without it.
- On macOS the service file is rendered from
  `services/local.llama-server.plist.template` into `~/Library/LaunchAgents`
  and started. It starts again at every login and unloads the model after
  `LLAMA_IDLE_SLEEP` seconds without a request. On other systems this step is
  skipped.
- `CLAUDISH_OPENAI_URL` and `CLAUDISH_OPENAI_KEY` are written to
  `TARGET_DIR/settings.json` when they are missing. They are never stored in
  the repo, so `make update-settings` keeps them, and a machine without its own
  server can point `CLAUDISH_OPENAI_URL` at another host.

The repo `settings.json` holds only `CLAUDISH_PROVIDER=openai`, which selects
the OpenAI API format that `llama-server` speaks, and `CLAUDISH_MODEL`, which
is also the model alias of the server.

The server flags in the template come from a benchmark on an Apple M5 Pro:
speculative decoding with `draft-mtp,ngram-mod` ran at about 128 tokens/s
against 77 without it. Thinking is off and the temperature is 0.3, because the
plugin sends neither to this kind of server.

Manage the service with `launchctl`:

```bash
launchctl kickstart -k gui/$(id -u)/local.llama-server    # Restart
launchctl bootout gui/$(id -u)/local.llama-server         # Stop
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.llama-server.plist  # Start
```

An existing service file is never overwritten. To apply a changed template or
option, stop the service, delete the file, and run `make install claudish`
again.

To add a new target, append its name to the matching group variable in the
Makefile (`INSTALL_SYNC`, `INSTALL_SKILLS`, `INSTALL_PLUGINS`, or `INSTALL_MCPS`) and add a
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
| `LLAMA_HOST=<address>` | Address the claudish server listens on (default `127.0.0.1`; `0.0.0.0` lets other machines use it) |
| `LLAMA_PORT=<port>` | Port of the claudish server (default `11435`) |
| `LLAMA_IDLE_SLEEP=<seconds>` | Idle time before the claudish server unloads the model (default `1800`) |
| `LLAMA_MODEL_DIR=<path>` | Where the model files are stored (default `~/models/gguf`) |
| `LLAMA_KEY_FILE=<path>` | File that holds the API key of the claudish server (default `~/.config/llama-server/api-key`) |

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
merge into `.claude.json` from both `update-config` and `update-mcp`. It
checks that `update-settings`, `update-claude-md`, and `update-mcp` each
leave the other two config files alone. It
also checks that `DRY_RUN=1 install anatomy` prints the command without
running `npx`, and that `install` asks for each target and installs only the
approved ones, including `hooks` and `config`.

## Status Legend

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)
