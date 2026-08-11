# Slop Cleaners and Explain

Design for three new extensions: `text-slop-cleaner`, `code-slop-cleaner`, and `explain`.

## Goal

Three extensions that share one judgment, applied to different material:

| Extension | Question it answers |
|-----------|--------------------|
| `text-slop-cleaner` | Does this sentence earn its place? |
| `code-slop-cleaner` | Did this change need to happen? |
| `explain` | What is this, in words anyone can follow? |

## Decisions

| Decision | Choice |
|----------|--------|
| Relationship to `simplifier` | `code-slop-cleaner` is a separate agent. `simplifier` judges code on its own merits across the codebase. `code-slop-cleaner` judges a diff against its stated purpose. |
| Comment stripping | Belongs to `text-slop-cleaner`. Removing a comment is a judgment about English, not about code. |
| `text-slop-cleaner` writes | Applies directly with no confirmation, everywhere it is able to. |
| `code-slop-cleaner` writes | Reports by default. `apply` mode removes, then runs the project test command. |
| `explain` output | Terminal only. Nothing written to disk, nothing published. |
| Models | All three on `opus`. Each one either deletes work or risks inventing an explanation. |
| Naming | Skill name matches agent name, as everywhere else in this repository. |

## Files

```
.claude/agents/text-slop-cleaner.md
.claude/agents/code-slop-cleaner.md
.claude/agents/explain.md
.claude/skills/text-slop-cleaner/SKILL.md
.claude/skills/text-slop-cleaner/references/slop-patterns.md
.claude/skills/code-slop-cleaner/SKILL.md
.claude/skills/code-slop-cleaner/references/change-patterns.md
.claude/skills/explain/SKILL.md
.claude/skills/explain/references/deep-mode.md
```

Updated: `README.md`, `docs/reference/agents.md`, `docs/reference/skills.md`.

Agent frontmatter uses the terse third-person `description` style used by `pr-body`, not the older `<example>` block style.

## text-slop-cleaner

Rewrites text that reads as machine-written into plain English, and removes comments that do not earn their place.

### Modes

| Mode | Command | Target |
|------|---------|--------|
| Default | `/text-slop-cleaner` | Prose and comments in uncommitted changes |
| Scoped | `/text-slop-cleaner <path>` | A file or directory |
| Pull request | `/text-slop-cleaner <number\|url>` | PR body and the user's own comments |
| All | `/text-slop-cleaner all` | Every markdown file in the repository |
| Check | `/text-slop-cleaner check` | Report only, changes nothing |

### Never touches

- Code behavior. Only prose and comments change.
- String literals, even when they read as slop.
- Another person's comment. GitHub does not allow editing it, so it is reported and left.
- Lint and tooling directives: `//nolint`, `# noqa`, `# type: ignore`, `// eslint-disable`, `# pylint:`, `// @ts-expect-error`.
- Build tags, pragmas, generated-file markers, license headers.
- Doc comments a toolchain requires: godoc on exported symbols, JSDoc on published package APIs.

### Prose rules

Removes hedge padding, rule-of-three lists, "it is not X, it is Y" constructions, bold-label bullets, emoji, empty openers and closers, marketing adjectives (`robust`, `seamless`, `leverage`, `delve`, `comprehensive`), hollow transitions (`Additionally`, `Furthermore`, `Moreover`), restated conclusions, and claims of improvement with no number behind them.

The full list lives in `references/slop-patterns.md`.

A sentence that is both slop and load-bearing gets rewritten, never deleted. Meaning does not change.

### Comment rules

Remove:
- Comments restating the line below them
- Banner separators
- Docstrings that repeat the signature and add nothing
- Change history in code
- Commented-out code

Keep:
- Why a thing is done this way
- Constraints that are not visible in the code
- Workarounds, with their link or issue reference
- Units, ranges, and invariants

## code-slop-cleaner

Judges a change against the purpose it was made for.

### Workflow

1. **Establish the purpose** from the linked issue, PR body, or commit messages. If no purpose can be found, stop and ask. Never invent one.
2. **Split the diff** into units grouped by concern.
3. **Classify** each unit.
4. **Report**, or in `apply` mode remove and verify.

### Classification

| Class | Meaning |
|-------|---------|
| REQUIRED | The purpose fails without it |
| SUPPORTING | Genuinely needed: tests for new behavior, a migration, an import |
| UNNECESSARY | Does not serve the purpose. Remove. |
| UNRELATED | Real work, wrong change. Split it out. |

### Looks for

- Defensive checks the caller or type system already guarantees
- Error handling that catches and rethrows unchanged
- Abstractions with one implementation
- Config flags with one caller sitting on the default
- Compatibility shims for code that never shipped
- New helpers duplicating something already in the repository, confirmed by searching
- Demo and `__main__` blocks
- Tests asserting that a mock was called
- Parameters added, defaulted, and never passed
- New dependencies replacing a few lines of standard library
- Reformatting dragged into an unrelated diff

### Never flags

- Tests covering new behavior
- Error handling at real input and output boundaries
- Anything as unused without searching the codebase first
- A public API's compatibility layer

### Modes

| Mode | Command |
|------|---------|
| Default | `/code-slop-cleaner` |
| Scoped | `/code-slop-cleaner <path>` |
| Pull request | `/code-slop-cleaner <number\|url>` |
| Branch | `/code-slop-cleaner branch` |
| Apply | `/code-slop-cleaner apply` |

`apply` removes UNNECESSARY units, runs the project test command, and reports the result. If tests fail, it says so with the output.

## explain

Explains whatever it is pointed at, in plain English.

### Target detection

In order:

1. No argument, and there are uncommitted changes, then those changes
2. No argument, and the tree is clean, then the last commit
3. An existing file path, then that file
4. A number or a pull request URL, then that pull request
5. A symbol found in the repository, then that symbol
6. Anything else, then a concept question answered in this codebase's terms

The chosen target is stated in the first line of output, so a wrong guess is obvious.

### Output

Default:

- What it is, in one line
- What it does, as plain steps
- Why it exists, meaning the problem it solves
- How it fits, meaning what calls it and what it calls
- What to watch out for, only when something real exists

`/explain <target> deep` adds a walkthrough in execution order with `file:line` anchors, and a worked example using concrete values.

### Tone

- Everyday words. Any unavoidable term is defined in the sentence it first appears in.
- Concrete values, not "the input".
- Short sentences.
- Never `simply`, `just`, `obviously`, `as you know`.
- Never bluff. When the purpose is not clear from the code, say so and say what would be needed to find out.

The anti-bluff rule matters most. Confident invention is the failure mode this agent is most prone to.

## Testing

`tests/` currently covers hook scripts and Makefile sync. Neither is touched by this work.

Add `tests/extension-frontmatter.test.sh`, which asserts that every file in `.claude/agents/*.md` and `.claude/skills/*/SKILL.md` has valid YAML frontmatter with a `name` matching its filename or directory, and a non-empty `description`. This catches the most common breakage when adding extensions, and covers the existing files as well as the new ones.

## Out of scope

- Changing or removing the existing `simplifier` agent
- Publishing explanations as artifacts or web pages
- Editing other people's pull request comments
- Any hook that runs these automatically
