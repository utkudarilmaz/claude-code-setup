---
name: create-pr
description: This skill should be used when the user asks to "open a PR", "make a PR", "create a pull request", "commit and open a PR", "raise a PR for this branch", "write a PR description", "update the PR body", "fix this PR description", "describe this PR", or "/create-pr". Commits the pending work, pushes the branch, writes the title and body, sets the PR fields, and opens the pull request with gh.
---

# Create PR Skill

## Purpose

Takes a branch from wherever it is to an open pull request. Dispatches to the `create-pr` agent, which commits the pending work, pushes the branch, reads the branch diff and commits plus any linked issue, then writes a title and a short human-sounding body and opens the PR with `gh`.

Plain and short is the default in every mode. The agent writes the smallest body a reviewer can act on and cuts the rest; there is no separate mode for that.

This skill owns the whole path: commit, push, title, body, fields, creation. Use it instead of `/commit-commands:commit-push-pr`, which opens a PR without writing a real description. When the branch already has an open PR, the skill updates it rather than failing.

After the PR exists, the skill runs a cleanup pass over it: `pr-comment-cleaner` on the code comments, `text-slop-cleaner` on the PR text, and `code-slop-cleaner` on the scope. Every mode except `show` gets the pass, and `no-clean` skips it. See Cleanup Pass below.

## When to Invoke

Invoke this skill:

- When the work is done and the PR does not exist yet
- When the branch is pushed but nobody opened a PR for it
- When an existing PR body no longer matches the code
- When a PR title or body reads as generated and needs rewriting

## Invocation Modes

### Default: `/create-pr`

Commit, push, and open the PR for the current branch.

```
Task tool with subagent_type="create-pr"
prompt: "Open the pull request for the current branch, end to end.
Run the preflight checks. Read the branch, the working tree state, the
repository default branch, and any existing PR. If a PR already exists,
switch to the update path instead of creating one.
If the current branch is the default branch, create a type/short-slug
branch first. If the tree is dirty, print the files you will stage and
the conventional commit message, then commit. Push with git push -u.
Write a conventional commit style title under 70 characters.
Write What, Why, and Files sections. Add Testing and Next only when there
is something real to say.
What and Why are one or two plain sentences each.
Build Files from git diff --name-status -M, grouped Added, Changed, and
Removed. List every file, never truncate. Add a note next to a file only
when the path alone leaves a reviewer guessing.
Keep the prose under 120 words in plain simple English, then cut anything
the Files list already shows.
Set the base branch and assignee. Add reviewers, labels, and a milestone
only when the field rules say so.
Create the PR with gh pr create and print the URL."
```

### Draft: `/create-pr draft`

Same as default, opened as a GitHub draft PR.

```
Task tool with subagent_type="create-pr"
prompt: "Open the pull request for the current branch as a draft, end to
end. Follow the default flow: preflight, branch if needed, commit if the
tree is dirty, push with git push -u, write the title and body, set the
fields, then create the PR with gh pr create --draft.
Write a conventional commit style title under 70 characters.
Write What, Why, and Files sections. Add Testing and Next only when there
is something real to say.
Build Files from git diff --name-status -M, grouped Added, Changed, and
Removed. List every file, never truncate.
Keep the prose under 120 words in plain simple English.
Print the URL and say it was opened as a draft."
```

### Show: `/create-pr show`

Print the title and body without touching git or GitHub.

```
Task tool with subagent_type="create-pr"
prompt: "Print the title and body for the current branch's pull request,
then stop. Change nothing.
Do not commit, do not push, do not call gh pr create or gh pr edit.
If there is no open PR, diff against the default branch and still print a
title and body.
Write a conventional commit style title under 70 characters.
Write What, Why, and Files sections. Add Testing and Next only when there
is something real to say.
Build Files from git diff --name-status -M, grouped Added, Changed, and
Removed. List every file, never truncate. Add a note next to a file only
when the path alone leaves a reviewer guessing.
Keep the prose under 120 words in plain simple English, then cut anything
the Files list already shows.
Also print the fields you would set, and stop."
```

### Refresh: `/create-pr refresh`

Update the existing PR against new commits, keeping the author's own writing.

```
Task tool with subagent_type="create-pr"
prompt: "Refresh the current branch's existing PR.
Read the current body first. Keep everything the author wrote by hand:
review notes, screenshots, checklists, deploy steps, and any section not
in the template. Keep their wording and heading style.
Rewrite the template sections to the short default shape: give a stale
section the new facts, and cut a padded but accurate one down to one or
two plain sentences.
Always rebuild the Files section from the current diff, carrying over the
author's per-file notes for files still in it. Add a Files section if the
body has none.
If the current body is empty or a bare template, write a fresh one.
Replace the title only when it is vague or no longer matches the commits.
Apply it with gh pr edit and print the PR URL."
```

### Targeted: `/create-pr <number|url>`

Update the title and body of a specific PR.

```
Task tool with subagent_type="create-pr"
prompt: "Update the title and body of PR: [number or url]
Resolve it with gh pr view [number]. Read the commits and diff against
that PR's base branch, plus any linked issue.
Write What, Why, and Files sections. Add Testing and Next only when there
is something real to say.
What and Why are one or two plain sentences each.
Build Files from git diff --name-status -M, grouped Added, Changed, and
Removed. List every file, never truncate. Add a note next to a file only
when the path alone leaves a reviewer guessing.
Keep the prose under 120 words in plain simple English, then cut anything
the Files list already shows.
Replace the title only when it is vague or no longer matches the commits.
Apply it with gh pr edit and print the PR URL."
```

**Scope examples:**
- `/create-pr 142` - update PR 142
- `/create-pr https://github.com/owner/repo/pull/142` - same, by URL

### Extra Instructions

Anything typed after the mode is passed to the agent as plain text:

- `/create-pr base develop` - open the PR against `develop`
- `/create-pr draft reviewer alice` - draft PR with alice requested
- `/create-pr label bug milestone 2.1` - set an existing label and milestone
- `/create-pr no-clean` - open the PR and skip the cleanup pass

## Cleanup Pass

The `create-pr` agent cannot dispatch other agents, so this pass runs here, after that agent returns. Run it once per PR the run created or updated. Skip it in `show` mode, when the run stopped before a PR existed, or when the user typed `no-clean`.

Take the PR number from the URL the `create-pr` agent printed, then dispatch these three agents. When the run worked on the current branch (default, draft, refresh), send all three in the same turn so they run concurrently; they touch different surfaces and do not collide. When the run targeted another PR by number or URL, run `pr-comment-cleaner` first, since it checks the PR branch out, and send the other two together after it finishes.

**1. Code comments** (edits files, leaves them uncommitted):

```
Task tool with subagent_type="pr-comment-cleaner"
prompt: "Clean the code comments in pull request: [number]
Resolve the PR with gh pr view. If the current branch is already the
PR's branch, work in place; otherwise stop with a one line message if
the working tree has uncommitted changes and check the PR out with
gh pr checkout.
Work only on files in the PR's diff, and only on comment lines in
them. Remove comments that are not 100% necessary, verifying each
against the code it describes before cutting. Removal is the
default: a comment that is merely accurate or helpful goes, and one
stays only when you can name the fact the code cannot give back.
Rewrite kept comments that are stale or padded. Never touch
protected content, code, or string literals.
Apply the edits directly, then review your own git diff to confirm
only comment lines in scoped files changed. Never commit, push, or
stash. Report removed, rewritten, kept, and protected comments.
Consult references/comment-necessity.md for the full pattern list."
```

**2. PR text** (edits the body and own comments through gh):

```
Task tool with subagent_type="text-slop-cleaner"
prompt: "Clean the text on pull request: [number]
Read the body and every comment with gh pr view and gh api.
Separate your own comments from other people's before changing anything.
Rewrite the body and your own comments into plain English, and apply
them with gh pr edit and gh api.
Never edit another person's comment. GitHub does not allow it. List
what reads as slop in theirs and leave it alone.
Report what changed and what was reported only."
```

**3. Scope** (report only):

```
Task tool with subagent_type="code-slop-cleaner"
prompt: "Review the diff of pull request: [number]
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

After all three return, give the user one combined summary: the PR URL, what each cleaner changed or found, and a reminder that any comment edits from `pr-comment-cleaner` sit uncommitted on the branch, waiting for the user to commit and push. Never commit or push them on the user's behalf.

## Body Shape

| Section | Required | Content |
|---------|----------|---------|
| What | Yes | What the change does, in one or two sentences |
| Why | Yes | The problem or reason behind it, in one or two sentences |
| Files | Yes | Every changed file, grouped Added / Changed / Removed |
| Testing | Optional | What was actually run or verified |
| Next | Optional | Follow-up work left out on purpose |

Optional sections are dropped entirely when empty. No "N/A" placeholders.

The prose stays under 120 words across all sections. A big change does not earn a longer body: the Files list carries the detail.

### Files Section

Built from `git diff --name-status -M` against the PR's base branch:

```markdown
## Files

**Added**
- `webhooks/retry.go` - backoff helper

**Changed**
- `webhooks/stripe.go` - wraps the handler in retry
- `webhooks/stripe_test.go`

**Removed**
- `webhooks/legacy_retry.go` - replaced by the new helper
```

- Every file is listed. No truncation, no "and 12 more", no directory rollups
- Only groups with files appear
- Paths are relative to the repository root, sorted within each group
- Renames show as one line under **Changed**: `` `old` - renamed to `new` ``
- A file gets a note only when its path leaves a reviewer guessing, and then a few words at most

## PR Fields

| Field | Set when |
|-------|----------|
| Base | Always. The repository default branch, or the branch the user named |
| Draft | `draft` mode, or the user says the work is unfinished |
| Assignee | Always, set to the author |
| Reviewer | The user names one, or a CODEOWNERS entry matches a changed file |
| Label | A label that already exists fits the change. Never created |
| Milestone | The user names one, or the linked issue carries one |

## Rules

- Plain simple English, under 120 words of prose; the Files list is exempt and always complete
- Short is the default in every mode, including refresh
- Title is conventional commit style, under 70 characters
- One commit per run unless the user asks for more, with a conventional commit message
- No emoji, no bold-label bullets in prose, no AI attribution footer
- No invented test results or made-up rationale
- Never force push, never commit on the default branch, never create labels
- Every mode except `show` applies its changes without asking; use `show` to review first

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/create-pr` | `create-pr` | Work committed, branch pushed, PR opened |
| `/create-pr draft` | `create-pr` | Same, opened as a draft PR |
| `/create-pr show` | `create-pr` | Title and body printed, nothing changed |
| `/create-pr refresh` | `create-pr` | Existing PR updated, author's notes kept |
| `/create-pr <number\|url>` | `create-pr` | Title and body updated on the named PR |

Every mode except `show` is followed by the cleanup pass, which dispatches `pr-comment-cleaner`, `text-slop-cleaner`, and `code-slop-cleaner` against the finished PR. `no-clean` after any mode skips it.

## Usage Examples

```
/create-pr                 # Commit, push, and open the PR
/create-pr draft           # Same, opened as a draft
/create-pr show            # Print the title and body, change nothing
/create-pr refresh         # Update the existing PR, keep hand-written notes
/create-pr 142             # Update the title and body of PR 142
/create-pr base develop    # Open the PR against develop
/create-pr no-clean        # Open the PR, skip the cleanup pass
```

## Additional Resources

### Reference Files

- **`references/pr-creation.md`** - preflight checks, branch naming, commit and push rules, title rules, field selection, and the exact gh commands
