# Two-Way Scope Checking for code-slop-cleaner

Date: 2026-08-14
Status: approved design, pending implementation

## Problem

`code-slop-cleaner` judges a diff in one direction only: it asks whether each
part of the diff serves the stated purpose. It can never notice that the
ticket asked for three things and the change delivered two. Nothing in the
setup checks completeness against a ticket.

A separate `scope-check` agent was considered and rejected: its extra-work
direction would duplicate code-slop-cleaner's UNRELATED/UNNECESSARY
classification, and both agents would need the same purpose gate. Instead,
code-slop-cleaner grows the missing-work direction.

## Decision

Update the existing agent and skill. No new agent, no new skill, no rename.
The command stays `/code-slop-cleaner`.

## Agent changes (`.claude/agents/code-slop-cleaner.md`)

### Identity

Widens from "was this needed" to "does the change match its purpose, in both
directions": everything in the diff serves the scope, and everything in the
scope appears in the diff.

### Purpose Gate becomes a Scope Gate

Same priority order, same stop-and-ask rule. New behavior: capture the full
scope when more than a one-sentence purpose exists.

Sources, in priority order:

1. Ticket text pasted by the user or passed in the dispatch prompt
2. An explicit ticket URL or number given as an argument
3. The pull request body and its linked issue
4. The commit messages on the branch

For Jira/Linear/external tracker URLs, fetch with WebFetch. If the tracker
needs auth and the fetch fails, ask the user to paste the ticket text. Never
guess ticket content from its URL slug.

From the scope, extract a numbered requirement list: explicit asks,
acceptance criteria, stated non-goals. Print the list at the top of the
report so a misread ticket is visible and correctable.

When only a one-sentence purpose exists, run the completeness check against
that one sentence and say so in the report. Degraded honestly, not skipped.

If no purpose can be found at all, stop and ask. Unchanged.

### New workflow step: requirement mapping

After inventorying the diff into units, map in both directions:

- Each requirement gets COVERED (name the implementing unit), PARTIAL (say
  what is missing), or MISSING (nothing in the diff addresses it)
- Each diff unit keeps its existing class: REQUIRED, SUPPORTING,
  UNNECESSARY, UNRELATED

Verification extends to MISSING: before calling a requirement missing,
search the codebase. It may already exist from earlier work or be
implemented somewhere non-obvious. An unverified MISSING is not a finding.

### Report changes

New verdict line at the top: IN SCOPE, INCOMPLETE (missing or partial
requirements), SCOPE CREEP (unnecessary or unrelated units), or BOTH.

New "Requirements" section after the summary: the numbered requirement list
with per-requirement status and the evidence for it.

Existing Unnecessary/Unrelated/Kept sections unchanged.

### Apply mode unchanged

Apply still only removes UNNECESSARY units. It never writes missing
features. MISSING and PARTIAL findings are report-only in every mode.

## Skill changes (`.claude/skills/code-slop-cleaner/SKILL.md`)

### Context injection rule (new, applies to every mode)

Before dispatching, the main session must copy into the agent prompt any
scope context already present in the conversation: a ticket URL the user
mentioned, pasted requirements, or the purpose the user stated when asking
for the change. The subagent starts fresh and cannot see the conversation;
without this rule, bare `/code-slop-cleaner` drops context the user already
gave.

### Modes

Existing five modes stay. Their prompts gain the requirement-extraction and
both-direction instructions. One additive form: an optional ticket argument.

| Invocation | Meaning |
|------------|---------|
| `/code-slop-cleaner` | Uncommitted changes, scope from session context or repo |
| `/code-slop-cleaner <path>` | Scoped to a path |
| `/code-slop-cleaner <number\|url>` | A pull request diff, scope from its body/linked issue |
| `/code-slop-cleaner <ticket-url>` | Current changes against an explicit ticket |
| `/code-slop-cleaner <pr> <ticket-url>` | Both explicit |
| `/code-slop-cleaner branch` | Whole branch against the default branch |
| `/code-slop-cleaner apply` | Remove UNNECESSARY units, run tests |

PR numbers/URLs point at github; anything else URL-shaped is a ticket.

### Description updates

Agent and skill descriptions gain the completeness direction. New trigger
phrases: "does this PR match the ticket", "is anything missing from this
change", "did this implement everything".

## Documentation updates

- `docs/reference/agents.md`: update the code-slop-cleaner row
- `docs/reference/skills.md`: update the code-slop-cleaner row and modes
- `README.md`: update the inventory line if it describes the agent

## Out of scope

- No new agent or skill
- No rename of the command
- No PR comment posting
- No changes to `references/change-patterns.md` beyond what the both-direction
  wording requires
- No hook or Makefile changes, so no new tests

## Testing

Manual: run `/code-slop-cleaner` against a branch with a known ticket and
confirm the report contains the requirement list, per-requirement statuses,
and the verdict line.
