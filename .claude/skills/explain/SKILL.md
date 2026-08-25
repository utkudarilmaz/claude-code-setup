---
name: explain
description: This skill should be used when the user asks to "explain this", "what does this do", "how does this work", "walk me through this", "explain this change", "explain this PR", "what is this function for", "explain it simply", "I don't understand this code", or "/explain". Explains code, changes, pull requests, or concepts in plain English.
---

# Explain Skill

## Purpose

Explains whatever it is pointed at, in words anyone can follow. Dispatches to the `explain` agent, which works out the target, reads it, and describes what it is, what it does, why it exists, and how it fits.

Terminal output only. Nothing is written to disk and nothing is published.

Explains, does not review. Use `/code-review` or `/simplifier` to judge code.

## When to Invoke

Invoke this skill:

- When picking up unfamiliar code
- When a diff or pull request is hard to follow
- When a term in the codebase has no obvious meaning
- Before reviewing someone else's change, to understand it first

## Target Detection

One command, no mode to remember. The agent works out the target in this order:

| Argument | Target |
|----------|--------|
| none, tree dirty | The uncommitted changes |
| none, tree clean | The most recent commit |
| an existing path | That file or directory |
| a number or PR url | That pull request |
| a symbol in the repository | That function, type, or class |
| anything else | A concept question, answered in this codebase's terms |

The resolved target is printed on the first line, so a wrong guess is obvious straight away.

## Invocation Modes

### Default: `/explain` or `/explain <target>`

```
Task tool with subagent_type="explain"
prompt: "Explain: [target, or 'the current changes' when none was given]
Work out the target in this order: no argument and a dirty tree means
the uncommitted changes, no argument and a clean tree means the last
commit, an existing path means that file, a number or PR url means that
pull request, a symbol found in the repository means that symbol, and
anything else is a concept question answered in this codebase's terms.
State the resolved target on the first line.
Cover what it is, what it does, why it exists, and how it fits. Add a
watch out for section only when something real belongs in it.
Read the callers before saying why something exists. Check commit
messages and linked issues for the reason behind a change.
Use everyday words. Define any unavoidable term in the sentence it
first appears in. Give one concrete example with real values.
Never write simply, just, obviously, or as you know.
If you cannot tell why something exists, say so, say what you checked,
and say what would answer it. Never invent a rationale.
Terminal output only. Write no files."
```

### Deep: `/explain <target> deep`

```
Task tool with subagent_type="explain"
prompt: "Explain in depth: [target]
Resolve the target the same way as the default mode and state it on the
first line.
Cover what it is, what it does, why it exists, and how it fits, then add
a walkthrough in execution order with file:line anchors for each step,
a worked example traced from a concrete input to its output, and the
edge cases the code handles with what it does in each.
Deep means more detail, not more jargon. Keep the same plain English.
Never invent a rationale. Say what you could not determine.
Terminal output only. Write no files.
Consult references/deep-mode.md for the walkthrough structure."
```

**Examples:**
- `/explain internal/queue/retry.go deep` - line by line through one file
- `/explain 142 deep` - full walkthrough of a pull request

## Output Shape

| Section | Included |
|---------|----------|
| What it is | Always, one line |
| What it does | Always, plain steps |
| Why it exists | Always, the problem it solves |
| How it fits | Always, callers and callees |
| Watch out for | Only when something real belongs there |

Empty sections are dropped, not padded.

## Rules

- The resolved target is stated first
- Everyday words. Any unavoidable term is defined where it first appears
- Concrete values, not "the input"
- One worked example with real values
- Never `simply`, `just`, `obviously`, `of course`, `as you know`
- Never invent a reason. An honest gap beats a plausible guess
- What was read and what was inferred are kept apart
- Length follows the target. A small function gets a short answer

## Agent Dispatch Summary

| Invocation | Agent | Output |
|------------|-------|--------|
| `/explain` | `explain` | The uncommitted changes, or the last commit |
| `/explain <target>` | `explain` | The named file, PR, symbol, or concept |
| `/explain <target> deep` | `explain` | Full walkthrough with anchors and a worked example |

## Usage Examples

```
/explain                                # The current changes
/explain internal/queue/retry.go        # One file
/explain 142                            # Pull request 142
/explain parseManifest                  # One function
/explain what is a reconciler here      # A concept, in this codebase's terms
/explain internal/queue/retry.go deep   # Line by line, with an example
```

## Additional Resources

### Reference Files

- **`references/deep-mode.md`** - walkthrough structure, worked example format, and how to handle code you cannot fully explain
