# Comprehensive Mode: `/tester all`

Perform a planned, modular test audit covering every testable area of the repository.

**Do not skip any aspect. Continue until ALL areas are reviewed.**

## Execution Flow

1. **Explore repository structure** - Identify all testable code areas
2. **Create TodoWrite plan** - One todo item per testing aspect
3. **Process sequentially** - Complete each aspect before moving to the next
4. **Mark progress** - Update todos as each section completes

## Testing Aspects to Review

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

## Example TodoWrite Plan

When `/tester all` is invoked, create todos such as:

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

Dispatch the tester agent for each aspect sequentially, marking each complete as it finishes.

## Coverage Requirements

The full audit enforces a minimum **50% overall project code coverage** threshold:

1. **Measure coverage** - Run the project's coverage tool after writing tests for each aspect
2. **Track overall project coverage** - Record the total coverage percentage across the entire codebase
3. **Flag if below 50%** - Overall project coverage under 50% is a blocking finding
4. **Prioritize by risk** - Focus on business-critical logic, security-sensitive code, and frequently-changed areas first
5. **Report coverage gaps** - Provide a clear list of what remains untested with recommended priority

### Coverage Commands by Language

| Language | Command |
|----------|---------|
| Go | `go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out` |
| JavaScript/TypeScript | `npx vitest --coverage` or `npx jest --coverage` |
| Python | `pytest --cov=. --cov-report=term-missing` |

### Final Coverage Report

Include a project coverage summary in the audit output:

| Metric | Value |
|--------|-------|
| Overall project coverage | 62% |
| Status | PASS (above 50%) |
| Lines covered | 1,240 / 2,000 |

Mark the audit as **incomplete** if overall project coverage remains below 50% after test additions. Document remaining gaps and recommend follow-up actions.
