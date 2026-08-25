---
name: text-slop-cleaner
description: This skill should be used when the user asks to "clean up this text", "remove the AI slop", "make this sound human", "humanize this", "rewrite this in plain English", "remove unnecessary comments", "strip the comments", "this reads like AI wrote it", or "/text-slop-cleaner". Rewrites machine sounding prose and removes every comment that is not 100% necessary.
---

# Text Slop Cleaner Skill

## Purpose

Turns machine sounding text into plain English, and removes every comment that is not 100% necessary. Dispatches to the `text-slop-cleaner` agent, which reads the target, rewrites padded prose, cuts unnecessary comments, and leaves protected content alone.

Two standards, applied to two different things. Prose is rewritten rather than deleted when it carries information. A comment stays only when the code cannot tell the reader what it says, and every removal is verified against that code first.

With no argument it works out its own target: the uncommitted changes, or the commits this branch has that the base does not, or the branch's open PR, whichever it finds first.

Applies changes directly. Use `check` mode to see the report without touching anything.

Text only. This skill never changes code behaviour and never edits string literals.

## When to Invoke

Invoke this skill:

- After generating documentation, a README, or a pull request body
- When a file has picked up comments that only restate the code
- Before sharing writing that reads as generated
- When reviewing a change that added more comments than code
- Before opening a PR, or on a branch whose work is already committed and pushed

## Invocation Modes

### Default: `/text-slop-cleaner`

Clean whatever this branch has in flight. The agent resolves the target itself.

```
Task tool with subagent_type="text-slop-cleaner"
prompt: "Clean the prose and comments in whatever this branch has in
flight. Resolve the target with this cascade and stop at the first step
that has something in it:
1. Uncommitted changes, found with git status --porcelain. Work only on
   the lines those changes touched.
2. Commits this branch has that the base branch does not, pushed or not.
   Work on every file those commits touched.
3. An open PR for the branch, found with gh pr view. Clean the body and
   your own comments, and never another person's.
4. Nothing in any of those. Say so in one line and stop.
Resolve the base branch with gh repo view, or git symbolic-ref
refs/remotes/origin/HEAD when gh is missing.
State which step fired in the first line of the report, and say why the
earlier steps were empty.
Rewrite padded prose into plain English, never deleting a sentence
that carries information.
Remove every comment that is not 100% necessary. Read the code a
comment describes before cutting it, and keep it only when the code
cannot tell the reader what it says.
Never touch lint directives, build tags, generated file markers,
licence headers, or doc comments a toolchain requires.
Never change code behaviour and never edit string literals.
Apply the changes directly. Report what changed, what was protected,
and the word count before and after.
Consult references/slop-patterns.md for the full pattern list."
```

**What the cascade picks:**

| Order | When | Target |
|-------|------|--------|
| 1 | The working tree is dirty | The uncommitted changes |
| 2 | The tree is clean but the branch is ahead of the base | The files those commits touched |
| 3 | Nothing local, but the branch has an open PR | The PR body and your own comments |
| 4 | Nothing anywhere | One line saying so, no changes |

Steps 1 and 2 need only `git`. Step 3 needs `gh`. The cascade never reaches every markdown file in the repository; ask for `all` when you want that.

### Scoped: `/text-slop-cleaner <path>`

Clean a specific file or directory.

```
Task tool with subagent_type="text-slop-cleaner"
prompt: "Clean the prose and comments in: [path]
Read each file fully before cutting anything from it.
Rewrite padded prose into plain English, never deleting a sentence
that carries information.
Remove every comment that is not 100% necessary. Read the code a
comment describes before cutting it, and keep it only when the code
cannot tell the reader what it says.
Never touch lint directives, build tags, generated file markers,
licence headers, or doc comments a toolchain requires.
Never change code behaviour and never edit string literals.
Apply the changes directly. Report what changed, what was protected,
and the word count before and after.
Consult references/slop-patterns.md for the full pattern list."
```

**Scope examples:**
- `/text-slop-cleaner README.md` - one file
- `/text-slop-cleaner docs/` - every file in a directory
- `/text-slop-cleaner src/auth/handler.go` - comments in one source file

### Pull request: `/text-slop-cleaner <number|url>`

Clean a pull request body and your own comments on it.

```
Task tool with subagent_type="text-slop-cleaner"
prompt: "Clean the text on pull request: [number or url]
Read the body and every comment with gh pr view and gh api.
Separate your own comments from other people's before changing anything.
Rewrite the body and your own comments into plain English, and apply
them with gh pr edit and gh api.
Never edit another person's comment. GitHub does not allow it. List
what reads as slop in theirs and leave it alone.
Report what changed and what was reported only."
```

### All: `/text-slop-cleaner all`

Clean every markdown file in the repository.

```
Task tool with subagent_type="text-slop-cleaner"
prompt: "Clean the prose in every markdown file in the repository.
Skip vendored, generated, and dependency directories.
Work file by file. Read each one fully before cutting anything.
Rewrite padded prose into plain English. Keep every code block,
command, path, and number exactly as written.
Never add headings, sections, or summaries that were not there.
Apply the changes directly. Report per file, then a total word count
before and after.
Consult references/slop-patterns.md for the full pattern list."
```

### Check: `/text-slop-cleaner check`

Report what would change, without changing anything. Resolves its target with the same cascade as the default.

```
Task tool with subagent_type="text-slop-cleaner"
prompt: "Report the slop in whatever this branch has in flight. Resolve
the target with the default cascade: uncommitted changes, then the
commits this branch has that the base does not, then the branch's open
PR, then nothing. State which step fired. Change nothing.
Do not edit any file and do not call gh.
Apply the 100% necessary rule to comments and show the verification
against the code for each one you would cut.
For each finding show the current text and the proposed replacement.
List protected content you would leave alone and why.
Consult references/slop-patterns.md for the full pattern list."
```

## What Is Protected

The agent never touches these, even though they can read as noise:

| Kind | Examples |
|------|----------|
| Lint and type directives | `//nolint`, `# noqa`, `# type: ignore`, `// eslint-disable` |
| Build and tooling markers | build tags, `//go:generate`, encoding lines, shebangs |
| Generated file markers | `Code generated by ... DO NOT EDIT` |
| Legal | licence headers, copyright notices, SPDX identifiers |
| Required doc comments | godoc on exported symbols, JSDoc on published APIs |
| Pragma comments that are code | `# frozen_string_literal: true`, webpack magic comments, `/** @type {...} */` |
| Sole statement docstrings | removing one breaks the syntax of the block |
| Other people's comments | reported, never edited |

## Rules

- Meaning never changes. A padded sentence that carries information gets rewritten, not deleted
- A comment that is not 100% necessary is removed, after reading the code it describes
- Code blocks, commands, paths, and numbers are copied through exactly
- Only prose and comments change. Never code, never string literals
- Nothing new is added. No new headings, no new summaries
- When a run touches a source file, the working tree is reviewed with `git diff` and the project's tests are run, since a comment edit can break syntax
- Default, scoped, pull request, and all modes apply without asking. Use `check` to review first

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/text-slop-cleaner` | `text-slop-cleaner` | Uncommitted changes, branch commits, or the open PR, whichever comes first |
| `/text-slop-cleaner <path>` | `text-slop-cleaner` | Named file or directory cleaned in place |
| `/text-slop-cleaner <number\|url>` | `text-slop-cleaner` | PR body and own comments rewritten |
| `/text-slop-cleaner all` | `text-slop-cleaner` | Every markdown file cleaned |
| `/text-slop-cleaner check` | `text-slop-cleaner` | Same target as the default, report only |

## Usage Examples

```
/text-slop-cleaner              # Clean whatever is in flight: changes, commits, or the PR
/text-slop-cleaner README.md    # Clean one file
/text-slop-cleaner docs/        # Clean a directory
/text-slop-cleaner 142          # Clean the body and your comments on PR 142
/text-slop-cleaner all          # Clean every markdown file
/text-slop-cleaner check        # Same target, show what would change, change nothing
```

## Additional Resources

### Reference Files

- **`references/slop-patterns.md`** - the full pattern list for prose and comments, with before and after examples
