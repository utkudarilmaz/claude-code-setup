---
name: pr-comment-cleaner
description: This skill should be used when the user asks to "clean the comments in this PR", "remove unnecessary comments from the PR", "check the PR for comment slop", "fix the comments in this diff", "enforce the comment rule on this branch", or "/pr-comment-cleaner". Removes code comments in a PR's changed files that are not 100% necessary and rewrites the ones that must stay.
---

# PR Comment Cleaner Skill

## Purpose

Enforces the rule that a comment which is not 100% necessary does not stay, across the files a pull request changes. Removal is the default outcome: a comment does not survive by being accurate or helpful, only by carrying a fact the code cannot give back. Dispatches to the `pr-comment-cleaner` agent, which resolves the PR, builds the list of changed files, verifies every removal against the code and every keep against that necessity test, applies the edits, and reviews its own diff to confirm only comment lines changed.

Applies changes directly and never commits or pushes; the edits stay uncommitted for the user to review and commit. Use `check` mode to see the report without touching anything.

Code comments only, inside the PR's diff only. This skill never edits GitHub review or discussion comments and never touches prose or markdown; that is `/text-slop-cleaner`'s job. It never judges code quality; that is `/simplifier`'s job. There is no repo-wide mode; whole-repository comment cleanup is `/text-slop-cleaner <path>`'s job.

## When to Invoke

Invoke this skill:

- Before asking for review on a PR
- After a session that generated code with narrating comments
- When a reviewer flags comment noise on a PR
- Before committing a branch built with an agent

## Invocation Modes

### Default: `/pr-comment-cleaner`

Clean the code comments in the current branch's pull request.

```
Task tool with subagent_type="pr-comment-cleaner"
prompt: "Clean the code comments in the current branch's pull request.
Resolve the PR with gh pr view. If no PR exists, use the diff of this
branch against its merge base with the default branch, including
uncommitted changes.
Work only on files in that diff, and only on comment lines in them.
Remove comments that are not 100% necessary, verifying each against
the code it describes before cutting. Removal is the default: a
comment that is merely accurate or helpful goes, and one stays only
when you can name the fact the code cannot give back. Rewrite kept
comments that are stale or padded. Never touch protected content,
code, or string literals.
Apply the edits directly, then review your own git diff to confirm
only comment lines in scoped files changed. Never commit, push, or
stash. Report removed, rewritten, kept, and protected comments.
Consult references/comment-necessity.md for the full pattern list."
```

### Pull request: `/pr-comment-cleaner <number|url>`

Check out a specific PR and clean its comments.

```
Task tool with subagent_type="pr-comment-cleaner"
prompt: "Clean the code comments in pull request: [number or url]
Stop with a one line message if the working tree has uncommitted
changes. Otherwise check the PR out with gh pr checkout.
Work only on files in the PR's diff, and only on comment lines in
them. Remove comments that are not 100% necessary, verifying each
against the code first. Removal is the default: a comment that is
merely accurate or helpful goes, and one stays only when you can
name the fact the code cannot give back. Rewrite kept comments that
are stale or padded. Never touch protected content, code, or string
literals.
Apply the edits directly and leave them uncommitted on the PR
branch. Never commit, push, stash, or switch back. Say in the
report that the repository is now on the PR branch.
Consult references/comment-necessity.md for the full pattern list."
```

### Scoped: `/pr-comment-cleaner <path>`

Clean only the PR's changed files under a path.

```
Task tool with subagent_type="pr-comment-cleaner"
prompt: "Clean the code comments in the current PR's changed files
under: [path]
Resolve the PR with gh pr view, falling back to the branch diff
against the merge base with the default branch. Intersect the diff's
file list with the given path; files outside either are out of
scope.
Remove comments that are not 100% necessary, verifying each against
the code first. Removal is the default: a comment that is merely
accurate or helpful goes, and one stays only when you can name the
fact the code cannot give back. Rewrite kept comments that are stale
or padded. Never touch protected content, code, or string literals.
Apply the edits directly. Never commit, push, or stash. Report
removed, rewritten, kept, and protected comments.
Consult references/comment-necessity.md for the full pattern list."
```

**Scope examples:**
- `/pr-comment-cleaner src/auth/` - only changed files under a directory
- `/pr-comment-cleaner cmd/server/main.go` - one changed file

### Check: `/pr-comment-cleaner check [number|url]`

Report what would change, without changing anything.

```
Task tool with subagent_type="pr-comment-cleaner"
prompt: "Report the unnecessary and stale code comments in [the
current branch's PR | pull request <number or url>]. Change nothing.
Do not edit any file, do not check out any branch, and do not run
any git command that writes. For a PR that is not checked out, read
its files with gh pr diff and gh api.
Removal is the default: a comment that is merely accurate or
helpful is a finding, and one survives only when you can name the
fact the code cannot give back.
For each finding show the comment, its file and line, whether this
PR introduced it, and the removal or the proposed rewrite, with the
verification that backs it. List protected comments left alone, and
for each comment you would keep name the fact that keeps it.
Consult references/comment-necessity.md for the full pattern list."
```

## Rules

- Only files in the PR's diff, and only comment lines in them. Never code, never string literals
- Removal is the default. A keep must name the fact the code cannot give back; accurate or helpful is not enough
- Every removal and rewrite is verified against the code first, by confirming the code already says what the comment says
- Protected content is never touched: lint directives, build markers, licence headers, required doc comments, pragma comments, sole statement docstrings
- Edits stay uncommitted. The agent never commits, pushes, or stashes; the user commits
- An explicit PR target requires a clean working tree and leaves the repository on the PR branch, stated in the report
- Default, pull request, and scoped modes apply without asking. Use `check` to review first

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/pr-comment-cleaner` | `pr-comment-cleaner` | Current PR's comments cleaned in place |
| `/pr-comment-cleaner <number\|url>` | `pr-comment-cleaner` | PR checked out, comments cleaned, left uncommitted |
| `/pr-comment-cleaner <path>` | `pr-comment-cleaner` | PR's changed files under the path cleaned |
| `/pr-comment-cleaner check [target]` | `pr-comment-cleaner` | Report only, nothing changed |

## Usage Examples

```
/pr-comment-cleaner              # Clean comments in the current branch's PR
/pr-comment-cleaner 142          # Check out PR 142 and clean its comments
/pr-comment-cleaner src/auth/    # Only PR-changed files under src/auth/
/pr-comment-cleaner check        # Report only, change nothing
/pr-comment-cleaner check 142    # Report on PR 142 without checking it out
```

## Additional Resources

### Reference Files

- **`references/comment-necessity.md`** - the full remove, rewrite, keep, and protected pattern list, with verification steps and before and after examples
