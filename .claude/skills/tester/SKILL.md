---
name: tester
description: This skill should be used when the user asks to "write tests", "add test coverage", "check test coverage", "test this function", "run test audit", "add regression tests", "verify tests pass", "run tests", or "/tester". Verifies, creates, and updates test coverage.
---

# Tester Skill

## Purpose

Dispatch the tester agent to verify, create, or update test coverage. The agent analyzes code, identifies missing coverage, writes tests following best practices (AAA pattern, table-driven tests), and runs the test suite.

## When to Invoke

Invoke this skill after:

- Implementing new features or functions
- Fixing bugs (to add regression tests)
- Refactoring existing code (to verify tests still pass)
- When test coverage needs verification or audit
- Explicit request to write, run, or review tests

## Invocation Modes

### Default: `/tester`

Test current or recent changes. The agent identifies recently modified files and ensures test coverage.

```
Task tool with subagent_type="tester"
prompt: "Review recent code changes and ensure test coverage.
Identify modified files, verify existing tests, add missing tests."
```

### Scoped: `/tester <scope>`

Test only the specified scope (file, module, feature).

```
Task tool with subagent_type="tester"
prompt: "Review and ensure test coverage for: [scope]
Focus only on this area. Verify existing tests, add missing coverage."
```

**Scope examples:**
- `/tester src/auth` - authentication module
- `/tester utils/parser.ts` - specific file
- `/tester API endpoints` - all API routes
- `/tester UserService` - specific class or service

### Comprehensive: `/tester all`

Perform a planned, modular test audit covering every testable area of the repository.

```
Task tool with subagent_type="tester"
prompt: "Perform comprehensive test audit of all repository areas.
Create a TodoWrite plan with one item per testing aspect, then process sequentially.
Enforce minimum 50% overall project code coverage.
Consult references/comprehensive-mode.md for the full aspect checklist, coverage requirements, and execution flow."
```

For detailed testing aspects checklist and example plan, consult **`references/comprehensive-mode.md`**.

## Usage Examples

```
/tester                        # Test recent changes
/tester src/services/payment   # Test payment service only
/tester utils/parser.ts        # Test specific file
/tester all                    # Full project test audit
```

## Additional Resources

### Reference Files

For detailed mode execution flows, consult:
- **`references/comprehensive-mode.md`** - Full audit execution flow, testing aspects checklist, 50% coverage requirements, example TodoWrite plan
