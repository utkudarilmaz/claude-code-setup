# Installation

## Requirements

- **Node.js** - Required for statusLine plugins (claude-hud, claude-pray)
- **Bash** - For hook scripts and status line commands
- **Audio system** (optional) - For notification sounds:
  - macOS: Built-in `afplay` command
  - Linux: PulseAudio (`paplay`) or ALSA (`aplay`)

## Platform Support

This configuration is tested and compatible with:
- macOS (Intel and Apple Silicon)
- Linux (Ubuntu, Debian, Fedora, Arch)

Cross-platform features:
- Dynamic node path resolution (works with Homebrew, nvm, system installations)
- Audio notification fallback chain (macOS and Linux)

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

### Sync Status

Check sync status with color-coded indicators:

```bash
make status
```

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)

### StatusLine Not Working

If the status line doesn't display:

1. Verify Node.js is installed and in PATH:
   ```bash
   command -v node
   ```

2. Check if plugins are installed:
   ```bash
   ls -d ~/.claude/plugins/cache/claude-hud/claude-hud/*/
   ls -d ~/.claude/plugins/cache/claude-pray/claude-pray/*/
   ```

3. Ensure plugins are enabled in `~/.claude/settings.json`

### Notification Sounds Not Playing

On macOS:
- System sounds should work by default with `afplay`

On Linux:
- Install PulseAudio: `sudo apt-get install pulseaudio-utils` (Ubuntu/Debian)
- Or ensure ALSA is configured: `sudo apt-get install alsa-utils`

See [Makefile Commands](../reference/makefile.md) for all available commands.
