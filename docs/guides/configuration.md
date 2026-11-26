# Configuration

## settings.json Structure

The base settings live in `config/settings.json`. `make update-settings` merges
them into each home, see [Makefile Commands](../reference/makefile.md#settingsjson-merge).

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {...},                       // CLAUDISH_* settings for the claudish plugin
  "statusLine": {...},                // Status bar configuration
  "enabledPlugins": {...},            // Plugin enable/disable map
  "skillOverrides": {...},            // Skill on/off map
  "extraKnownMarketplaces": {...},    // External plugin sources
  "effortLevel": "medium",            // Default reasoning effort
  "modelSettings": {...},             // Per-model settings such as effortLevel
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
| `claude-code-setup` | `utkudarilmaz/claude-code-setup` | This repo, with the `core` plugin. Auto update is on |
| `claude-hud` | `jarrodwatts/claude-hud` | Status line HUD plugin |
| `claude-design-skillstack` | `freshtechbro/claudedesignskills` | Design and animation plugins |
| `ui-ux-pro-max-skill` | `nextlevelbuilder/ui-ux-pro-max-skill` | UI/UX design skills |
| `marketingskills` | `coreyhaines31/marketingskills` | Marketing skill plugins |
| `claude-pray` | `utkudarilmaz/claude-pray` | Prayer times and status line utilities |
| `gvzdv-plugins` | `gvzdv/claudish-to-english` | Plain English rewrite plugin |

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
| `core` | `claude-code-setup` | This repo's agents, skills and hooks |
| `claude-hud` | `claude-hud` | Status line UI |
| `claude-pray` | `claude-pray` | Prayer times and status line utilities |
| `claudish-to-english` | `gvzdv-plugins` | Rewrites each message in plain English, see [External Tools](external-tools.md#claudish-plugin) |
| `commit-commands` | `claude-plugins-official` | Git commit helpers |
| `explanatory-output-style` | `claude-plugins-official` | Output formatting |
| `code-review` | `claude-plugins-official` | Code review assistance |
| `typescript-lsp` | `claude-plugins-official` | TypeScript and JavaScript code intelligence via `typescript-language-server`, see [External Tools](external-tools.md#language-servers) |
| `gopls-lsp` | `claude-plugins-official` | Go code intelligence via `gopls`, see [External Tools](external-tools.md#language-servers) |

Disabled plugins (set to `false`) remain registered but inactive. Notable disabled plugins include `claude-md-management@claude-plugins-official`, `feature-dev@claude-plugins-official`, `code-simplifier@claude-plugins-official`, `security-guidance@claude-plugins-official`, `marketing-skills@marketingskills`, and various design/animation skills from `claude-design-skillstack`.

## Skill Overrides

Single skills are turned off via the `skillOverrides` map, even when the plugin or built-in set that ships them stays on:

```json
{
  "skillOverrides": {
    "anthropic-skills:pdf": "off"
  }
}
```

The default settings turn off the built-in `anthropic-skills` for docs, office files (`docx`, `xlsx`, `pptx`, `pdf`), browsers (`built-in-browser`, `chrome-browser`), `computer-use`, `google-workspace`, `doc-coauthoring`, `skill-creator`, `morning`, and `import-memory`. They also turn off `anatomy`, the isometric figure skill from [External Tools](external-tools.md#third-party-skills). `make update-settings` keeps entries you add locally (for example `"seo": "off"`). To change a repo value on one machine, use `settings.overrides.json`, see [Per-Machine Overrides](../reference/makefile.md#per-machine-overrides).

## Hook Configuration

Hook scripts live in `plugins/core/hooks/` and are wired in `plugins/core/hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}`, so they run from the installed plugin. The base `settings.json` has no `hooks` block. To add a hook, follow [Contributing](contributing.md#new-hook). The wiring format is in [Extension Model](../architecture/extension-model.md#hook-system).

### Current Hooks

#### sensitive-file-protection

Script: `plugins/core/hooks/sensitive-file-protection.sh`

Blocks Edit and Write calls on protected files (.env, credentials, secrets, lock files). `.env.example` is allowed because it holds placeholder values, not real secrets. Claude Code sends the tool call as JSON on stdin; the script extracts `tool_input.file_path` (with `jq`, or a `sed` fallback when jq is not installed) and exits with code 2 to block the call. Exit code 2 is required: it is the only exit code that blocks a tool call, and the script's stderr message is fed back to Claude.

Tests: `tests/sensitive-file-protection.test.sh`

#### dirty-merge-protection

Script: `plugins/core/hooks/dirty-merge-protection.sh`

Blocks Bash calls that run `git merge` or `gh pr merge` while the repo has uncommitted changes, including untracked files. It checks the directory from `git -C <dir>`, else the last `cd <dir>` anywhere in the command (subshells included), else the session's `cwd`. `git merge --abort`, `--continue`, and `--quit` are allowed so a merge in progress can still be finished or undone. Commands outside a git repo pass through. The hook runs git with `core.fsmonitor` and git hooks turned off, so the target repo's config cannot run commands.

Tests: `tests/dirty-merge-protection.test.sh`

#### notification

Script: `plugins/core/hooks/notification.sh`

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

This finds `node` wherever it is installed: `/opt/homebrew/bin/node` with Homebrew, `~/.nvm/versions/node/*/bin/node` with nvm, or `/usr/bin/node` on Linux.

The command also prints `user@hostname` in dim text at the start of the first line, before the claude-hud output. It reads `id -un` and `hostname -s` on every refresh, so each machine shows its own values and no claude-hud setting is needed.

## MCP Servers

MCP servers are not part of `settings.json` and the repo does not sync them.
Add them by hand with `claude mcp add`. The steps are in
[MCP Servers](../reference/mcp-servers.md).

## Global Conventions

`config/CLAUDE.md` holds the conventions applied to all projects. `make update-claude-md` copies it into each home. Read that
file for the current list.
