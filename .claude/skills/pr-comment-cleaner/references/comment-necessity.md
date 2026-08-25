# Comment Necessity

The pattern list for the `pr-comment-cleaner` agent. A comment is necessary only when deleting it loses information the surrounding code does not carry. Removal is the default: a comment earns its place by naming a fact a competent reader of the code cannot recover, and accurate, harmless, or mildly helpful does not earn it.

Verification runs both ways. A removal is verified by reading the code and confirming it already says everything the comment says. A keep is verified by naming the fact the code cannot give back. Doubt about whether content is protected, or whether the code rather than the comment is wrong, keeps the comment; doubt about whether a comment is useful enough removes it, because usefulness is not the bar.

## Remove

### Restating the code

```go
// increment the counter
counter++

// loop over the users
for _, u := range users {
```

**Verify:** read the code below the comment. If the comment names nothing the code does not already say, cut it. If it carries a unit, a constraint, or a why, it is a REWRITE or a KEEP.

### Section narration

```go
// handle errors
if err != nil {
```

**Verify:** the code structure already shows the section. If the comment marks a region a tool reads, it is PROTECTED, not removable.

### Edit narration

```python
# updated to use the new client
client = NewClient()
```

**Verify:** the comment describes the change, not the code. Git history holds this; the file should not.

### Banner separators

```go
// ============================
// HELPER FUNCTIONS
// ============================
```

**Verify:** confirm no tool consumes the marker. Region markers an editor or generator reads are PROTECTED.

### Commented out code

```python
# result = old_compute(data)
result = compute(data)
```

**Verify:** git history preserves it. Search the file for a live comment that references it as an example; if one does, keep both or rewrite the reference.

### Change history and ticket annotations

```go
// Added 2024-01-01 by the platform team
// Modified for PROJ-1234
```

**Verify:** confirm the line adds nothing beyond authorship or history. Note the user convention: ticket IDs do not belong in comment lines at all.

### Docstring repeating the signature

```python
def get_user_by_id(user_id: int) -> User:
    """Get a user by ID.

    Args:
        user_id: The user ID.
    Returns:
        The user.
    """
```

**Verify:** check for doc tooling (Sphinx, godoc, JSDoc, a published package). If a generator publishes it or the symbol is exported under a convention that requires docs, it is PROTECTED. If it is the only statement in its block, it is PROTECTED because removing it breaks the syntax.

### Obvious type notes

```javascript
// userId is a string
const userId = String(id);
```

**Verify:** the declaration already states the type. A `/** @type {...} */` annotation a type checker consumes is PROTECTED, not removable.

### TODO with no owner, date, or issue

```go
// TODO: clean this up
```

**Verify:** confirm there is no owner, no date, and no issue reference. A TODO with any of those stays.

### Accurate summary on an internal helper

```python
def build_index(rows):
    """Build the lookup index from the rows."""
```

**Verify:** the symbol is internal, no doc generator consumes it, and the name plus body already say what it says. Accuracy is not necessity; an accurate restatement is still a restatement. Exported symbols under a docs convention are PROTECTED.

### Obvious why

```go
// use a map for O(1) lookup
seen := map[string]bool{}

// check the user exists before deleting
```

**Verify:** cover the comment and read the code. A reader who infers the reason from the code in front of them did not need the comment. A why survives only when the reason is genuinely not inferable: a non-obvious alternative was rejected, an external contract forces the shape, a failure mode is invisible.

### Intent narration

```python
# we need to fetch the config before starting the workers
config = load_config()
start_workers(config)
```

**Verify:** the code states the order and the data flow. If the ordering is a real constraint the code cannot show, whose violation breaks something invisibly, rewrite it down to that constraint instead.

## Rewrite

### Stale comment contradicting the code

```go
Before: // retries three times
        for i := 0; i < 5; i++ {
After:  // retries five times, matching the upstream rate window
```

**Verify:** read the current behaviour and quote both the comment and the code in the report. Never guess which one is right; when the code looks wrong instead, keep the comment and flag the mismatch.

### Comment made wrong by this PR's own change

**Verify:** compare the comment against the PR diff. A comment that was true before the PR and false after it is the PR author's cleanup debt; fix it here.

### What plus why

```go
Before: // send the batch, chunked to 500 because the API rejects more
After:  // the API rejects batches over 500
```

**Verify:** the what half restates the code. Keep only the why.

### Padded why

```python
Before: # This function is responsible for ensuring that the cache is
        # properly invalidated before we proceed with the update.
After:  # invalidate the cache before updating, or readers see stale data
```

**Verify:** the information is real but buried. Rewrite it plainly without losing the constraint.

### Wrong names, values, or units

```go
Before: // timeout in seconds
        timeoutMs := 5000
After:  // timeout in milliseconds
```

**Verify:** confirm the correct value from the code and its callers before rewriting.

## Keep

Every keep must pass the same test: cover the comment, read the code alone, and name the fact a competent reader loses. No named fact, no keep. The categories:

- Why the code does a thing this way rather than the obvious way, when the reason is not inferable from the code
- Constraints invisible in the code: ordering requirements, external contracts
- Workarounds, together with their issue link or reference
- Units, ranges, invariants, and precision notes
- Warnings about non-obvious failure modes
- Doc comments a convention or generator requires on public APIs

Matching a category by shape is not enough. "Why" comments stating an obvious reason and "warnings" about failures the code plainly shows read like keepers and are removals; the test is the named fact, not the shape.

## Protected

Never remove, never rewrite:

| Kind | Examples |
|------|----------|
| Lint and type directives | `//nolint:gosec`, `# noqa`, `# type: ignore`, `// eslint-disable-next-line`, `# pylint: disable`, `// @ts-expect-error` |
| Build and tooling markers | build tags, `//go:generate`, `# -*- coding: utf-8 -*-`, shebang lines |
| Generated file markers | `Code generated by ... DO NOT EDIT` |
| Legal | licence headers, copyright notices, SPDX identifiers |
| Required doc comments | godoc on exported Go symbols, JSDoc on published package APIs, docstrings a doc generator consumes |
| Structural markers | region markers a tool reads, template placeholders, front matter keys |
| Pragma comments that are code | `# frozen_string_literal: true`, `/* webpackChunkName: "..." */`, `/* istanbul ignore next */`, `/** @type {...} */` consumed by a type checker |
| Sole statement docstrings | a docstring that is the only statement in its function or class body; removing it breaks the syntax |

When unsure whether a comment is protected, keep it.

## Not Actually Comments

Lines that match a comment marker and are not comments. Parse by language, not by grep:

- `//` and `#` inside string literals, URLs, and regular expressions
- `#` in YAML values, anchors, and CSS colours
- `{/* ... */}` in JSX carries different semantics than a plain comment; edit only when certain of the syntax
- Shebang and encoding lines the interpreter reads
- Markdown headings starting with `#` inside template strings or heredocs

When the language is unfamiliar or the syntax is ambiguous, leave the line alone and report it.
