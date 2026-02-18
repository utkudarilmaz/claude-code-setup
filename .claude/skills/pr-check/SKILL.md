---
name: pr-check
description: This skill should be used when the user asks to "review my PR", "check if PR is ready", "run PR checklist", "verify PR quality", "review pull request", or "/pr-check". Reviews test coverage, secrets, error handling, and documentation against a quality checklist.
---

# PR Check Skill

## Purpose

Dispatch the pr-check agent to review a PR against quality standards. The agent verifies test coverage, checks for secrets, validates error handling, ensures documentation is updated, and produces a pass/fail report with recommendations.

## When to Invoke

Invoke this skill:

- Before merging a PR
- After addressing review comments
- For final verification before merge
- With specific focus for targeted review (tests, security, docs)

## Invocation Modes

### Default: `/pr-check`

Review the current PR against the full quality checklist.

```
Task tool with subagent_type="pr-check"
prompt: "Review the current PR against the quality checklist.
Use gh pr view and gh pr diff to gather context.
Evaluate: tests, secrets, error handling, breaking changes, commits, docs."
```

### Scoped: `/pr-check <focus>`

Review the PR with emphasis on a specific aspect.

```
Task tool with subagent_type="pr-check"
prompt: "Review the current PR with focus on: [focus]
Use gh pr view and gh pr diff to gather context.
Prioritize [focus] in your review while still checking other items."
```

**Focus examples:**
- `/pr-check tests` - focus on test coverage and quality
- `/pr-check security` - focus on secrets, auth, input validation
- `/pr-check docs` - focus on documentation completeness
- `/pr-check breaking` - focus on breaking changes and migration

## Usage Examples

```
/pr-check                # Full quality checklist review
/pr-check tests          # Deep dive on test coverage
/pr-check security       # Focus on secrets and auth
/pr-check docs           # Focus on documentation
```
