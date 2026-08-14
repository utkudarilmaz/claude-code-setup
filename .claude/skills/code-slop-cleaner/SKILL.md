---
name: code-slop-cleaner
description: This skill should be used when the user asks to "check if this change was necessary", "does this PR match the ticket", "is anything missing from this change", "did this implement everything", "what in this diff is not needed", "did this change do too much", "find the scope creep", "is all of this required", or "/code-slop-cleaner". Judges a diff against its ticket or stated purpose in both directions and separates needed work, extra work, and missing work.
---

# Code Slop Cleaner Skill

## Purpose

Checks whether a change matches its scope in both directions. Dispatches to the `code-slop-cleaner` agent, which reads the scope from a ticket, pull request body, or commits, extracts a numbered requirement list, then classifies every part of the diff as required, supporting, unnecessary, or belonging to a different change, and gives every requirement a status of covered, partial, or missing.

Reports by default. `apply` removes the unnecessary parts and runs the tests. Missing work is never written, only reported.

Different from `/simplifier`. That one asks whether code is well written. This one asks whether it needed to be written, and whether everything asked for was written.

## When to Invoke

Invoke this skill:

- Before opening a pull request, to catch work that crept in
- When a diff is much larger than the task it came from
- After a generated change, where defensive code and abstractions accumulate
- When a review comment says the change does too much
- Before closing a ticket, to check every requirement made it into the change

## Context Injection

The agent starts fresh and cannot see this conversation. Before dispatching, copy into the prompt any scope context already present in the session: a ticket URL the user mentioned, pasted requirements or acceptance criteria, or the purpose the user stated when asking for the change. Without this, a bare `/code-slop-cleaner` drops context the user already gave.

## The Scope Gate

The agent reads the scope from pasted ticket text, an explicit ticket URL, the linked issue, the pull request body, or the commit messages, in that order. Jira, Linear, and other tracker URLs are fetched with WebFetch; if the tracker needs auth, the agent asks for the ticket text. **If it cannot find any scope, it stops and asks.**

This is deliberate. A scope guessed from the diff makes every line look necessary and every requirement look delivered, and the review returns nothing. Give it a scope, or answer its question.

## Invocation Modes

### Default: `/code-slop-cleaner`

Review the uncommitted changes.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the uncommitted changes against the scope of the change,
in both directions.
Establish the scope first: any ticket context included below, then the
linked issue, the PR body, or the branch commits. If no scope can be
found, stop and ask. Do not infer the scope from the diff itself.
Extract a numbered requirement list from the scope.
[Include here any ticket URL, pasted requirements, or stated purpose
from the current session.]
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Give every requirement a status: COVERED, PARTIAL, or MISSING. Before
calling one missing, search the codebase for an existing implementation.
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
Establish the scope first: any ticket context included below, then the
linked issue, the PR body, or the branch commits. If no scope can be
found, stop and ask. Do not infer the scope from the diff itself.
Extract a numbered requirement list from the scope.
[Include here any ticket URL, pasted requirements, or stated purpose
from the current session.]
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Give every requirement a status: COVERED, PARTIAL, or MISSING. Before
calling one missing, search the codebase for an existing implementation.
Judge coverage only for requirements the path can contain; say so when
a requirement lives outside the reviewed path.
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
scope. Fetch external ticket links with WebFetch. Fall back to the
commit messages. If no scope can be found, stop and ask.
Extract a numbered requirement list from the scope.
[Include here any ticket URL, pasted requirements, or stated purpose
from the current session.]
Diff against that PR's base branch.
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Give every requirement a status: COVERED, PARTIAL, or MISSING. Before
calling one missing, search the codebase for an existing implementation.
Verify every suspicion with a search before reporting it.
Report only. Do not post comments and do not change the PR.
Consult references/change-patterns.md for the pattern list."
```

### Ticket: `/code-slop-cleaner <ticket-url>`

Review the current changes against an explicit ticket. A github.com URL or bare number is treated as a pull request; any other URL is a ticket.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the uncommitted changes (or the branch if there are
none) against this ticket: [url]
Fetch the ticket with WebFetch. If the tracker needs auth and the fetch
fails, stop and ask the user to paste the ticket text.
Extract a numbered requirement list from the ticket.
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Give every requirement a status: COVERED, PARTIAL, or MISSING. Before
calling one missing, search the codebase for an existing implementation.
Verify every suspicion with a search before reporting it.
Report only. Change nothing.
Consult references/change-patterns.md for the pattern list."
```

### Pull request with ticket: `/code-slop-cleaner <pr> <ticket-url>`

Review a pull request against an explicit ticket instead of its linked issue.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the diff of pull request [number or url] against this
ticket: [ticket url]
Resolve the PR with gh pr view and diff against its base branch.
Fetch the ticket with WebFetch. If the tracker needs auth and the fetch
fails, stop and ask the user to paste the ticket text.
Extract a numbered requirement list from the ticket.
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Give every requirement a status: COVERED, PARTIAL, or MISSING. Before
calling one missing, search the codebase for an existing implementation.
Verify every suspicion with a search before reporting it.
Report only. Do not post comments and do not change the PR.
Consult references/change-patterns.md for the pattern list."
```

### Branch: `/code-slop-cleaner branch`

Review the whole branch against the default branch.

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the whole current branch against the default branch.
Establish the scope first: any ticket context included below, then the
linked issue, the open PR body, or the branch commits. If no scope can
be found, stop and ask. Do not infer the scope from the diff itself.
Extract a numbered requirement list from the scope.
[Include here any ticket URL, pasted requirements, or stated purpose
from the current session.]
Group the diff into units by concern. Classify each as REQUIRED,
SUPPORTING, UNNECESSARY, or UNRELATED.
Give every requirement a status: COVERED, PARTIAL, or MISSING. Before
calling one missing, search the codebase for an existing implementation.
Pay attention to work added in later commits that the original scope
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
Establish the scope first: any ticket context included below, then the
linked issue, the PR body, or the branch commits. If no scope can be
found, stop and ask.
Extract a numbered requirement list from the scope.
[Include here any ticket URL, pasted requirements, or stated purpose
from the current session.]
Classify every unit. Give every requirement a status: COVERED, PARTIAL,
or MISSING. Before calling one missing, search the codebase for an
existing implementation.
Remove only the UNNECESSARY ones, smallest blast radius first. Never
remove UNRELATED work. Never write missing features. Report MISSING
and PARTIAL requirements only.
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

Requirements get their own status:

| Status | Meaning |
|--------|---------|
| COVERED | A unit implements it |
| PARTIAL | Partly implemented; the report says what is missing |
| MISSING | Nothing in the diff addresses it, verified by a search |

## Rules

- The scope comes first. No scope means the agent asks rather than guesses
- Every finding is verified by a search before it is reported
- A requirement is only MISSING after a codebase search comes up empty
- Missing work is reported, never written, in every mode including apply
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
| `/code-slop-cleaner <ticket-url>` | `code-slop-cleaner` | Report on the current changes against a ticket |
| `/code-slop-cleaner <pr> <ticket-url>` | `code-slop-cleaner` | Report on a pull request against a ticket |
| `/code-slop-cleaner branch` | `code-slop-cleaner` | Report on the whole branch |
| `/code-slop-cleaner apply` | `code-slop-cleaner` | Unnecessary units removed, tests run |

## Usage Examples

```
/code-slop-cleaner            # Report on the uncommitted changes
/code-slop-cleaner src/auth   # Report on the auth changes only
/code-slop-cleaner 142        # Report on PR 142
/code-slop-cleaner https://acme.atlassian.net/browse/APP-42   # Current changes vs ticket
/code-slop-cleaner 142 https://linear.app/acme/issue/APP-42   # PR 142 vs ticket
/code-slop-cleaner branch     # Report on the whole branch
/code-slop-cleaner apply      # Remove what is unnecessary, then test
```

## Additional Resources

### Reference Files

- **`references/change-patterns.md`** - the pattern list, what to verify before flagging each one, and the never flag list
