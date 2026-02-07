---
name: tester
description: This skill should be used when the user asks to "write tests", "add test coverage", "check test coverage", "test this function", "run test audit", "add regression tests", or "/tester". Verifies, creates, and updates test coverage.
---

# Tester

## Overview

Dispatch the tester agent to verify, create, or update test coverage. The agent analyzes code and ensures comprehensive testing.

## When to Use

- After implementing new features
- After fixing bugs (add regression tests)
- After refactoring existing code
- When test coverage needs verification
- With "all" for full project test audit
- With specific scope for targeted testing

## Invocation Modes

### Default: `/tester`

Tests current or recent changes. Agent identifies recently modified files and ensures test coverage.

```
Task tool with subagent_type="tester"
prompt: "Review recent code changes and ensure test coverage.
Identify modified files, verify existing tests, add missing tests."
```

### Scoped: `/tester <scope>`

Tests only the specified scope (file, module, feature).

```
Task tool with subagent_type="tester"
prompt: "Review and ensure test coverage for: [scope]
Focus only on this area. Verify existing tests, add missing coverage."
```

**Scope examples:**
- `/tester src/auth` - test authentication module
- `/tester utils/parser.ts` - test specific file
- `/tester API endpoints` - test all API routes
- `/tester UserService` - test specific class/service

### Comprehensive: `/tester all`

**Planned, modular test audit** covering every aspect of the repository.

**CRITICAL: Do not skip any aspect. Continue until ALL areas are reviewed.**

#### Execution Flow

1. **Explore repository structure** - Identify all testable code areas
2. **Create TodoWrite plan** - One todo item per testing aspect
3. **Process sequentially** - Complete each aspect before moving to next
4. **Mark progress** - Update todos as each section completes

#### Testing Aspects to Review

Process each area one-by-one:

| Aspect | What to Test |
|--------|--------------|
| Unit tests | Individual functions, methods, utilities |
| Integration tests | Module interactions, service connections |
| API tests | Endpoints, request/response, error handling |
| Component tests | UI components, rendering, user interactions |
| Model tests | Data models, validation, relationships |
| Service tests | Business logic, service layer |
| Middleware tests | Auth, validation, error handling middleware |
| Utility tests | Helper functions, formatters, parsers |
| Edge cases | Boundary conditions, null handling, errors |
| Error handling | Exception paths, error responses |
| Configuration | Config loading, environment handling |
| Database | Queries, transactions, migrations |

#### Example: Full Audit

```
/tester all
```

Creates todos like:
- [ ] Audit and test utility functions
- [ ] Audit and test data models
- [ ] Audit and test service layer
- [ ] Audit and test API endpoints
- [ ] Audit and test middleware
- [ ] Audit and test components
- [ ] Audit and test integration points
- [ ] Audit and test error handling paths
- [ ] Audit and test edge cases
- [ ] Verify overall test coverage

Then dispatches tester agent for each aspect sequentially, marking complete as each finishes.

## What the Agent Does

- Analyzes code for testable logic
- Identifies missing test coverage
- Creates new test files/cases
- Updates existing tests after refactoring
- Runs test suite and reports results
- Adds regression tests for bug fixes

## Examples

**After adding a feature:**
```
/tester
→ Reviews recent changes, adds tests for new functionality
```

**Test specific module:**
```
/tester src/services/payment
→ Focuses only on payment service tests
```

**Full project audit:**
```
/tester all
→ Creates plan, systematically tests every aspect
```
