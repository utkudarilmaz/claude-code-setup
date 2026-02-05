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
| `claude-mem` | `thedotmack/claude-mem` | Memory and context persistence |

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

| Plugin | Purpose |
|--------|---------|
| `claude-hud` | Status line UI |
| `commit-commands` | Git commit helpers |
| `explanatory-output-style` | Output formatting |
| `context7` | Documentation queries |
| `claude-mem` | Memory and context persistence |
| `superpowers` | Advanced skill framework |

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

- `suggest-compact.sh` - Suggests `/compact` at logical intervals (every 50 tool calls)
- `sensitive-file-protection` - Blocks writes to protected files
- `notification` - Plays audio notification on idle/permission prompts

## Global Conventions

The `.claude/CLAUDE.md` file contains conventions applied to all projects:

- No AI attribution in commits
- Conventional commits format
- Tags without `v` prefix
- camelCase for JSON field names
- Check available skills/agents when planning tasks
