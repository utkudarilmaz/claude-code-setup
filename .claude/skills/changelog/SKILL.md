---
name: changelog
description: This skill should be used when the user asks to "generate changelog", "update changelog", "create release notes", "prepare release documentation", "what changed since last release", or "/changelog". Dispatches to changelog-generator or release-notes agents based on mode.
---

# Changelog Skill

## Purpose

Unified skill for changelog management and release note generation. Dispatches to different agents based on invocation mode: default mode uses the changelog-generator agent for CHANGELOG.md updates, and release mode uses the release-notes agent for announcement-style notes.

## When to Invoke

Invoke this skill:

- To update CHANGELOG.md with recent commits
- To generate release notes for GitHub releases or announcements
- Before tagging a new version
- When preparing release documentation

## Invocation Modes

### Default: `/changelog`

Update or create CHANGELOG.md using Keep a Changelog format.

```
Task tool with subagent_type="changelog-generator"
prompt: "Generate or update CHANGELOG.md from git history.
Use Keep a Changelog format. Include all versions from git tags.
Add [Unreleased] section for commits after latest tag."
```

### Release Mode: `/changelog release`

Generate user-friendly release notes for the latest version (since last tag).

```
Task tool with subagent_type="release-notes"
prompt: "Generate release notes from the last tag to HEAD.
Write from user perspective with emojis. Highlight breaking changes.
Format for GitHub release or announcement."
```

### Versioned: `/changelog <version>`

Generate release notes for a specific version or range.

```
Task tool with subagent_type="release-notes"
prompt: "Generate release notes for version: [version]
Write from user perspective. Highlight breaking changes.
Format for GitHub release or announcement."
```

**Scope examples:**
- `/changelog 2.0.0` - notes for specific version
- `/changelog 1.5.0..2.0.0` - notes for version range

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/changelog` | `changelog-generator` | CHANGELOG.md file |
| `/changelog release` | `release-notes` | Release announcement |
| `/changelog <version>` | `release-notes` | Version-specific notes |

## Usage Examples

```
/changelog              # Update CHANGELOG.md from git history
/changelog release      # Generate GitHub release notes
/changelog 3.0.0        # Notes for specific version
```
