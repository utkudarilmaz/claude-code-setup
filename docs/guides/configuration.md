# Configuration

## settings.json Structure

```json
{
  "hooks": {
    "PreToolUse": [...]           // Tool call interception
  },
  "statusLine": {...},             // Status bar configuration
  "enabledPlugins": {...},         // Plugin enable/disable map
  "extraKnownMarketplaces": {...}  // External plugin sources
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

#### sensitive-file-protection
Blocks writes to protected files (.env, credentials, secrets, lock files).

**Implementation:**
```bash
bash -c '[[ "$TOOL_INPUT" =~ (\.env|credentials|secrets|\.lock|lock\.json|lock\.yaml) ]] && echo "BLOCK: Protected file" && exit 1 || exit 0'
```

#### notification
Plays audio notification on idle or permission prompts. Cross-platform support for macOS and Linux.

**Implementation:**
```bash
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || \
paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || \
aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || \
true
```

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
- camelCase for JSON field names
- Check available skills/agents when planning tasks
