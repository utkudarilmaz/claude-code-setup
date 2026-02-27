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
| `claude-md-management` | `claude-plugins-official` | CLAUDE.md lifecycle management |
| `feature-dev` | `claude-plugins-official` | Feature development workflows |
| `superpowers` | `claude-plugins-official` | Advanced skill framework |
| `commit-commands` | `claude-plugins-official` | Git commit helpers |
| `explanatory-output-style` | `claude-plugins-official` | Output formatting |
| `context7` | `claude-plugins-official` | Documentation queries |
| `code-review` | `claude-plugins-official` | Code review assistance |
| `code-simplifier` | `claude-plugins-official` | Code simplification |
| `security-guidance` | `claude-plugins-official` | Security best practices |

Disabled plugins (set to `false`) remain registered but inactive. Notable disabled plugins include `marketing-skills@marketingskills` and various design/animation skills from `claude-design-skillstack`.

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

- `sensitive-file-protection` - Blocks writes to protected files
- `notification` - Plays audio notification on idle/permission prompts

## Global Conventions

The `.claude/CLAUDE.md` file contains conventions applied to all projects:

- No AI attribution in commits
- Conventional commits format
- Tags without `v` prefix
- camelCase for JSON field names
- Check available skills/agents when planning tasks
