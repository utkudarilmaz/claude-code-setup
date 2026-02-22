---
name: release-tag
description: This skill should be used when the user asks to "create a release tag", "bump version", "tag a release", "release major/minor/patch", "bump major", "bump minor", "bump patch", "create version tag", or "/release-tag". Bumps semantic version, invokes changelog, and creates annotated git tag.
---

# Release Tag Skill

## Purpose

Bump a semantic version tag, update CHANGELOG.md via the `/changelog` skill, and create an annotated git tag with a commit summary message. Handles initial tagging from `0.0.0` when no tags exist.

## Invocation

### `/release-tag <major|minor|patch>`

A bump type argument is **required**. Reject invocation without one.

```
/release-tag patch   # 1.2.3 -> 1.2.4
/release-tag minor   # 1.2.3 -> 1.3.0
/release-tag major   # 1.2.3 -> 2.0.0
```

## Workflow

Execute these steps sequentially:

### Step 1: Determine current version

```bash
git tag --sort=-version:refname | head -1
```

If no tags exist, use `0.0.0` as the base version.

### Step 2: Calculate new version

Parse the current version into `major.minor.patch` components and apply the bump:

| Bump type | Rule |
|-----------|------|
| `patch` | Increment patch, keep major and minor |
| `minor` | Increment minor, reset patch to 0, keep major |
| `major` | Increment major, reset minor and patch to 0 |

Report to the user: `Bumping <current> -> <new>`

### Step 3: Verify clean working tree

```bash
git status --porcelain
```

If the working tree has uncommitted changes, **stop and report** the issue. Do not proceed with a dirty tree. The user must commit or stash changes first.

### Step 4: Invoke changelog

Use the Skill tool to invoke `/changelog`. This updates CHANGELOG.md with the latest changes.

After changelog completes, stage and commit the changelog update:

```bash
git add CHANGELOG.md
git commit -m "docs: update changelog for <new-version>"
```

### Step 5: Build tag message

Gather commits since the last tag (or all commits if no previous tag):

```bash
git log <last-tag>..HEAD --oneline
# or if no previous tag:
git log --oneline
```

Group commits by conventional commit type (feat, fix, docs, refactor, etc.) for the tag message. Format as a readable summary.

### Step 6: Create annotated tag

```bash
git tag -a <new-version> -m "<tag-message>"
```

Report success: `Created tag <new-version>`

Remind the user to push the tag when ready: `git push origin <new-version>`

## Rules

- **No "v" prefix**: Tags are `1.0.0`, never `v1.0.0`
- **Annotated tags only**: Always use `git tag -a`, never lightweight tags
- **Clean tree required**: Refuse to tag with uncommitted changes (step 3)
- **Changelog first**: Always invoke `/changelog` before creating the tag (step 4)
- **No auto-push**: Never push automatically; remind the user to push manually
- **No AI attribution**: Never add Co-Authored-By or AI references to the changelog commit
- **Bump argument required**: Reject invocation without `major`, `minor`, or `patch`
