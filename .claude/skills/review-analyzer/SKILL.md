---
name: review-analyzer
description: This skill should be used when the user asks to "analyze this review", "is this review comment right", "check this code review against the code", "is this reviewer correct", "does the suggested fix actually work", "verify this review feedback", or "/review-analyzer". Checks each issue in a code review against the actual code, judges the proposed fixes, and explains everything in plain language.
---

# Review Analyzer Skill

## Purpose

Checks a code review someone else wrote against the actual code. Dispatches to the `review-analyzer` agent, which parses the review into numbered issues, verifies each issue in the code, judges every proposed fix as valid, partial, or invalid, proposes a better fix when the proposed one falls short, and explains all of it in plain language for a reader who does not know the codebase.

The report gives every parsed issue its own numbered section answering six questions: what the reviewer found, what the issue is, why it is an issue and whether it is valid, what fix the review suggests, whether that fix is right, and what the agent suggests to close it. No item is skipped or merged, and every item ends with one concrete closing recommendation.

Report only. Nothing is edited, nothing is written to disk, and nothing is fetched from GitHub.

Different from `/code-review`, which finds issues in code. This skill judges issues someone else already found. Different from `/explain`, which describes code without judging. This skill judges a review of the code.

## When to Invoke

Invoke this skill:

- After receiving review comments, before acting on them
- Before pushing back on a review comment, to check the reviewer is actually wrong
- When a reviewer's suggested fix looks wrong or incomplete
- When someone outside the team needs the review explained in plain words

## Context Injection

The agent starts fresh and cannot see this conversation. Before dispatching, paste the full review text from the session into the prompt. Without this, a bare `/review-analyzer` drops the review the user already gave.

## The Review Gate

The agent takes the review from pasted text or a file path, in that order. It never fetches pull requests or review comments itself. Given a PR number or URL, it stops and asks for the text or a file. **If it cannot find any review, it stops and asks.**

## Invocation Modes

### Default: `/review-analyzer`

Analyze the review pasted in the conversation.

```
Task tool with subagent_type="review-analyzer"
prompt: "Analyze this code review against the actual code:
[paste the full review text from the current session here]
If no review text is available, stop and ask the user to paste it or
give a file path. Never fetch anything with gh.
Parse the review into a numbered issue list, noting each issue's
location and proposed fix if any, and state the list at the top.
For each issue, read the actual code it points at, plus its callers
and tests, before judging. Verdict CONFIRMED, NOT A BUG, or CANNOT
VERIFY, naming the file and lines that prove it. Never judge from the
review text alone. Note when the code appears to have changed since
the review was written.
For each proposed fix on a confirmed issue, trace what it would
change. Verdict VALID, PARTIAL, or INVALID, naming what it misses or
breaks. Skip the fix verdict for issues that are not confirmed and
say in one sentence why.
When a fix is PARTIAL or INVALID, or a confirmed issue has no fix,
propose a better fix in words: which file, what changes, and why that
addresses the cause. Search for an existing helper it should reuse.
Report every parsed issue as its own numbered section, in the parsed
order, answering six questions: what the reviewer found, what the
issue is, why it is an issue and whether it is valid, what fix the
review suggests, whether that fix is right, and what you suggest to
close it. Answer all six in every section; write No fix proposed or
No fix to judge instead of leaving a line out. Never skip, merge, or
shorten an item, not even a minor or entirely correct one. State the
item count in the header and make the sections match it. End every
item with one concrete closing recommendation: apply the reviewer's
fix, apply the better fix, reply with the evidence and close without
a change, or run the check that would settle the verdict.
Explain every issue, the reviewer's fix, and your suggested fix in
plain language for a reader who has never seen this codebase. Never
write simply, just, obviously, of course, or as you know.
Consult references/fix-validity-patterns.md for what makes a proposed
fix partial or invalid.
Report only. Change nothing. Write no files. Terminal output only."
```

### File: `/review-analyzer <file>`

Analyze a review saved to a file.

```
Task tool with subagent_type="review-analyzer"
prompt: "Analyze the code review in this file: [path]
Read the file first. If the path does not exist, stop and ask.
Keep the reviewer's own grouping of comments when the file has one.
Parse the review into a numbered issue list, noting each issue's
location and proposed fix if any, and state the list at the top.
For each issue, read the actual code it points at, plus its callers
and tests, before judging. Verdict CONFIRMED, NOT A BUG, or CANNOT
VERIFY, naming the file and lines that prove it. Never judge from the
review text alone. Note when the code appears to have changed since
the review was written.
For each proposed fix on a confirmed issue, trace what it would
change. Verdict VALID, PARTIAL, or INVALID, naming what it misses or
breaks. Skip the fix verdict for issues that are not confirmed and
say in one sentence why.
When a fix is PARTIAL or INVALID, or a confirmed issue has no fix,
propose a better fix in words: which file, what changes, and why that
addresses the cause. Search for an existing helper it should reuse.
Report every parsed issue as its own numbered section, in the parsed
order, answering six questions: what the reviewer found, what the
issue is, why it is an issue and whether it is valid, what fix the
review suggests, whether that fix is right, and what you suggest to
close it. Answer all six in every section; write No fix proposed or
No fix to judge instead of leaving a line out. Never skip, merge, or
shorten an item, not even a minor or entirely correct one. State the
item count in the header and make the sections match it. End every
item with one concrete closing recommendation: apply the reviewer's
fix, apply the better fix, reply with the evidence and close without
a change, or run the check that would settle the verdict.
Explain every issue, the reviewer's fix, and your suggested fix in
plain language for a reader who has never seen this codebase. Never
write simply, just, obviously, of course, or as you know.
Consult references/fix-validity-patterns.md for what makes a proposed
fix partial or invalid.
Report only. Change nothing. Write no files. Terminal output only."
```

## Verdicts

Issues:

| Verdict | Meaning |
|---------|---------|
| CONFIRMED | The problem exists, proven by named file and lines |
| NOT A BUG | The code is fine, backed by a named guarantee, caller, or test |
| CANNOT VERIFY | Not checkable from the code alone; the report says what would settle it |

Proposed fixes:

| Verdict | Meaning |
|---------|---------|
| VALID | Fixes the root cause without breaking anything else |
| PARTIAL | Helps but incomplete; the report says exactly what is missing |
| INVALID | Does not fix it, fixes the wrong thing, or breaks something else |

## Rules

- The review comes from pasted text or a file, never from gh
- Every parsed issue gets its own numbered section answering all six questions; the item count in the header matches the sections
- Every item ends with one concrete closing recommendation
- Every verdict names its evidence in the code
- Better fixes are proposed in words, never applied
- Plain language throughout; a reader outside the team can follow it
- A review that is entirely right is reported as such, not padded with findings
- Report only. No files are edited or written

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/review-analyzer` | `review-analyzer` | Analysis of the review pasted in the conversation |
| `/review-analyzer <file>` | `review-analyzer` | Analysis of the review stored in a file |

## Usage Examples

```
/review-analyzer                      # The review pasted above in the chat
/review-analyzer reviews/pr-142.md    # A review saved to a file
```

## Additional Resources

### Reference Files

- **`references/fix-validity-patterns.md`** - what makes a proposed fix invalid or partial, what makes an issue not a bug, and what a better fix must state
