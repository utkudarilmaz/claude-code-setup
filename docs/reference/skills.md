# Skills Reference

Skills are user-facing slash commands that dispatch work to agents. Each skill supports multiple invocation modes.

## /docs

Synchronize documentation with code changes.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/docs` | Document recent changes |
| Scoped | `/docs <scope>` | Document specific area (file, module, feature) |
| Comprehensive | `/docs all` | Complete repository documentation audit with TodoWrite planning |
| Simplifier | `/docs simplifier` | Restructure large documentation into modular files |

**What it does:**
- **Default:** Reviews recent changes and updates affected documentation (README.md, CLAUDE.md, API docs)
- **Scoped:** Focuses only on specified area (e.g., module, API, specific file)
- **Comprehensive:** Creates TodoWrite plan covering all documentation aspects (overview, installation, API, architecture, etc.), processes each aspect sequentially
- **Simplifier:** Analyzes documentation structure, identifies files >300 lines, proposes and executes modular split with cross-linking

**File Management:**
- Enforces 300-line limit per file
- Creates modular structure: docs/architecture/, docs/guides/, docs/api/
- Manages .drawio architecture diagrams with PNG exports
- Validates postman_collection.json with camelCase fields

**Examples:**
```
/docs                    # Document recent changes
/docs src/auth           # Document authentication module
/docs API                # Document all API endpoints
/docs README             # Update only README.md
/docs config             # Document configuration options
/docs UserService        # Document specific class/service
/docs all                # Full documentation audit with planning
/docs simplifier         # Restructure large documentation files
/docs architecture       # Update architecture docs and diagrams
/docs postman            # Validate API collection
```

---

## /tester

Verify and create test coverage.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/tester` | Test recent changes |
| Scoped | `/tester <scope>` | Test specific area (file, module, feature) |
| Comprehensive | `/tester all` | Complete test coverage audit with TodoWrite planning |

**What it does:**
- **Default:** Identifies recently modified files and ensures test coverage
- **Scoped:** Tests only specified area (file, module, or feature)
- **Comprehensive:** Creates TodoWrite plan covering all testing aspects (unit, integration, API, components, edge cases), processes each sequentially

**Examples:**
```
/tester                      # Test recent changes
/tester src/auth             # Test authentication module
/tester utils/parser.ts      # Test specific file
/tester API endpoints        # Test all API routes
/tester UserService          # Test specific class/service
/tester all                  # Full test audit with planning
```

---

## /pr-check

Review current PR against quality checklist before merging.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/pr-check` | Review current PR against full quality checklist |
| Focused | `/pr-check <focus>` | Review with emphasis on specific aspect |

**What it does:**
- Uses `gh pr view` and `gh pr diff` to analyze the current PR
- Evaluates against quality checklist: tests, secrets, error handling, breaking changes, commits, docs
- Produces pass/fail report with overall verdict (Ready to Merge / Changes Required)
- **Focused mode:** Prioritizes specified aspect while still checking other items

**Examples:**
```
/pr-check                # Full quality review
/pr-check tests          # Focus on test coverage and quality
/pr-check security       # Focus on secrets, auth, input validation
/pr-check docs           # Focus on documentation completeness
/pr-check breaking       # Focus on breaking changes and migration
```

---

## /security-review

Perform security-focused code review.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/security-review` | Review recent changes for security vulnerabilities |
| Scoped | `/security-review <path>` | Review specific file/module for security issues |
| Comprehensive | `/security-review all` | Complete security audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent commits for security vulnerabilities
- **Scoped:** Deep security review of specified file/module
- **Comprehensive:** Creates TodoWrite plan covering all 13 security focus areas, processes each thoroughly

**13 Security Focus Areas:**
1. Authentication & Authorization
2. Input Validation
3. Data Exposure
4. Secrets Management
5. OWASP Top 10 (2021)
6. API Security
7. File Upload Security
8. Cryptography
9. Business Logic Vulnerabilities
10. Client-Side Security
11. HTTP Security Headers & Cookies
12. Dependency Security
13. Modern Attack Vectors

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Examples:**
```
/security-review                  # Review recent changes
/security-review src/auth         # Deep review of authentication module
/security-review api/handlers     # Review API endpoints
/security-review lib/payment.ts   # Review specific file
/security-review controllers/     # Review all controllers
/security-review all              # Comprehensive security audit with planning
```

---

## /changelog

Generate or update changelog, or create release notes.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/changelog` | Update CHANGELOG.md from git history (Keep a Changelog format) |
| Release | `/changelog release` | Generate user-friendly release notes for latest version |
| Versioned | `/changelog <version>` | Generate release notes for specific version or range |

**What it does:**
- **Default:** Updates or creates CHANGELOG.md using Keep a Changelog format, includes all versions from git tags plus [Unreleased] section
- **Release mode:** Generates announcement-style release notes from last tag to HEAD, formatted for GitHub releases or announcements
- **Versioned mode:** Generates release notes for specific version or version range

**Agent Dispatch:**
- `/changelog` → `changelog-generator` agent (CHANGELOG.md file)
- `/changelog release` → `release-notes` agent (release announcement markdown)
- `/changelog <version>` → `release-notes` agent (version-specific notes)

**Examples:**
```
/changelog                # Update CHANGELOG.md
/changelog release        # Generate GitHub release notes for latest version
/changelog 2.0.0          # Generate notes for version 2.0.0
/changelog 1.5.0..2.0.0   # Generate notes for version range
```

---

## /simplifier

Cleanup dead code and reduce complexity.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/simplifier` | Cleanup recent changes |
| Scoped | `/simplifier <scope>` | Cleanup specific area (file, module, directory) |
| Comprehensive | `/simplifier all` | Complete code quality audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent changes for dead code, unused imports, overly complex functions
- **Scoped:** Focuses cleanup on specified area
- **Comprehensive:** Creates TodoWrite plan covering all aspects (dead code, complexity, patterns, organization), processes each sequentially

**Examples:**
```
/simplifier                  # Cleanup recent changes
/simplifier src/utils        # Cleanup utils directory
/simplifier handlers/        # Cleanup all handlers
/simplifier all              # Full code quality audit with planning
```

---

## /devops

Review and design infrastructure configurations.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/devops` | Review recent infrastructure changes |
| Scoped | `/devops <context>` | Review or design based on context |
| Comprehensive | `/devops all` | Complete infrastructure audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent IaC changes for security, best practices, reliability
- **Scoped:** Review specific files/directories OR design new configurations based on context
- **Comprehensive:** Creates TodoWrite plan covering all infrastructure types (K8s, Helm, ArgoCD, Terraform, Terragrunt), processes each thoroughly

**Infrastructure Coverage:**
- Kubernetes: Security contexts, resource limits, probes, RBAC, NetworkPolicies
- Helm: Chart structure, values templating, defaults, documentation
- ArgoCD: Sync policies, health checks, RBAC, progressive delivery
- Terraform: State management, modules, security, variable validation
- Terragrunt: DRY patterns, dependencies, remote state configuration

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Examples:**
```
/devops                              # Review recent infrastructure changes
/devops review k8s/                  # Review Kubernetes manifests
/devops review terraform/modules/vpc # Review Terraform module
/devops design helm chart for redis  # Generate Helm chart
/devops design argocd app for apis   # Generate ArgoCD config
/devops review values.yaml           # Review Helm values
/devops all                          # Full infrastructure audit with planning
```

---

## strategic-compact

Hook that suggests context compaction at logical intervals.

**Why Manual Compaction:**
- Auto-compact happens at arbitrary points, often mid-task
- Strategic compacting preserves context through logical phases
- Compact after exploration, before execution

**Trigger Points:**
- After 50 tool calls (configurable via `COMPACT_THRESHOLD`)
- Every 25 calls thereafter
