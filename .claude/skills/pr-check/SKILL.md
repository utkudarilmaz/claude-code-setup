---
name: pr-check
description: This skill should be used when the user asks to "review my PR", "check if PR is ready", "run PR checklist", "verify PR quality", "review pull request", or "/pr-check". Reviews test coverage, secrets, error handling, and documentation against a quality checklist.
---

# PR Check

## Overview

Dispatch the pr-check agent to review a PR against quality standards. The agent verifies test coverage, checks for secrets, validates error handling, and ensures documentation is updated.

## When to Use

- Before merging a PR
- After addressing review comments
- For final verification before merge
- When you want a second opinion on PR quality
- With specific focus for targeted review (tests, security, docs)

## Invocation Modes

### Default: `/pr-check`

Reviews the current PR against the full quality checklist.

```
Task tool with subagent_type="pr-check"
prompt: "Review the current PR against the quality checklist.
Use gh pr view and gh pr diff to gather context.
Evaluate: tests, secrets, error handling, breaking changes, commits, docs."
```

### Scoped: `/pr-check <focus>`

Reviews the PR with emphasis on a specific aspect.

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

## What the Agent Does

- Retrieves PR details via `gh pr view`
- Analyzes the diff via `gh pr diff`
- Evaluates each checklist item:
  - Tests added/updated for changes
  - No hardcoded secrets or credentials
  - Error handling is appropriate
  - Breaking changes are documented
  - Commit messages follow conventions
  - Documentation updated if needed
- Produces pass/fail report with explanations

## Quality Checklist

| Check | Criteria |
|-------|----------|
| Tests | New/modified code has corresponding tests |
| Secrets | No hardcoded passwords, API keys, tokens |
| Error Handling | Errors caught and handled appropriately |
| Breaking Changes | API/behavior changes documented |
| Commits | Follow conventional commit format |
| Documentation | README/docs updated if needed |
| Dependencies | New deps justified and secure |
| Code Quality | No obvious smells or anti-patterns |

## Examples

**Standard PR review:**
```
/pr-check
→ Runs full checklist, produces pass/fail report
```

**Security-focused review:**
```
/pr-check security
→ Prioritizes secrets, auth, input validation checks
```

**Test coverage review:**
```
/pr-check tests
→ Deep dive on test coverage, edge cases, test quality
```

## Output

The agent produces a markdown report with:
- Checklist results (PASS/FAIL/N/A for each item)
- Summary of findings
- Overall verdict (Ready to Merge / Changes Required)
- Recommendations for improvement
