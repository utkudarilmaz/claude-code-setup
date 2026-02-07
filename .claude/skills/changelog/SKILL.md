---
name: changelog
description: This skill should be used when the user asks to "generate changelog", "update changelog", "create release notes", "prepare release documentation", "what changed since last release", or "/changelog". Dispatches to changelog-generator or release-notes agents based on mode.
---

# Changelog

## Overview

Unified skill for changelog management and release note generation. Dispatches to different agents based on invocation mode:

- **Default** → `changelog-generator` agent (updates CHANGELOG.md)
- **Release mode** → `release-notes` agent (generates announcement-style notes)

## When to Use

- To update CHANGELOG.md with recent commits
- To generate release notes for GitHub releases or announcements
- Before tagging a new version
- When preparing release documentation

## Invocation Modes

### Default: `/changelog`

Updates or creates CHANGELOG.md using Keep a Changelog format. Includes all versions and an [Unreleased] section.

```
Task tool with subagent_type="changelog-generator"
prompt: "Generate or update CHANGELOG.md from git history.
Use Keep a Changelog format. Include all versions from git tags.
Add [Unreleased] section for commits after latest tag."
```

**Output**: Updated CHANGELOG.md file

---

### Release Mode: `/changelog release`

Generates user-friendly release notes for the latest version (since last tag). Ideal for GitHub releases, announcements, or emails.

```
Task tool with subagent_type="release-notes"
prompt: "Generate release notes from the last tag to HEAD.
Write from user perspective with emojis. Highlight breaking changes.
Format for GitHub release or announcement."
```

**Output**: Standalone release notes markdown

---

### Versioned: `/changelog <version>`

Generates release notes for a specific version or range.

```
Task tool with subagent_type="release-notes"
prompt: "Generate release notes for version: [version]
Write from user perspective. Highlight breaking changes.
Format for GitHub release or announcement."
```

**Scope examples:**
- `/changelog 2.0.0` - notes for specific version
- `/changelog 1.5.0..2.0.0` - notes for version range

**Output**: Standalone release notes markdown

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/changelog` | `changelog-generator` | CHANGELOG.md file |
| `/changelog release` | `release-notes` | Release announcement |
| `/changelog <version>` | `release-notes` | Version-specific notes |

## Output Formats

### CHANGELOG.md (default mode)

```markdown
# Changelog

## [Unreleased]
### Added
- New feature

## [1.0.0] - 2024-01-15
### Added
- Initial release
```

### Release Notes (release mode)

```markdown
# Release Notes - 2.0.0

## 💥 Breaking Changes
- Migration required for X

## ✨ New Features
- Feature description

## 🐛 Bug Fixes
- Fixed issue Y
```

## Examples

**Update CHANGELOG.md:**
```
/changelog
→ Dispatches to changelog-generator, updates CHANGELOG.md
```

**Generate GitHub release notes:**
```
/changelog release
→ Dispatches to release-notes, generates announcement markdown
```

**Notes for specific version:**
```
/changelog 3.0.0
→ Dispatches to release-notes for version 3.0.0
```
