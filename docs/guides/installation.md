# Installation

## Requirements

- **Claude Code** - with plugin support (`claude plugin --help` works)
- **Bash** - For hook scripts and status line commands
- **jq** - Required to merge `settings.json` on sync
- **Audio system** (optional) - For notification sounds:
  - macOS: Built-in `afplay` command
  - Linux: PulseAudio (`paplay`) or ALSA (`aplay`)

The Makefile only syncs `settings.json` and `CLAUDE.md`. Set up Node.js, the
language servers, the claudish model server, and third-party skills by hand
from [External Tools](external-tools.md). Add MCP servers by hand from
[MCP Servers](../reference/mcp-servers.md).

## Platform Support

This configuration is tested on:
- macOS (Intel and Apple Silicon)
- Linux (Ubuntu, Debian, Fedora, Arch)

## New Machine

```bash
git clone https://github.com/utkudarilmaz/claude-code-setup
cd claude-code-setup
make update-config
```

`make update-config` merges `config/settings.json` into `~/.claude/settings.json`
and copies `config/CLAUDE.md`. The base settings declare the
`claude-code-setup` marketplace with auto update on and enable
`core@claude-code-setup`. On the next start, Claude Code clones the
marketplace and installs the plugin in the background. Start a new session or
run `/reload-plugins` to load it.

To install by hand instead, or on a machine without the shared settings:

```
/plugin marketplace add utkudarilmaz/claude-code-setup
/plugin install core@claude-code-setup
```

For a second Claude home, pass it as `TARGET_DIR`, and set `CLAUDE_CONFIG_DIR`
when you run Claude Code or the `claude plugin` commands for that home:

```bash
make update-config TARGET_DIR=$HOME/.claude-personal
CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude
```

## Moving From the Old File Sync

Before the plugin, `make update-all` copied agents, skills and hooks into
`~/.claude` and wired the hooks in `settings.json`. Those copies would now load
next to the plugin: every hook would run twice, and the old skill copies would
take the bare command names. Clean them up once on each machine:

```bash
git pull
make migrate DRY_RUN=1   # See what would go
make migrate             # Back up the home, then remove the old copies
make update-config
```

`make migrate` removes only the files whose names the plugin ships, plus the
old `security-review` agent and skill. Your own agents, skills and hooks stay.
In `settings.json` it removes only hook entries that run one of the plugin's
scripts from `<home>/hooks/`. `make status` tells you when a home still needs
it.

## Using the Skills

```
/docs                    # Document recent changes
/tester                  # Test recent changes
/security-audit          # Security review
/changelog               # Update changelog
```

A bare name works when no other command has it. If one does, use the
namespaced form, for example `/core:docs`. See
[Skills Reference](../reference/skills.md) for every command.

## Updating

- **Agents, skills and hooks** update by themselves. Claude Code checks the
  marketplace at session start because auto update is on. To update now, run
  `/plugin marketplace update claude-code-setup`.
- **Settings and CLAUDE.md** update when you run:
  ```bash
  git pull
  make update-config
  ```

## Working on the Plugin

To try changes before they are on `main`, load the plugin from your checkout
for one session:

```bash
claude --plugin-dir ./plugins/core
```

To keep one machine on your checkout, so the plugin loads in place from the
working tree, point the marketplace at it in that home's
`settings.overrides.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-code-setup": {
      "source": { "source": "directory", "path": "/path/to/claude-code-setup", "repo": null }
    }
  }
}
```

Then run `make update-settings`. Adding the checkout with
`/plugin marketplace add` alone also works, but the next `make update-config`
puts the GitHub source back.

## Troubleshooting

### Sync Status

```bash
make status
```

- **Green (●)** - In sync with the repo
- **Yellow (●)** - Differs from the repo, or old copies are still there
- **Red (●)** - Missing from the home

### Skills Missing

1. Check that the plugin is installed and enabled: `claude plugin list`
2. Check that `~/.claude/settings.json` has `"core@claude-code-setup": true`
   under `enabledPlugins`
3. Run `/reload-plugins`, or start a new session

### StatusLine Not Working

1. Verify Node.js is installed and in PATH, see [External Tools](external-tools.md#nodejs):
   ```bash
   command -v node
   ```
2. Check if the status line plugins are installed:
   ```bash
   ls -d ~/.claude/plugins/cache/claude-hud/claude-hud/*/
   ls -d ~/.claude/plugins/cache/claude-pray/claude-pray/*/
   ```

### Notification Sounds Not Playing

On macOS:
- System sounds should work by default with `afplay`

On Linux:
- Install PulseAudio: `sudo apt-get install pulseaudio-utils` (Ubuntu/Debian)
- Or ensure ALSA is configured: `sudo apt-get install alsa-utils`

See [Makefile Commands](../reference/makefile.md) for all available commands.
