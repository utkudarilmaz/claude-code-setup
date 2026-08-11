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

## pr-body

Writes short, plain-English pull request descriptions and applies them with `gh`.

**Trigger:** When writing a new PR description or updating an existing one

**Responsibilities:**
- Resolve the target PR and its base branch with `gh pr view`
- Read the branch commits, diff, and any linked issue
- Write What, Why, and Files, plus Testing and Next only when there is real content
- Build the Files list from `git diff --name-status -M`, grouped Added, Changed, and Removed, with renames detected
- Keep the prose under 200 words with no emoji and no AI attribution
- Apply the body with `gh pr edit`, or print it in draft mode

**Never:** creates a PR, pushes commits, or invents test results

---

## seo-optimizer

SEO/GEO/AIO optimization expert that improves web content discoverability across traditional search engines, generative AI systems, and AI crawlers.

**Trigger:** After creating or modifying HTML pages, web templates, or web-facing content; when improving search rankings or AI citability

**Responsibilities:**
- Optimize meta tags (title, description, canonical, robots, viewport)
- Enforce heading hierarchy (single H1, logical H2-H6 nesting)
- Add and validate JSON-LD structured data (Schema.org types)
- Add Open Graph and Twitter Card tags
- Improve image optimization (alt text, width/height, lazy loading)
- Strengthen internal linking (descriptive anchors, link depth)
- Improve GEO signals (entity clarity, factual density, FAQ/HowTo schemas)
- Enhance AIO signals (semantic HTML5, machine-readable structure, context density)
- Apply changes directly with before/after tracking
- Produce audit report cards with 0-100 scores per aspect

**Coverage Areas:**

| Area | Focus |
|------|-------|
| SEO | Meta tags, headings, Open Graph, Twitter Cards, images, linking, technical |
| GEO | Entity clarity, factual density, FAQ/HowTo schema, passage optimization |
| AIO | JSON-LD structured data, semantic HTML5, machine readability, context density |

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Model:** opus (complex analysis and editing)

**Modes:**
- **Edit mode (default):** Applies CRITICAL and HIGH fixes directly; flags LOW items as recommendations
- **Audit mode:** Scores each aspect 0-100, produces weighted report card, no file modifications

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

---

## text-slop-cleaner

Editor that rewrites machine sounding prose into plain English and removes comments that do not earn their place.

**Trigger:** After generating documentation, a README, or a PR body; when a file has picked up comments that only restate the code

**Responsibilities:**
- Rewrite padded, hedged, or inflated prose into plain English
- Remove comments that restate the code, keep comments that explain why
- Preserve meaning: every fact, number, caveat, path, command, and warning survives the cut
- Classify each sentence, bullet, and comment as KEEP, REWRITE, CUT, or PROTECTED
- Leave protected content alone
- Report the word count before and after

**Protected Content:**
- Lint and type directives (`//nolint`, `# noqa`, `# type: ignore`, `// eslint-disable`)
- Build and tooling markers (build tags, `//go:generate`, encoding lines, shebangs)
- Generated file markers (`Code generated by ... DO NOT EDIT`)
- Legal (license headers, copyright notices, SPDX identifiers)
- Required doc comments (godoc on exported symbols, JSDoc on published APIs, docstrings a doc generator consumes)
- Structural markers (region markers a tool reads, template placeholders, front matter keys)

**Scope:** Prose and comments only. Never changes code behavior and never edits string literals. Never edits another person's pull request comment, because GitHub does not allow it; reports it instead.

**Modes:**
- **Applied (default):** Rewrites and cuts in place without asking first
- **Check:** Reports the findings only, changes nothing

**Output:** Text Cleanup Report listing what changed, what was protected, what was reported only, and the word count before and after

---

## code-slop-cleaner

Reviewer that judges a change against the purpose it was made for, and separates the work that serves that purpose from the work that does not.

**Trigger:** Before opening a pull request, when a diff is much larger than the task it came from, or when a review says the change does too much

**Not the same as `simplifier`:** `simplifier` asks whether code is well written and looks anywhere in the codebase. `code-slop-cleaner` asks whether a change needed to happen at all, judged against its stated purpose. Use `simplifier` for dead code, complexity, duplication, style, and naming. Use `code-slop-cleaner` for work that crept into a diff.

**Responsibilities:**
- Establish the purpose from the linked issue, PR body, or commit messages before reading a line of the diff
- Stop and ask the user when no purpose can be found, rather than inferring one from the diff
- Group the diff into units by concern, not by file
- Verify every suspicion with a search before reporting it, naming the existing helper, caller, or guarantee found
- Classify each unit as REQUIRED, SUPPORTING, UNNECESSARY, or UNRELATED
- Report by default; remove only in apply mode, then run the project test command

**Classification:**

| Class | Meaning | Action |
|-------|---------|--------|
| REQUIRED | The purpose fails without it | Keep |
| SUPPORTING | Needed to ship the required work: tests for new behavior, a migration, an import, a config key the code reads | Keep |
| UNNECESSARY | Does not serve the purpose and nothing depends on it | Remove |
| UNRELATED | Real work, but a different change | Split out |

UNRELATED is not a criticism. The work is fine and belongs in its own commit.

**Modes:**
- **Report (default):** Classifies every unit and changes nothing
- **Apply:** Removes the UNNECESSARY units, smallest blast radius first, then runs the project test command and reports the result honestly, including the output when it fails

**Never:** removes UNRELATED work, flags tests covering new behavior, flags error handling at real input and output boundaries, judges style or naming, recommends adding anything, or claims a test run it did not perform

**Output:** Change Necessity Report with the purpose it settled on, where that purpose came from, and per-unit findings with the search that verified each one

---

## explain

Explains code, changes, pull requests, and concepts in words anyone can follow.

**Trigger:** When picking up unfamiliar code, when a diff or pull request is hard to follow, or when a term in the codebase has no obvious meaning

**Responsibilities:**
- Work out the target and state it on the first line, so a wrong guess is visible immediately
- Cover what it is, what it does, why it exists, and how it fits, plus gotchas when real ones exist
- Read the callers before saying why something exists, and check commit messages and linked issues for the reason behind a change
- Define any unavoidable term in the sentence it first appears in, and give one concrete example with real values
- Say when the reason for something cannot be determined, what was checked, and what would answer it
- Keep what was read apart from what was inferred

**Target Detection:**

| Argument | Target |
|----------|--------|
| none, tree dirty | The uncommitted changes |
| none, tree clean | The most recent commit |
| an existing path | That file or directory |
| a number or PR url | That pull request |
| a symbol in the repository | That function, type, or class |
| anything else | A concept question, answered in this codebase's terms |

**Scope:** Terminal output only. Writes no files and publishes nothing. Explains rather than reviews, and never suggests changes.

**Modes:**
- **Default:** What it is, what it does, why it exists, how it fits, and watch out for. Empty sections are dropped rather than padded
- **Deep:** Adds a walkthrough in execution order anchored with `file:line`, a worked example traced from a concrete input to its output, and the edge cases the code handles

**Anti bluff rule:** Never invents a rationale. An honest gap beats a plausible guess, since the reader acts on what they are told. Never uses `simply`, `just`, `obviously`, `of course`, or `as you know`.
