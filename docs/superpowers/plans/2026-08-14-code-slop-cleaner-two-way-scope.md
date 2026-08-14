# Two-Way Scope Checking for code-slop-cleaner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the code-slop-cleaner agent and skill so they check a change against its ticket in both directions: work the scope does not cover, and scope the work does not deliver.

**Architecture:** Two markdown files carry the behavior: `.claude/agents/code-slop-cleaner.md` holds the methodology, `.claude/skills/code-slop-cleaner/SKILL.md` is the dispatch layer. Three docs files describe them. All changes are prose edits; there is no runnable code and no automated test for this content.

**Tech Stack:** Markdown, YAML frontmatter. Spec: `docs/superpowers/specs/2026-08-14-code-slop-cleaner-two-way-scope-design.md`.

## Global Constraints

- Do not commit at any step. The user commits manually. This overrides any frequent-commit habit.
- Plain simple English in all prose. No double dashes anywhere.
- Never split the agent file or SKILL.md; they load as complete context.
- Keep existing classification classes REQUIRED, SUPPORTING, UNNECESSARY, UNRELATED exactly as they are.
- New requirement statuses are exactly: COVERED, PARTIAL, MISSING.
- Verdict values are exactly: IN SCOPE, INCOMPLETE, SCOPE CREEP, BOTH.
- Apply mode never writes missing features. MISSING and PARTIAL are report-only in every mode.
- Do not modify `references/change-patterns.md`.
- After all tasks, `make test` must still pass (nothing here touches hooks or Makefile, so a failure means an unrelated breakage; report it, do not fix it in this plan).

---

### Task 1: Rewrite the agent for two-way checking

**Files:**
- Modify: `.claude/agents/code-slop-cleaner.md`

**Interfaces:**
- Produces: the section names, statuses, and verdicts that Task 2's dispatch prompts and Task 3's docs reference: "The Scope Gate", statuses COVERED/PARTIAL/MISSING, verdicts IN SCOPE/INCOMPLETE/SCOPE CREEP/BOTH, report titled "Change Scope Report".

- [ ] **Step 1: Update the frontmatter description**

Replace the `description:` line with:

```yaml
description: "This agent should be invoked to check whether a change matches its purpose in both directions. This includes judging a diff against its ticket or stated purpose, separating the parts that serve that purpose from the parts that do not, flagging work that belongs in a different change, and finding requirements the change was supposed to deliver but did not."
```

- [ ] **Step 2: Replace the identity paragraphs**

Replace the two paragraphs directly under the frontmatter (starting "You are a reviewer who judges a change against the reason it was made." and "This is different from a general code quality review.") with:

```markdown
You are a reviewer who judges a change against the scope it was made for, in both directions. You ask two questions. Does everything in the diff serve the scope? Does everything in the scope appear in the diff? Work that does not serve the scope is either a separate change or nothing at all. A requirement with nothing in the diff addressing it is missing work.

This is different from a general code quality review. Quality asks "is this well written". You ask "was this asked for, and was all of it delivered".
```

- [ ] **Step 3: Replace "## The Purpose Gate" with "## The Scope Gate"**

Replace the whole "## The Purpose Gate" section with:

```markdown
## The Scope Gate

**Establish the scope before looking at a single line of the diff.** Read, in this order:

1. Ticket text pasted by the user or included in the dispatch prompt
2. An explicit ticket URL or number given as an argument
3. The linked issue or ticket
4. The pull request body
5. The commit messages on the branch
6. The user's own description if they gave one

For Jira, Linear, or any external tracker URL, fetch the ticket with WebFetch. If the fetch fails because the tracker needs auth, ask the user to paste the ticket text. Never guess ticket content from its URL slug.

If none of these yield a clear scope, **stop and ask the user what the change was for**. Do not proceed.

This is not a formality. Without a stated scope you will infer one from the diff itself, and a scope inferred from the diff makes every line look necessary and every requirement look delivered. You will then report nothing. An honest question is the correct output when the scope is missing.

From the scope, extract a numbered requirement list: explicit asks, acceptance criteria, and stated non-goals. State the list at the top of the report so the user can correct a misreading. When the scope is only a one-sentence purpose, run the completeness check against that sentence and say in the report that coverage was judged against a purpose, not a ticket.
```

- [ ] **Step 4: Update the workflow steps**

Rename "### Step 1: Establish the Purpose" to "### Step 1: Establish the Scope" and change its body to:

```markdown
As above. Extract the numbered requirement list. Stop and ask if no scope can be found.
```

Keep "### Step 2: Inventory the Diff" unchanged. Insert a new step after it:

```markdown
### Step 3: Map Requirements to Units

Give every requirement a status:

| Status | Meaning |
|--------|---------|
| COVERED | A unit implements it. Name the unit |
| PARTIAL | Partly implemented. Say exactly what is missing |
| MISSING | Nothing in the diff addresses it |
```

Renumber the remaining steps: "Verify Before Judging" becomes Step 4, "Classify Each Unit" becomes Step 5, "Report, or Apply" becomes Step 6.

- [ ] **Step 5: Extend verification to MISSING**

In the renumbered "### Step 4: Verify Before Judging", add one bullet to the checklist:

```markdown
- Before calling a requirement missing or partial, search the codebase for an existing implementation. It may have shipped in earlier work or live somewhere non-obvious. Name the search that came up empty
```

- [ ] **Step 6: Update the report/apply step and output format**

In the renumbered "### Step 6: Report, or Apply", append:

```markdown
MISSING and PARTIAL findings are report only in every mode. Apply removes UNNECESSARY units; it never writes missing features.
```

Replace the "## Output Format" code block with:

````markdown
```markdown
## Change Scope Report

**Verdict**: [IN SCOPE | INCOMPLETE | SCOPE CREEP | BOTH]
**Scope**: [one sentence]
**Source of scope**: [where it came from, and whether it was a full ticket or only a purpose]
**Reviewed**: [what was reviewed]

### Requirements
[Numbered list. Each line: the requirement, its status, and the evidence.]
1. [requirement] - COVERED by [unit]
2. [requirement] - PARTIAL: [what is missing]
3. [requirement] - MISSING, verified by [the search that came up empty]

### Summary
X units: A required, B supporting, C unnecessary, D unrelated.
N requirements: E covered, F partial, G missing.

### Missing
#### [requirement]
**What the scope asks**: [plain description]
**What exists**: [what the diff or codebase has instead, if anything]
**Verified by**: [the search that confirms it is absent]

### Unnecessary
#### [unit name]
**Location**: `file:line`
**What it does**: [plain description]
**Why it does not serve the scope**: [reason]
**Verified by**: [the search or check that confirms it]
**Removal**: [what to delete]

### Unrelated
#### [unit name]
**Location**: `file:line`
**Belongs in**: [a short description of the change it belongs to]

### Kept
[One line per required and supporting unit. No detail needed.]
```
````

Directly under the code block, add the verdict definitions:

```markdown
Verdicts: IN SCOPE means every requirement is covered and no unit is unnecessary or unrelated. INCOMPLETE means at least one requirement is missing or partial. SCOPE CREEP means at least one unit is unnecessary or unrelated. BOTH means both problems are present.
```

- [ ] **Step 7: Update the guidelines**

In "### Do", add:

```markdown
- Search before calling a requirement missing; absence must be verified like any other finding
- Report the requirement list you extracted, so a misread ticket is visible
```

In "### Do Not", change "Do not infer the purpose from the diff you are reviewing" to "Do not infer the scope from the diff you are reviewing", change "Why it does not serve the purpose" wording consistency if present, and add:

```markdown
- Do not write missing features in apply mode. MISSING is a report finding, never an edit
```

Also in "## Never Flag", leave every existing bullet, and in the last bullet keep the meaning but update the word "purpose" to "scope" where it reads "even when it does not fit the written purpose".

- [ ] **Step 8: Verify the agent file**

Run: `grep -n "Purpose Gate\|the purpose" .claude/agents/code-slop-cleaner.md`
Expected: no "Purpose Gate" heading remains. Occurrences of "the purpose" are fine only inside the classification table rows (REQUIRED/SUPPORTING/UNNECESSARY definitions may keep the word purpose) and pattern text; headings and workflow must say scope. Fix any leftovers.

Run: `grep -c "COVERED\|PARTIAL\|MISSING" .claude/agents/code-slop-cleaner.md`
Expected: nonzero.

---

### Task 2: Update the skill dispatch layer

**Files:**
- Modify: `.claude/skills/code-slop-cleaner/SKILL.md`

**Interfaces:**
- Consumes: from Task 1: "The Scope Gate", COVERED/PARTIAL/MISSING, verdicts, "Change Scope Report".

- [ ] **Step 1: Update the frontmatter description**

Replace the `description:` line with:

```yaml
description: This skill should be used when the user asks to "check if this change was necessary", "does this PR match the ticket", "is anything missing from this change", "did this implement everything", "what in this diff is not needed", "did this change do too much", "find the scope creep", "is all of this required", or "/code-slop-cleaner". Judges a diff against its ticket or stated purpose in both directions and separates needed work, extra work, and missing work.
```

- [ ] **Step 2: Update Purpose and add the context injection rule**

Replace the "## Purpose" body with:

```markdown
Checks whether a change matches its scope in both directions. Dispatches to the `code-slop-cleaner` agent, which reads the scope from a ticket, pull request body, or commits, extracts a numbered requirement list, then classifies every part of the diff as required, supporting, unnecessary, or belonging to a different change, and gives every requirement a status of covered, partial, or missing.

Reports by default. `apply` removes the unnecessary parts and runs the tests. Missing work is never written, only reported.

Different from `/simplifier`. That one asks whether code is well written. This one asks whether it needed to be written, and whether everything asked for was written.
```

After the "## When to Invoke" section, add:

```markdown
## Context Injection

The agent starts fresh and cannot see this conversation. Before dispatching, copy into the prompt any scope context already present in the session: a ticket URL the user mentioned, pasted requirements or acceptance criteria, or the purpose the user stated when asking for the change. Without this, a bare `/code-slop-cleaner` drops context the user already gave.
```

Add to "## When to Invoke" bullet list:

```markdown
- Before closing a ticket, to check every requirement made it into the change
```

- [ ] **Step 3: Rename the Purpose Gate section**

Replace "## The Purpose Gate" heading and body with:

```markdown
## The Scope Gate

The agent reads the scope from pasted ticket text, an explicit ticket URL, the linked issue, the pull request body, or the commit messages, in that order. Jira, Linear, and other tracker URLs are fetched with WebFetch; if the tracker needs auth, the agent asks for the ticket text. **If it cannot find any scope, it stops and asks.**

This is deliberate. A scope guessed from the diff makes every line look necessary and every requirement look delivered, and the review returns nothing. Give it a scope, or answer its question.
```

- [ ] **Step 4: Update every existing mode prompt**

In each of the five mode prompts (Default, Scoped, Pull request, Branch, Apply), make these substitutions:

- Replace the sentence pair "Establish the purpose first from the linked issue, the branch commits, or the user's own description. If no purpose can be found, stop and ask. Do not infer the purpose from the diff itself." (wording varies slightly per mode) with:

```
Establish the scope first: any ticket context included below, then the
linked issue, the PR body, or the branch commits. If no scope can be
found, stop and ask. Do not infer the scope from the diff itself.
Extract a numbered requirement list from the scope.
[Include here any ticket URL, pasted requirements, or stated purpose
from the current session.]
```

- After the classify line ("Classify each as REQUIRED, SUPPORTING, UNNECESSARY, or UNRELATED."), add:

```
Give every requirement a status: COVERED, PARTIAL, or MISSING. Before
calling one missing, search the codebase for an existing implementation.
```

- In the Pull request mode prompt, also replace "Read the body and any linked issue for the purpose. Fall back to the commit messages." with "Read the body and any linked issue for the scope. Fetch external ticket links with WebFetch. Fall back to the commit messages."

- In the Apply mode prompt, after "Never remove UNRELATED work." add "Never write missing features. Report MISSING and PARTIAL requirements only."

- [ ] **Step 5: Add the ticket modes**

After the "### Pull request" mode section, insert:

````markdown
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
````

- [ ] **Step 6: Update classification, rules, dispatch summary, examples**

After the existing "## Classification" table, add:

```markdown
Requirements get their own status:

| Status | Meaning |
|--------|---------|
| COVERED | A unit implements it |
| PARTIAL | Partly implemented; the report says what is missing |
| MISSING | Nothing in the diff addresses it, verified by a search |
```

In "## Rules", change "The purpose comes first. No purpose means the agent asks rather than guesses" to "The scope comes first. No scope means the agent asks rather than guesses", and add:

```markdown
- A requirement is only MISSING after a codebase search comes up empty
- Missing work is reported, never written, in every mode including apply
```

In "## Agent Dispatch Summary", add two rows:

```markdown
| `/code-slop-cleaner <ticket-url>` | `code-slop-cleaner` | Report on the current changes against a ticket |
| `/code-slop-cleaner <pr> <ticket-url>` | `code-slop-cleaner` | Report on a pull request against a ticket |
```

In "## Usage Examples", add:

```markdown
/code-slop-cleaner https://acme.atlassian.net/browse/APP-42   # Current changes vs ticket
/code-slop-cleaner 142 https://linear.app/acme/issue/APP-42   # PR 142 vs ticket
```

- [ ] **Step 7: Verify the skill file**

Run: `grep -n "Purpose Gate\|purpose first" .claude/skills/code-slop-cleaner/SKILL.md`
Expected: no matches. Fix any leftovers.

Run: `grep -c "COVERED, PARTIAL, or MISSING" .claude/skills/code-slop-cleaner/SKILL.md`
Expected: 7 (five updated modes plus two ticket modes).

---

### Task 3: Update the documentation

**Files:**
- Modify: `docs/reference/agents.md:253-278`
- Modify: `docs/reference/skills.md:374-426`
- Modify: `README.md:73-76`

**Interfaces:**
- Consumes: names and statuses from Task 1 and modes from Task 2. No later task consumes this.

- [ ] **Step 1: Update the agent reference**

In `docs/reference/agents.md`, section "## code-slop-cleaner":

Replace the intro line with:

```markdown
Reviewer that judges a change against its scope in both directions: it separates the work that serves the scope from the work that does not, and finds requirements the change was supposed to deliver but did not.
```

In **Trigger**, append ", or before closing a ticket to check every requirement made it in".

In **Responsibilities**, change "Establish the purpose from the linked issue, PR body, or commit messages before reading a line of the diff" to "Establish the scope from pasted ticket text, a ticket URL (fetched with WebFetch), the linked issue, PR body, or commit messages before reading a line of the diff", change "Stop and ask the user when no purpose can be found" to "Stop and ask the user when no scope can be found", and add two bullets:

```markdown
- Extract a numbered requirement list from the scope and report it, so a misread ticket is visible
- Give every requirement a status of COVERED, PARTIAL, or MISSING, searching the codebase before calling one missing
```

After the classification table and its trailing note, add:

```markdown
Requirements get their own status: COVERED (a unit implements it), PARTIAL (partly implemented), or MISSING (nothing addresses it, verified by a search). The report opens with a verdict: IN SCOPE, INCOMPLETE, SCOPE CREEP, or BOTH. Missing work is reported, never written.
```

- [ ] **Step 2: Update the skill reference**

In `docs/reference/skills.md`, section "## /code-slop-cleaner":

Replace the tagline (line 376) with:

```markdown
Judge a diff against its ticket or stated purpose in both directions: needed work, extra work, and missing work.
```

Add two rows to the mode table:

```markdown
| Ticket | `/code-slop-cleaner <ticket-url>` | Review the current changes against an explicit ticket |
| PR with ticket | `/code-slop-cleaner <pr> <ticket-url>` | Review a pull request against an explicit ticket |
```

In **What it does**, add:

```markdown
- **Ticket:** Fetches the ticket with WebFetch (asks for pasted text if the tracker needs auth), extracts a requirement list, and checks the current changes against it
- **PR with ticket:** Same, but for a pull request's diff against its base branch
```

Replace the "**The purpose gate:**" paragraph with:

```markdown
**The scope gate:** The agent reads the scope from pasted ticket text, an explicit ticket URL, the linked issue, the pull request body, or the commit messages, in that order. External tracker URLs are fetched with WebFetch. If it cannot find any scope, it stops and asks. This is deliberate: a scope guessed from the diff makes every line look necessary and every requirement look delivered, and the review then returns nothing.
```

After the classification table note (line 406), add:

```markdown
Requirements get their own status: COVERED, PARTIAL, or MISSING (verified by a codebase search). The report opens with a verdict: IN SCOPE, INCOMPLETE, SCOPE CREEP, or BOTH.
```

In the `/simplifier` comparison table, change the `/code-slop-cleaner` row's "Question it answers" cell to "Did this change need to happen, and did it deliver everything asked?".

In **Rules**, append ": a requirement is only MISSING after a codebase search comes up empty, and missing work is reported, never written".

Add to **Examples**:

```markdown
/code-slop-cleaner https://acme.atlassian.net/browse/APP-42   # Current changes vs ticket
```

- [ ] **Step 3: Update the README**

In `README.md`, change line 73 from "Check whether the uncommitted changes were necessary" to "Check the uncommitted changes against their ticket or purpose, both directions", and after line 74 add:

```markdown
| code-slop-cleaner | `/code-slop-cleaner <ticket-url>` | Check the current changes against an explicit ticket |
```

- [ ] **Step 4: Verify docs and repo state**

Run: `grep -rn "purpose gate" docs/ README.md`
Expected: no matches (case-insensitive check too: `grep -rni "purpose gate" docs/ README.md`).

Run: `make test`
Expected: PASS (nothing in this plan touches hooks or the Makefile).

---

## Manual Smoke Test (after all tasks)

Run `/code-slop-cleaner` on a branch with a known ticket and confirm the report contains: the verdict line, the numbered requirement list with per-requirement statuses, and the existing unit sections. This needs a real session and is done by the user.
