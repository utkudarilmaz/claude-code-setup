# Configuration

## settings.json Structure

```json
{
  "hooks": {
    "PreToolUse": [...]     // Tool call interception
  },
  "statusLine": {...},       // Status bar configuration
  "enabledPlugins": {...}    // Plugin enable/disable map
}
```

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
