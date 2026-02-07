---
name: security-review
description: This skill should be used when the user asks to "security review", "check for vulnerabilities", "audit security", "review code for security", "check for secrets", "OWASP review", or "/security-review". Covers authentication, input validation, data exposure, secrets, and OWASP Top 10.
---

# Security Review

## Overview

Dispatch the security-reviewer agent to perform security-focused code review. The agent identifies vulnerabilities in authentication, input validation, data exposure, secrets management, and OWASP Top 10 categories.

## When to Use

- When reviewing authentication or authorization code
- When handling payment or sensitive data processing
- When implementing API endpoints
- When reviewing user input handling
- For security audit before release
- With "all" for comprehensive security audit

## Invocation Modes

### Default: `/security-review`

Reviews recent code changes for security vulnerabilities.

```
Task tool with subagent_type="security-reviewer"
prompt: "Review recent code changes for security vulnerabilities.
Focus on: auth, input validation, data exposure, secrets, OWASP Top 10.
Report findings with severity, location, and remediation."
```

### Scoped: `/security-review <path>`

Reviews specific files or modules for security issues.

```
Task tool with subagent_type="security-reviewer"
prompt: "Perform security review of: [path]
Focus on: auth, input validation, data exposure, secrets, OWASP Top 10.
Report findings with severity, location, and remediation."
```

**Scope examples:**
- `/security-review src/auth` - review authentication module
- `/security-review api/handlers` - review API endpoints
- `/security-review lib/payment.ts` - review specific file
- `/security-review controllers/` - review all controllers

### Comprehensive: `/security-review all`

**Full security audit** of the entire codebase.

**CRITICAL: Do not skip any area. Continue until ALL code is reviewed.**

#### Execution Flow

1. **Map attack surface** - Identify all entry points and data flows
2. **Create TodoWrite plan** - One todo item per security area
3. **Process sequentially** - Review each area thoroughly
4. **Mark progress** - Update todos as each section completes

#### 13 Security Areas to Review

| # | Area | What to Check |
|---|------|---------------|
| 1 | Authentication | Login, session, password, MFA, JWT |
| 2 | Input Validation | Injection (SQL, XSS, command, path, XXE, LDAP, template) |
| 3 | Data Exposure | PII, logs, error messages, debug info, stack traces |
| 4 | Secrets | Hardcoded credentials, API keys, tokens, version control |
| 5 | OWASP Top 10 | A01-A10 (2021) with cross-references to other areas |
| 6 | API Security | Rate limiting, mass assignment, GraphQL, CORS, OAuth/OIDC |
| 7 | File Upload | Type validation, size limits, malicious content, polyglots |
| 8 | Cryptography | Hashing, salts, key derivation, weak ciphers, TLS, timing |
| 9 | Business Logic | Race conditions, workflow bypass, integer overflow, replay |
| 10 | Client-Side | localStorage tokens, postMessage, clickjacking, prototype pollution |
| 11 | HTTP Headers/Cookies | CSP, HSTS, X-Frame-Options, Secure/HttpOnly/SameSite |
| 12 | Dependencies | CVEs, outdated packages, supply chain, transitive deps |
| 13 | Modern Attacks | Prototype pollution, ReDoS, smuggling, WebSocket, SSRF, deserialization |

## What the Agent Does

- Maps entry points and data flows across 13 security focus areas
- Identifies vulnerable code patterns (general + language-specific for Python/Go)
- Checks expanded OWASP Top 10 with cross-references to 8 additional security areas
- Covers modern attack vectors (prototype pollution, ReDoS, request smuggling, WebSocket, SSRF)
- Rates severity (CRITICAL/HIGH/MEDIUM/LOW)
- Provides specific remediation with secure code examples

## Severity Levels

| Level | Description |
|-------|-------------|
| CRITICAL | RCE, auth bypass, data breach potential |
| HIGH | Significant data exposure, privilege escalation |
| MEDIUM | Limited impact vulnerabilities |
| LOW | Minor issues, defense in depth |

## Output Format

The agent produces a security report with:

```markdown
## Security Review Report

### Executive Summary
[X critical, Y high, Z medium findings]

### Findings

#### [SEVERITY] Finding Title
- **Location**: file:line
- **Type**: Vulnerability type
- **Issue**: Description
- **Remediation**: How to fix (with code)

### Summary Table
| Severity | Count |
|----------|-------|
| Critical | X |
| High | Y |
| Medium | Z |
| Low | W |
```

## Examples

**Review recent changes:**
```
/security-review
→ Checks recent commits for security issues
```

**Review specific module:**
```
/security-review src/auth
→ Deep security review of authentication code
```

**Full security audit:**
```
/security-review all
→ Comprehensive audit with TodoWrite planning
```

## OWASP Top 10 Coverage

The agent checks all OWASP 2021 categories with cross-references to expanded areas:

| OWASP Risk | Expanded Coverage |
|------------|-------------------|
| A01: Broken Access Control | §1 Authentication, §6 API Security, §9 Business Logic |
| A02: Cryptographic Failures | §3 Data Exposure, §8 Cryptography |
| A03: Injection | §2 Input Validation, §13 Modern Attack Vectors |
| A04: Insecure Design | §9 Business Logic, §10 Client-Side Security |
| A05: Security Misconfiguration | §6 API Security, §11 HTTP Headers/Cookies |
| A06: Vulnerable Components | §12 Dependency Security |
| A07: Auth Failures | §1 Authentication, §6 API Security |
| A08: Integrity Failures | §12 Dependency Security, §13 Modern Attack Vectors |
| A09: Logging Failures | §3 Data Exposure |
| A10: SSRF | §13 Modern Attack Vectors |

**Note:** Agent extends OWASP Top 10 with 8 additional security focus areas (§6-§13) covering API security, file uploads, business logic, client-side security, HTTP headers, dependencies, and modern attack vectors.
