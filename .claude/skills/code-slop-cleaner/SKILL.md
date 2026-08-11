---
name: code-slop-cleaner
description: This skill should be used when the user asks to "check if this change was necessary", "what in this diff is not needed", "did this change do too much", "find the scope creep", "clean up this change", "is all of this required", or "/code-slop-cleaner". Judges a diff against its stated purpose and separates needed work from the rest.
---

# Code Slop Cleaner Skill

## Purpose

Checks whether a change needed to happen. Dispatches to the `code-slop-cleaner` agent, which reads the purpose behind a change from its issue, pull request body, or commits, then classifies every part of the diff as required, supporting, unnecessary, or belonging to a different change.

Reports by default. `apply` removes the unnecessary parts and runs the tests.

Different from `/simplifier`. That one asks whether code is well written. This one asks whether it needed to be written.

## When to Invoke

Invoke this skill:

- Before opening a pull request, to catch work that crept in
- When a diff is much larger than the task it came from
- After a generated change, where defensive code and abstractions accumulate
- When a review comment says the change does too much

## The Purpose Gate

The agent reads the purpose from the linked issue, the pull request body, or the commit messages, in that order. **If it cannot find one, it stops and asks.**

This is deliberate. A purpose guessed from the diff makes every line in that diff look necessary, and the review returns nothing. Give it a purpose, or answer its question.

## Invocation Modes

### Default: `/code-slop-cleaner`

Review the uncommitted changes.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the uncommitted changes for work that does not serve
the purpose of the change.
Establish the purpose first from the linked issue, the branch commits,
or the user's own description. If no purpose can be found, stop and ask.
Do not infer the purpose from the diff itself.
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Verify every suspicion with a search before reporting it. Name the
existing helper, the caller, or the guarantee you found.
Report only. Change nothing.
Consult references/change-patterns.md for the pattern list."
```

### Scoped: `/code-slop-cleaner <path>`

Review only the changes under a path.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the changes under: [path]
Establish the purpose first from the linked issue, the branch commits,
or the user's own description. If no purpose can be found, stop and ask.
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Verify every suspicion with a search before reporting it.
Report only. Change nothing.
Consult references/change-patterns.md for the pattern list."
```

**Scope examples:**
- `/code-slop-cleaner src/auth` - only the auth changes
- `/code-slop-cleaner internal/queue/retry.go` - one file

### Pull request: `/code-slop-cleaner <number|url>`

Review a pull request's diff.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the diff of pull request: [number or url]
Resolve it with gh pr view. Read the body and any linked issue for the
purpose. Fall back to the commit messages. If no purpose can be found,
stop and ask.
Diff against that PR's base branch.
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Verify every suspicion with a search before reporting it.
Report only. Do not post comments and do not change the PR.
Consult references/change-patterns.md for the pattern list."
```

### Branch: `/code-slop-cleaner branch`

Review the whole branch against the default branch.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the whole current branch against the default branch.
Establish the purpose from the linked issue, the open PR body, or the
branch commits. If no purpose can be found, stop and ask.
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Pay attention to work added in later commits that the original purpose
does not cover. Prefer UNRELATED over UNNECESSARY when the work is
useful but belongs elsewhere.
Report only. Change nothing.
Consult references/change-patterns.md for the pattern list."
```

### Apply: `/code-slop-cleaner apply`

Remove the unnecessary parts and verify.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the uncommitted changes, then remove what is unnecessary.
Establish the purpose first. If no purpose can be found, stop and ask.
Classify every unit. Remove only the UNNECESSARY ones, smallest blast
radius first. Never remove UNRELATED work.
Then find the project's test command from its build files or docs and
run it.
If the tests pass, report what was removed and the lines saved.
If they fail, report the failure with its output and name the removal
that most likely caused it. Never claim a test run you did not perform."
```

## Classification

| Class | Meaning | Action |
|-------|---------|--------|
| REQUIRED | The purpose fails without it | Keep |
| SUPPORTING | Needed to ship the required work: tests, a migration, an import | Keep |
| UNNECESSARY | Serves nothing, and nothing depends on it | Remove |
| UNRELATED | Real work, wrong change | Split out |

UNRELATED is not criticism. The work is fine and belongs in its own commit.

## Rules

- The purpose comes first. No purpose means the agent asks rather than guesses
- Every finding is verified by a search before it is reported
- Tests for new behaviour are never flagged
- Error handling at real input and output boundaries is never flagged
- Unrelated work is never removed, only named
- Style, naming, and formatting are out of scope. Use `/simplifier` for those
- Only `apply` changes files. Every other mode reports

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/code-slop-cleaner` | `code-slop-cleaner` | Report on the uncommitted changes |
| `/code-slop-cleaner <path>` | `code-slop-cleaner` | Report scoped to a path |
| `/code-slop-cleaner <number\|url>` | `code-slop-cleaner` | Report on a pull request diff |
| `/code-slop-cleaner branch` | `code-slop-cleaner` | Report on the whole branch |
| `/code-slop-cleaner apply` | `code-slop-cleaner` | Unnecessary units removed, tests run |

## Usage Examples

```
/code-slop-cleaner            # Report on the uncommitted changes
/code-slop-cleaner src/auth   # Report on the auth changes only
/code-slop-cleaner 142        # Report on PR 142
/code-slop-cleaner branch     # Report on the whole branch
/code-slop-cleaner apply      # Remove what is unnecessary, then test
```

## Additional Resources

### Reference Files

- **`references/change-patterns.md`** - the pattern list, what to verify before flagging each one, and the never flag list
