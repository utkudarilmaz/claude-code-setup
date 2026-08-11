---
name: pr-body
description: This skill should be used when the user asks to "write a PR description", "update the PR body", "fix this PR description", "describe this PR", "write PR body", "improve the PR description", or "/pr-body". Writes short, plain-English pull request bodies and applies them with gh.
---

# PR Body Skill

## Purpose

Writes the description for a pull request and applies it. Dispatches to the `pr-body` agent, which reads the branch diff, commits, and any linked issue, then writes a short human-sounding body covering what changed and why.

Plain and short is the default in every mode. The agent writes the smallest body a reviewer can act on and cuts the rest; there is no separate mode for that.

Writing only. This skill never creates a PR and never pushes commits. Use `/commit-commands:commit-push-pr` for that.

## When to Invoke

Invoke this skill:

- After opening a PR with an empty or thin description
- When an existing PR body no longer matches the code
- When a PR body reads as generated and needs rewriting
- Before asking for review, so reviewers know what to look at

## Invocation Modes

### Default: `/pr-body`

Write and apply the body for the current branch's open PR.

```
Task tool with subagent_type="pr-body"
prompt: "Write the PR body for the current branch's open PR.
Resolve the PR with gh pr view. Read the commits and diff against the
base branch, plus any linked issue.
Write What, Why, and Files sections. Add Testing and Next only when there
is something real to say.
What and Why are one or two plain sentences each.
Build Files from git diff --name-status -M, grouped Added, Changed, and
Removed. List every file, never truncate. Add a note next to a file only
when the path alone leaves a reviewer guessing.
Keep the prose under 120 words in plain simple English, then cut anything
the Files list already shows.
Apply it with gh pr edit and print the PR URL.
Stop with a one-line message if there is no open PR for this branch."
```

### Targeted: `/pr-body <number|url>`

Write and apply the body for a specific PR.

```
Task tool with subagent_type="pr-body"
prompt: "Write the PR body for PR: [number or url]
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
Apply it with gh pr edit and print the PR URL."
```

**Scope examples:**
- `/pr-body 142` - rewrite the body of PR 142
- `/pr-body https://github.com/owner/repo/pull/142` - same, by URL

### Draft: `/pr-body draft`

Write the body and print it without touching GitHub.

```
Task tool with subagent_type="pr-body"
prompt: "Draft the PR body for the current branch. Print it and stop.
Do not call gh pr edit and do not modify the PR.
If there is no open PR, diff against the default branch and still print
a draft.
Write What, Why, and Files sections. Add Testing and Next only when there
is something real to say.
What and Why are one or two plain sentences each.
Build Files from git diff --name-status -M, grouped Added, Changed, and
Removed. List every file, never truncate. Add a note next to a file only
when the path alone leaves a reviewer guessing.
Keep the prose under 120 words in plain simple English, then cut anything
the Files list already shows."
```

### Refresh: `/pr-body refresh`

Update an existing body against new commits, keeping the author's own writing.

```
Task tool with subagent_type="pr-body"
prompt: "Refresh the existing body of the current branch's PR.
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
Apply it with gh pr edit and print the PR URL."
```

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

## Rules

- Plain simple English, under 120 words of prose; the Files list is exempt and always complete
- Short is the default in every mode, including refresh
- No emoji, no bold-label bullets in prose, no AI attribution footer
- No invented test results or made-up rationale
- Default, targeted, and refresh modes apply the body without asking; use `draft` to review first

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/pr-body` | `pr-body` | Body applied to current branch's PR |
| `/pr-body <number\|url>` | `pr-body` | Body applied to the named PR |
| `/pr-body draft` | `pr-body` | Body printed to the terminal only |
| `/pr-body refresh` | `pr-body` | Existing body updated, author's notes kept |

## Usage Examples

```
/pr-body           # Write and apply the body for this branch's PR
/pr-body 142       # Rewrite the body of PR 142
/pr-body draft     # Print a draft, change nothing
/pr-body refresh   # Update the body, keep hand-written notes
```
