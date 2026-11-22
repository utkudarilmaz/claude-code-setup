# Comprehensive Mode

Execution guide for `/simplifier all`. The audit covers every code area of the repository, one at a time, so nothing is skipped.

## Execution Flow

1. **Explore repository structure** - Identify all code areas
2. **Create TodoWrite plan** - One todo item per module/package
3. **Process sequentially** - Complete each area before moving to next
4. **Mark progress** - Update todos as each section completes

## Quality Aspects to Review

Process each area one-by-one:

| Aspect | What to Check |
|--------|---------------|
| Dead imports | Unused imports across all files |
| Dead variables | Unused variables and constants |
| Dead functions | Unused exported/internal functions |
| Dead code paths | Unreachable code after returns |
| Commented code | Old code blocks that should be removed |
| Complexity | Deeply nested conditionals, long functions |
| Duplication | Repeated code patterns, copy-paste |
| Magic values | Hardcoded numbers and strings |
| Naming | Unclear or inconsistent names |
| Patterns | Inconsistent coding patterns |

## Example Plan

```
/simplifier all
```

Creates todos like:
- [ ] Scan and cleanup src/handlers/
- [ ] Scan and cleanup src/services/
- [ ] Scan and cleanup src/utils/
- [ ] Scan and cleanup src/models/
- [ ] Scan and cleanup internal/
- [ ] Review cross-cutting patterns
- [ ] Generate final quality report

Then the simplifier agent is dispatched for each area sequentially.

## Language-Specific Patterns

Detect the primary language(s) in each area and include the matching reference content in the dispatch prompt, as described in SKILL.md:

| Scope Language | Reference File |
|----------------|----------------|
| Go | `references/go-patterns.md` |
| JavaScript / TypeScript | `references/js-ts-patterns.md` |
| Python | `references/python-patterns.md` |
| Rust | `references/rust-patterns.md` |
