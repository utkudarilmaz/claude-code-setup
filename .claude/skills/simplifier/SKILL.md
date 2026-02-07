---
name: simplifier
description: This skill should be used when the user asks to "clean up code", "remove dead code", "simplify this function", "reduce complexity", "find unused imports", "code quality sweep", or "/simplifier". Focuses on dead code, complexity reduction, and duplication removal.
---

# Simplifier

## Overview

Dispatch the simplifier agent to cleanup dead code, reduce complexity, and improve code quality. Focuses on Go and JavaScript/TypeScript codebases.

## When to Use

- After implementing features (cleanup pass)
- After refactoring (dead code check)
- When code feels too complex
- When duplication is suspected
- With "all" for full project quality audit
- With specific scope for targeted cleanup

## Invocation Modes

### Default: `/simplifier`

Scans recent changes for cleanup opportunities.

```
Task tool with subagent_type="simplifier"
prompt: "Review recent code changes for dead code, complexity, and quality issues.
Identify modified files, find cleanup opportunities, suggest simplifications."
```

### Scoped: `/simplifier <scope>`

Analyzes only the specified scope (file, module, function).

```
Task tool with subagent_type="simplifier"
prompt: "Review and simplify code in: [scope]
Focus only on this area. Find dead code, reduce complexity, improve quality."
```

**Scope examples:**
- `/simplifier src/handlers` - simplify handlers module
- `/simplifier utils/parser.ts` - simplify specific file
- `/simplifier internal/service` - simplify Go service package
- `/simplifier UserService` - simplify specific class/service

### Comprehensive: `/simplifier all`

**Planned, modular code quality audit** covering the entire repository.

**CRITICAL: Do not skip any aspect. Continue until ALL areas are reviewed.**

#### Execution Flow

1. **Explore repository structure** - Identify all code areas
2. **Create TodoWrite plan** - One todo item per module/package
3. **Process sequentially** - Complete each area before moving to next
4. **Mark progress** - Update todos as each section completes

#### Quality Aspects to Review

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

#### Example: Full Audit

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

Then dispatches simplifier agent for each area sequentially.

## What the Agent Does

- Detects unused imports, variables, functions
- Finds unreachable code paths
- Identifies complexity hotspots
- Spots duplicated logic
- Suggests simplifications with before/after code
- Reports severity (HIGH/MEDIUM/LOW)

## Examples

**After adding a feature:**
```
/simplifier
→ Reviews recent changes, suggests cleanup
```

**Simplify specific module:**
```
/simplifier src/services/payment
→ Focuses only on payment service
```

**Simplify a complex function:**
```
/simplifier processOrder
→ Analyzes and simplifies the function
```

**Full project audit:**
```
/simplifier all
→ Creates plan, systematically reviews every module
```

## Language Focus

| Language | Key Checks |
|----------|------------|
| Go | Unchecked errors, empty interface abuse, defer in loops, context propagation |
| JS/TS | `any` abuse, unused hooks deps, mixed async patterns, optional chaining opportunities |
| Python | Mutable defaults, broad exceptions, unused imports |
