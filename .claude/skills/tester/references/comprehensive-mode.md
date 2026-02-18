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

## Coverage Analysis

During the comprehensive audit, for each module:

1. **Identify untested code paths** - Functions, branches, or error conditions without tests
2. **Prioritize by risk** - Focus on business-critical logic, security-sensitive code, and frequently-changed modules first
3. **Report coverage gaps** - Provide a clear list of what remains untested and recommended priority
