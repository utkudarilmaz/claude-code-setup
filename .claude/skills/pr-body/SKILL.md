---
name: pr-body
description: This skill should be used when the user asks to "write a PR description", "update the PR body", "fix this PR description", "describe this PR", "write PR body", "improve the PR description", or "/pr-body". Writes short, plain-English pull request bodies and applies them with gh.
---

# PR Body Skill

## Purpose

Writes the description for a pull request and applies it. Dispatches to the `pr-body` agent, which reads the branch diff, commits, and any linked issue, then writes a short human-sounding body covering what changed and why.

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
Write What and Why sections, and Scope, Testing, and Next only when there
is something real to say.
Keep it under 200 words in plain simple English.
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
Write What and Why sections, and Scope, Testing, and Next only when there
is something real to say.
Keep it under 200 words in plain simple English.
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
Keep it under 200 words in plain simple English."
```

### Refresh: `/pr-body refresh`

Update an existing body against new commits, keeping the author's own writing.

```
Task tool with subagent_type="pr-body"
prompt: "Refresh the existing body of the current branch's PR.
Read the current body first. Keep everything the author wrote by hand:
review notes, screenshots, checklists, deploy steps, and any section not
in the template. Preserve their heading style.
Update only the parts the new commits made stale.
If the current body is empty or a bare template, write a fresh one.
Apply it with gh pr edit and print the PR URL."
```

## Body Shape

| Section | Required | Content |
|---------|----------|---------|
| What | Yes | What the change does, in one to three sentences |
| Why | Yes | The problem or reason behind it |
| Scope | Optional | Files or areas touched, one line each |
| Testing | Optional | What was actually run or verified |
| Next | Optional | Follow-up work left out on purpose |

Optional sections are dropped entirely when empty. No "N/A" placeholders.

## Rules

- Plain simple English, under 200 words
- No emoji, no bold-label bullets, no AI attribution footer
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
