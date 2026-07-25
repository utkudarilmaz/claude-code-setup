# Configuration

## settings.json Structure

```json
{
  "hooks": {
    "PreToolUse": [...],             // Tool call interception
    "Notification": [...]            // Notification events
  },
  "statusLine": {...},                // Status bar configuration
  "enabledPlugins": {...},            // Plugin enable/disable map
  "extraKnownMarketplaces": {...},    // External plugin sources
  "effortLevel": "high",              // Default reasoning effort
  "skipDangerousModePermissionPrompt": true, // Skip prompt for dangerous mode
  "skipAutoPermissionPrompt": true    // Skip prompt for auto-approved actions
}
```

## Marketplace Configuration

External plugin marketplaces are configured via `extraKnownMarketplaces` in settings.json:

```json
{
  "extraKnownMarketplaces": {
    "marketplace-name": {
      "source": {
        "source": "github",
        "repo": "owner/repository"
      }
    }
  }
}
```

### Configured Marketplaces

| Marketplace | Repository | Description |
|-------------|------------|-------------|
| `claude-hud` | `jarrodwatts/claude-hud` | Status line HUD plugin |
| `claude-design-skillstack` | `freshtechbro/claudedesignskills` | Design and animation plugins |
| `ui-ux-pro-max-skill` | `nextlevelbuilder/ui-ux-pro-max-skill` | UI/UX design skills |
| `marketingskills` | `coreyhaines31/marketingskills` | Marketing skill plugins |
| `claude-pray` | `utkudarilmaz/claude-pray` | Prayer times and status line utilities |

The official `claude-plugins-official` marketplace from Anthropic is built-in and doesn't require configuration.

## Plugin Management

Plugins are toggled via `enabledPlugins` map:

```json
{
  "enabledPlugins": {
    "plugin-name@source": true,   // enabled
    "other-plugin@source": false  // disabled
  }
}
```

### Currently Enabled Plugins

| Plugin | Source | Purpose |
|--------|--------|---------|
| `claude-hud` | `claude-hud` | Status line UI |
| `claude-pray` | `claude-pray` | Prayer times and status line utilities |
| `claude-md-management` | `claude-plugins-official` | CLAUDE.md lifecycle management |
| `feature-dev` | `claude-plugins-official` | Feature development workflows |
| `superpowers` | `claude-plugins-official` | Advanced skill framework |
| `commit-commands` | `claude-plugins-official` | Git commit helpers |
| `explanatory-output-style` | `claude-plugins-official` | Output formatting |
| `context7` | `claude-plugins-official` | Documentation queries |
| `code-review` | `claude-plugins-official` | Code review assistance |

Disabled plugins (set to `false`) remain registered but inactive. Notable disabled plugins include `code-simplifier@claude-plugins-official`, `security-guidance@claude-plugins-official`, `marketing-skills@marketingskills`, and various design/animation skills from `claude-design-skillstack`.

## Hook Configuration

Hooks intercept tool calls for automation. See [Extension Model](../architecture/extension-model.md) for details.

### Adding a Hook

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "ToolPattern",
      "hooks": [{"type": "command", "command": "path/to/script.sh"}]
    }]
  }
}
```

### Current Hooks

Hook scripts live in `.claude/hooks/` and are referenced from settings.json by their `~/.claude/hooks/` path after sync.

#### sensitive-file-protection

Script: `.claude/hooks/sensitive-file-protection.sh`

Blocks Edit and Write calls on protected files (.env, credentials, secrets, lock files). Claude Code sends the tool call as JSON on stdin; the script extracts `tool_input.file_path` (with `jq`, or a `sed` fallback when jq is not installed) and exits with code 2 to block the call. Exit code 2 is required: it is the only exit code that blocks a tool call, and the script's stderr message is fed back to Claude.

Tests: `tests/sensitive-file-protection.test.sh`

#### notification

Script: `.claude/hooks/notification.sh`

Plays a sound whenever Claude Code sends a notification (idle prompts, permission prompts, and other notification events). Cross-platform support for macOS and Linux.

**Platform support:**
- macOS: Uses `afplay` with system sound
- Linux (PulseAudio): Uses `paplay`
- Linux (ALSA): Falls back to `aplay`

### StatusLine Configuration

The status line uses dynamic node path resolution for cross-platform compatibility:

```bash
bash -c 'EXISTING=$(\"$(command -v node)\" ...) ...'
```

This approach works on both macOS (where node may be at `/opt/homebrew/bin/node`) and Linux (typically `/usr/bin/node`), avoiding hardcoded paths.

## Global Conventions

The `.claude/CLAUDE.md` file contains conventions applied to all projects:

- No AI attribution in commits
- Conventional commits format
- Tags without `v` prefix
- Never commit before the user manually asks
- Never mention task IDs or names on comment lines
- Never use double dashes
- Never reply to human comments without asking
- Plain simple English when documenting or explaining, including PR bodies and PR comments
- camelCase for JSON field names
- Check available skills/agents/plugins/MCP servers when planning tasks
- Use tofu instead of terraform
