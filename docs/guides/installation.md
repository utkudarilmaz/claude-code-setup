# Installation

## Requirements

- **Node.js** - Required for statusLine plugins (claude-hud, claude-pray)
- **Bash** - For hook scripts and status line commands
- **jq** - Merges `settings.json` and the MCP servers on sync; without it `settings.json` is copied over and the MCP sync is skipped
- **Docker** (optional) - Needed only by the MCP server this repo ships, see [MCP Servers](../reference/mcp-servers.md)
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
git clone https://github.com/utkudarilmaz/claude-code-setup
cd claude-code-setup

# Sync to ~/.claude
make update-all       # Add missing + update changed files
make status           # Check sync status
```

## Claudish Plugin

The claudish-to-english plugin rewrites each message in plain English with a
model server. The repo `settings.json` sets `CLAUDISH_PROVIDER=openai`, the
OpenAI API format, and `CLAUDISH_MODEL=gemma4-26b`. The server itself is set up
by hand. These steps use `llama-server` from llama.cpp on macOS.

1. Install the tools:
   ```bash
   brew install llama.cpp jq
   ```
2. Download the model and its helper file (14.7 GB together):
   ```bash
   mkdir -p ~/models/gguf && cd ~/models/gguf
   curl -L -O https://huggingface.co/google/gemma-4-26B-A4B-it-qat-q4_0-gguf/resolve/main/gemma-4-26B_q4_0-it.gguf
   curl -L -O https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF/resolve/main/mtp-gemma-4-26B-A4B-it-Q4_0.gguf
   ```
3. Create an API key that only you can read:
   ```bash
   mkdir -p ~/.config/llama-server
   (umask 077; printf 'sk-local-%s\n' "$(openssl rand -hex 24)" > ~/.config/llama-server/api-key)
   ```
4. Start the server. The alias must match `CLAUDISH_MODEL`. Thinking is off
   because the plugin does not turn it off for this kind of server:
   ```bash
   llama-server -m ~/models/gguf/gemma-4-26B_q4_0-it.gguf --alias gemma4-26b \
     --host 127.0.0.1 --port 11435 -c 16384 -ngl 99 --parallel 1 \
     --jinja --reasoning off --temp 0.3 --top-k 64 --top-p 0.95 \
     --spec-type draft-mtp,ngram-mod \
     --spec-draft-model ~/models/gguf/mtp-gemma-4-26B-A4B-it-Q4_0.gguf \
     --api-key-file ~/.config/llama-server/api-key
   ```
5. Add the server URL and the key to the `env` block of `~/.claude/settings.json`:
   ```json
   "CLAUDISH_OPENAI_URL": "http://127.0.0.1:11435/v1",
   "CLAUDISH_OPENAI_KEY": "<the key from step 3>"
   ```
6. Start a new Claude Code session and run `/claudish` to check the provider
   and the model.

The URL and the key are not in the repo, so `make update-settings` keeps them.
A machine without its own server can set `CLAUDISH_OPENAI_URL` to another host
that runs the server with `--host 0.0.0.0`.

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

MCP servers are written to `~/.claude.json`, outside that directory. The
terraform server needs `TFE_TOKEN` exported before you start Claude Code, see
[MCP Servers](../reference/mcp-servers.md).

## Basic Usage

Once installed, you can use skills in Claude Code:

```
/docs                    # Document recent changes
/tester                  # Test recent changes
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
