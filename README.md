# Claude Code Configuration

Personal Claude Code configuration repository containing custom agents, skills, hooks, and plugin settings for extending Claude Code functionality.

## Overview

This repository provides a modular extension framework for Claude Code with:

- **Agents** - Specialized AI assistants for documentation, testing, and changelog generation
- **Skills** - User-facing slash commands (`/docs`, `/tester`) with multiple invocation modes
- **Hooks** - Tool call interception for automation (strategic context compaction)
- **Plugin Management** - Centralized plugin enable/disable configuration

## Quick Start

### Installation

```bash
# Clone to any location
git clone https://github.com/yourusername/claude-code-setup
cd claude-code-setup

# Sync to ~/.claude
make update-all       # Add missing + update changed files
make status           # Check sync status
```

### Verify installation

```
~/.claude/
├── agents/           # Agent definitions
├── skills/           # Skill commands
├── settings.json     # Configuration
└── CLAUDE.md         # Global AI conventions
```

### Use skills

```
/docs                    # Document recent changes
/docs <scope>            # Document specific file/module/feature
/docs all                # Full documentation audit with planning

/tester                  # Test recent changes
/tester <scope>          # Test specific file/module/feature
/tester all              # Full test audit with planning

/pr-check                # Review current PR with full checklist
/pr-check <focus>        # Review PR with focus on specific aspect

/security-review         # Security review of recent changes
/security-review <path>  # Review specific file/module
/security-review all     # Full security audit with planning

/changelog               # Update CHANGELOG.md from git history
/changelog release       # Generate release notes for announcement
/changelog <version>     # Generate notes for specific version
```

## Makefile Commands

The Makefile provides granular control over syncing between this repo and `~/.claude`.

### Update Commands (non-destructive)

Add missing files and update changed files, keep extras:

```bash
make update-all       # Update agents, skills, and config
make update-agents    # Update .claude/agents/ only
make update-skills    # Update .claude/skills/ only
make update-config    # Update settings.json and CLAUDE.md
```

### Remove Commands

Remove repo-managed files from `~/.claude`:

```bash
make rm-agents    # Remove matching agents
make rm-skills    # Remove matching skills
```

### Utility Commands

```bash
make status    # Show sync status with colored indicators
make diff      # Show file differences
make backup    # Create timestamped backup of ~/.claude
make help      # Display all commands
```

### Options

| Option | Description |
|--------|-------------|
| `DRY_RUN=1` | Preview changes without executing |
| `FORCE=1` | Skip confirmation prompts |

Examples:
```bash
make update-all               # Add missing + update changed
make DRY_RUN=1 rm-agents      # Preview agent removal
make status                   # Check what needs updating
```

### Status Legend

- **Green (●)** - File is synced (identical)
- **Yellow (●)** - File differs between repo and target
- **Red (●)** - File missing from target
- **Blue (●)** - Extra file in target (not in repo)

## Repository Structure

```
claude-code-setup/              # This repository
├── .claude/                    # Claude Code config (becomes ~/.claude)
│   ├── agents/
│   │   ├── docs.md             # Documentation agent
│   │   ├── tester.md           # Test coverage agent
│   │   ├── pr-check.md         # PR quality reviewer
│   │   ├── security-reviewer.md # Security expert
│   │   ├── release-notes.md    # Release documentation
│   │   └── changelog-generator.md
│   ├── skills/
│   │   ├── docs/SKILL.md       # /docs command
│   │   ├── tester/SKILL.md     # /tester command
│   │   ├── pr-check/SKILL.md   # /pr-check command
│   │   ├── security-review/SKILL.md # /security-review command
│   │   ├── changelog/SKILL.md  # /changelog command
│   │   └── strategic-compact/
│   │       └── suggest-compact.sh
│   ├── settings.json           # Hooks, plugins, statusLine
│   └── CLAUDE.md               # Global conventions
├── CLAUDE.md                   # Repo guidance for contributors
└── README.md                   # This file
```

## Architecture

### Two-Tier Extension Model

```
┌─────────────────────────────────────────────────────┐
│                    User Input                        │
│                   /docs all                          │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              Skills Layer (SKILL.md)                 │
│  • Parses command arguments                          │
│  • Determines invocation mode                        │
│  • Dispatches to agent via Task tool                 │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              Agents Layer (*.md)                     │
│  • Contains domain expertise                         │
│  • Defines workflows and rules                       │
│  • Executes actual work                              │
└─────────────────────────────────────────────────────┘
```

**Skills** provide the `/command` interface and dispatch logic.
**Agents** contain the specialized knowledge and execution workflows.

### Hook System

Hooks intercept tool calls for pre/post processing:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "script.sh"}]
    }]
  }
}
```

Current hooks:
- `suggest-compact.sh` - Suggests `/compact` at logical intervals (every 50 tool calls)
- `sensitive-file-protection` - Blocks writes to protected files (.env, credentials, secrets, lock files)
- `notification` - Plays audio notification on idle/permission prompts

## Configuration

### settings.json Structure

```json
{
  "hooks": {
    "PreToolUse": [...]     // Tool call interception
  },
  "statusLine": {...},       // Status bar configuration
  "enabledPlugins": {...}    // Plugin enable/disable map
}
```

### Plugin Management

Plugins are toggled via `enabledPlugins` map:

```json
{
  "enabledPlugins": {
    "plugin-name@source": true,   // enabled
    "other-plugin@source": false  // disabled
  }
}
```

**Currently Enabled:**
- `claude-hud` - Status line UI
- `commit-commands` - Git commit helpers
- `explanatory-output-style` - Output formatting
- `context7` - Documentation queries
- `superpowers` - Advanced skill framework

## Agents

### docs

Documentation architect that manages README.md, CLAUDE.md, API docs, and postman collections.

**Trigger:** After code changes affecting documentation

**Responsibilities:**
- Analyze code changes and identify affected docs
- Update documentation files for accuracy
- Maintain consistent formatting and style
- Use camelCase for JSON field names

### tester

Test specialist ensuring comprehensive coverage.

**Trigger:** After implementing features, fixing bugs, or refactoring

**Responsibilities:**
- Write new tests (happy path, edge cases, errors)
- Update existing tests when code changes
- Run test suites and report results
- Follow Arrange-Act-Assert pattern

**Go Testing Commands:**
```bash
go test -v ./path/to/package/...           # Run tests
go test -v ./package -run TestName         # Single test
go test -coverprofile=coverage.out ./...   # Coverage
```

### pr-check

PR quality reviewer that verifies PRs against a quality checklist before merging.

**Trigger:** Before merging a PR or after addressing review comments

**Checklist:**
- Tests added/updated for code changes
- No hardcoded secrets or credentials
- Error handling is appropriate
- Breaking changes documented
- Commit messages follow conventions
- Documentation updated if needed
- Dependencies justified and secure
- No obvious code smells or anti-patterns

**Focus Modes:** tests, security, docs, breaking

### security-reviewer

Security expert that performs security-focused code review.

**Trigger:** When reviewing auth, payment, API endpoints, or input handling

**Focus Areas:**
- Authentication & Authorization (auth flows, session management, access control)
- Input Validation (SQL injection, XSS, command injection, path traversal)
- Data Exposure (PII leaks, sensitive data in logs, verbose errors)
- Secrets Management (hardcoded credentials, API keys, tokens)
- OWASP Top 10 vulnerabilities

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

### release-notes

Release documentation specialist that generates user-friendly release notes.

**Trigger:** When preparing a release or creating release announcements

**Responsibilities:**
- Parse git history since last tag
- Categorize changes by type (features, fixes, improvements)
- Write from user perspective with emojis
- Highlight breaking changes with migration guidance
- Format for GitHub releases or announcements

### changelog-generator

Generates CHANGELOG.md from git history using Keep a Changelog format.

**Trigger:** When explicitly requested via `/changelog`

**Commit Type Mapping:**
| Prefix | Changelog Section |
|--------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:`, `perf:` | Changed |
| `BREAKING CHANGE:` | Breaking Changes |
| `deprecate:` | Deprecated |
| `remove:` | Removed |
| `security:` | Security |

## Skills

### /docs

Synchronize documentation with code changes.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/docs` | Document recent changes |
| Scoped | `/docs <scope>` | Document specific area (file, module, feature) |
| Comprehensive | `/docs all` | Complete repository documentation audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent changes and updates affected documentation (README.md, CLAUDE.md, API docs)
- **Scoped:** Focuses only on specified area (e.g., module, API, specific file)
- **Comprehensive:** Creates TodoWrite plan covering all documentation aspects (overview, installation, API, architecture, etc.), processes each aspect sequentially

**Examples:**
```
/docs                    # Document recent changes
/docs src/auth           # Document authentication module
/docs API                # Document all API endpoints
/docs README             # Update only README.md
/docs config             # Document configuration options
/docs UserService        # Document specific class/service
/docs all                # Full documentation audit with planning
```

### /tester

Verify and create test coverage.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/tester` | Test recent changes |
| Scoped | `/tester <scope>` | Test specific area (file, module, feature) |
| Comprehensive | `/tester all` | Complete test coverage audit with TodoWrite planning |

**What it does:**
- **Default:** Identifies recently modified files and ensures test coverage
- **Scoped:** Tests only specified area (file, module, or feature)
- **Comprehensive:** Creates TodoWrite plan covering all testing aspects (unit, integration, API, components, edge cases), processes each sequentially

**Examples:**
```
/tester                      # Test recent changes
/tester src/auth             # Test authentication module
/tester utils/parser.ts      # Test specific file
/tester API endpoints        # Test all API routes
/tester UserService          # Test specific class/service
/tester all                  # Full test audit with planning
```

### /pr-check

Review current PR against quality checklist before merging.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/pr-check` | Review current PR against full quality checklist |
| Focused | `/pr-check <focus>` | Review with emphasis on specific aspect |

**What it does:**
- Uses `gh pr view` and `gh pr diff` to analyze the current PR
- Evaluates against quality checklist: tests, secrets, error handling, breaking changes, commits, docs
- Produces pass/fail report with overall verdict (Ready to Merge / Changes Required)
- **Focused mode:** Prioritizes specified aspect while still checking other items

**Examples:**
```
/pr-check                # Full quality review
/pr-check tests          # Focus on test coverage and quality
/pr-check security       # Focus on secrets, auth, input validation
/pr-check docs           # Focus on documentation completeness
/pr-check breaking       # Focus on breaking changes and migration
```

### /security-review

Perform security-focused code review.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/security-review` | Review recent changes for security vulnerabilities |
| Scoped | `/security-review <path>` | Review specific file/module for security issues |
| Comprehensive | `/security-review all` | Complete security audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent commits for security vulnerabilities
- **Scoped:** Deep security review of specified file/module
- **Comprehensive:** Creates TodoWrite plan covering all security areas (auth, authorization, input validation, data exposure, secrets, crypto, API, files, dependencies, config), processes each thoroughly

**Security Focus:**
- Authentication & Authorization (login, session, access control, privilege escalation)
- Input Validation (SQL injection, XSS, command injection, path traversal)
- Data Exposure (PII leaks, logs, error messages)
- Secrets Management (hardcoded credentials, API keys, tokens)
- Cryptography (weak algorithms, key management)
- OWASP Top 10 coverage

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Examples:**
```
/security-review                  # Review recent changes
/security-review src/auth         # Deep review of authentication module
/security-review api/handlers     # Review API endpoints
/security-review lib/payment.ts   # Review specific file
/security-review controllers/     # Review all controllers
/security-review all              # Comprehensive security audit with planning
```

### /changelog

Generate or update changelog, or create release notes.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/changelog` | Update CHANGELOG.md from git history (Keep a Changelog format) |
| Release | `/changelog release` | Generate user-friendly release notes for latest version |
| Versioned | `/changelog <version>` | Generate release notes for specific version or range |

**What it does:**
- **Default:** Updates or creates CHANGELOG.md using Keep a Changelog format, includes all versions from git tags plus [Unreleased] section
- **Release mode:** Generates announcement-style release notes from last tag to HEAD, formatted for GitHub releases or announcements
- **Versioned mode:** Generates release notes for specific version or version range

**Agent Dispatch:**
- `/changelog` → `changelog-generator` agent (CHANGELOG.md file)
- `/changelog release` → `release-notes` agent (release announcement markdown)
- `/changelog <version>` → `release-notes` agent (version-specific notes)

**Examples:**
```
/changelog                # Update CHANGELOG.md
/changelog release        # Generate GitHub release notes for latest version
/changelog 2.0.0          # Generate notes for version 2.0.0
/changelog 1.5.0..2.0.0   # Generate notes for version range
```

### strategic-compact

Hook that suggests context compaction at logical intervals.

**Why Manual Compaction:**
- Auto-compact happens at arbitrary points, often mid-task
- Strategic compacting preserves context through logical phases
- Compact after exploration, before execution

**Trigger Points:**
- After 50 tool calls (configurable via `COMPACT_THRESHOLD`)
- Every 25 calls thereafter

## Global Conventions

The `.claude/CLAUDE.md` file contains conventions applied to all projects when this config is used:

- No AI attribution in commits
- Conventional commits format
- Tags without `v` prefix
- camelCase for JSON field names
- Check available skills/agents when planning tasks

## Adding Extensions

### New Agent

1. Create `.claude/agents/<name>.md`:
   ```yaml
   ---
   name: agent-name
   description: "When to invoke..."
   model: sonnet  # optional
   color: blue    # optional
   ---

   [Agent persona, responsibilities, workflow]
   ```

2. Agent is available via `Task` tool with `subagent_type="<name>"`

### New Skill

1. Create `.claude/skills/<name>/SKILL.md`:
   ```yaml
   ---
   name: skill-name
   description: When to use this skill
   ---

   [Invocation modes, dispatch logic, examples]
   ```

2. Skill is available as `/<name>` command

### New Hook

Add to `.claude/settings.json`:
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

## Contributing

1. Follow existing patterns for agents/skills
2. Use conventional commits
3. Update CLAUDE.md when adding new extensions
4. Test skills before committing

## License

MIT
