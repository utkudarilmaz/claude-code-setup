# Agents Reference

Agents are specialized AI assistants that contain domain expertise and execution workflows. They are invoked via the Task tool with `subagent_type="<name>"`.

## docs

Documentation architect that manages README.md, CLAUDE.md, API docs, postman collections, and architecture diagrams.

**Trigger:** After code changes affecting documentation

**Responsibilities:**
- Analyze code changes and identify affected docs
- Update documentation files for accuracy
- Enforce modular structure (300-line file limit with docs/ subdirectories)
- Maintain architecture diagrams (.drawio files with PNG exports)
- Maintain consistent formatting and style
- Use camelCase for JSON field names

**Supported Files:**
- README.md, CLAUDE.md (core documentation)
- postman_collection.json (API collections)
- docs/architecture/ (system design, diagrams, ADRs)
- docs/guides/ (user guides, tutorials)
- docs/api/ (endpoint docs, schemas)
- .drawio files (architecture diagrams)

---

## tester

Test specialist ensuring comprehensive coverage across Go, JavaScript/TypeScript, and Python projects.

**Trigger:** After implementing features, fixing bugs, or refactoring

**Responsibilities:**
- Write new tests (happy path, edge cases, errors)
- Update existing tests when code changes
- Run test suites and report results
- Follow Arrange-Act-Assert pattern and table-driven tests where appropriate

**Language Support:**

Go:
```bash
go test -v ./path/to/package/...           # Run tests
go test -v ./package -run TestName         # Single test
go test -coverprofile=coverage.out ./...   # Coverage
```

JavaScript/TypeScript: Uses project-configured runner (Jest, Vitest). Follows `*.test.ts` / `*.spec.ts` conventions.

Python: Uses pytest with `test_*.py` / `*_test.py` conventions.

---

## pr-check

PR quality reviewer that verifies PRs against a quality checklist before merging.

**Trigger:** Before merging a PR or after addressing review comments

**Checklist:**
- Tests added/updated for code changes
- No hardcoded secrets or credentials
- Error handling is appropriate
- Breaking changes documented
- Commit messages follow conventions
- Documentation updated if needed
- Dependencies justified and secure
- No obvious code smells or anti-patterns

**Focus Modes:** tests, security, docs, breaking

---

## simplifier

Code quality expert that removes dead code, reduces complexity, and eliminates duplication without changing behavior.

**Trigger:** After feature implementation, refactoring, or when code quality issues are suspected

**Responsibilities:**
- Detect unused imports, variables, functions, and unreachable code
- Identify complexity hotspots (deep nesting, long functions, complex booleans)
- Find duplicated logic and suggest consolidation
- Classify findings by severity (HIGH/MEDIUM/LOW) and confidence (CERTAIN/LIKELY/POSSIBLE)
- Report only CERTAIN or LIKELY findings; flag POSSIBLE items separately

**Language Support:** Go, JavaScript/TypeScript, Python (language-specific pattern references applied per scope)

**Output:** Code Simplification Report with before/after code examples and severity summary table

---

## security-reviewer

Security expert that performs comprehensive security-focused code review.

**Trigger:** When reviewing auth, payment, API endpoints, or input handling

**Core Focus Areas:**
- Authentication & Authorization (auth flows, session management, access control, privilege escalation)
- Input Validation (SQL injection, XSS, command injection, path traversal, XXE, LDAP, template injection)
- Data Exposure (PII leaks, sensitive data in logs, verbose errors, debug info, stack traces)
- Secrets Management (hardcoded credentials, API keys, tokens, weak credentials)
- Cryptography (weak algorithms, key management, TLS configuration, timing attacks)

**Extended Security Coverage:**
- API Security (rate limiting, mass assignment, GraphQL attacks, CORS, OAuth/OIDC, versioning)
- File Upload Security (type validation, size limits, malicious content, path traversal, polyglot files)
- Business Logic Vulnerabilities (race conditions, workflow bypass, price manipulation, replay attacks)
- Client-Side Security (localStorage tokens, postMessage validation, clickjacking, DOM clobbering, prototype pollution)
- HTTP Security Headers & Cookies (CSP, HSTS, X-Frame-Options, Secure/HttpOnly/SameSite flags)
- Dependency Security (CVEs, outdated packages, supply chain risks, transitive dependencies)
- Modern Attack Vectors (prototype pollution, ReDoS, request smuggling, WebSocket security, cache poisoning, SSRF, insecure deserialization)

**OWASP Top 10 (2021) Coverage:** A01-A10 with cross-references to extended areas

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Language-Specific Patterns:** Python, Go

---

## release-notes

Release documentation specialist that generates user-friendly release notes.

**Trigger:** When preparing a release or creating release announcements

**Responsibilities:**
- Parse git history since last tag
- Categorize changes by type (features, fixes, improvements)
- Write from user perspective with emojis
- Highlight breaking changes with migration guidance
- Format for GitHub releases or announcements

---

## changelog-generator

Generates CHANGELOG.md from git history using Keep a Changelog format.

**Trigger:** When explicitly requested via `/changelog`

**Commit Type Mapping:**

| Prefix | Changelog Section |
|--------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:`, `perf:` | Changed |
| `BREAKING CHANGE:` | Breaking Changes |
| `deprecate:` | Deprecated |
| `remove:` | Removed |
| `security:` | Security |

---

## devops

DevOps architect for infrastructure code review and design.

**Trigger:** When working with Kubernetes, Helm, ArgoCD, Terraform, or Terragrunt

**Responsibilities:**
- Review infrastructure code for security, best practices, reliability
- Design and generate production-ready configurations
- Identify misconfigurations (privileged containers, missing RBAC, no resource limits)
- Check Terraform state management, modules, and security
- Verify ArgoCD sync policies and health checks
- Rate severity: CRITICAL/HIGH/MEDIUM/LOW

**Infrastructure Types:**
- Kubernetes: Deployments, Services, ConfigMaps, Secrets, RBAC, NetworkPolicies
- Helm: Chart structure, values management, templates, hooks
- ArgoCD: Applications, ApplicationSets, sync policies, progressive delivery
- Terraform: Modules, state management, providers, security
- Terragrunt: DRY configurations, dependency management, remote state
