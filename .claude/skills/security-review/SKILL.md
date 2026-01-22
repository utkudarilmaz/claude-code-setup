---
name: security-review
description: Perform security-focused code review
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

#### Security Areas to Review

| Area | What to Check |
|------|---------------|
| Authentication | Login, session, password, MFA |
| Authorization | Access control, IDOR, privilege escalation |
| Input Validation | Injection (SQL, XSS, command, path) |
| Data Exposure | PII, logs, error messages, debug info |
| Secrets | Hardcoded credentials, API keys, tokens |
| Cryptography | Weak algorithms, key management |
| API Security | Rate limiting, auth, input validation |
| File Handling | Upload, path traversal, permissions |
| Dependencies | Known vulnerabilities, outdated packages |
| Configuration | Security headers, CORS, default settings |

## What the Agent Does

- Maps entry points and data flows
- Identifies vulnerable code patterns
- Classifies by OWASP Top 10 categories
- Rates severity (CRITICAL/HIGH/MEDIUM/LOW)
- Provides specific remediation with code examples

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

The agent checks for all OWASP 2021 categories:
- A01: Broken Access Control
- A02: Cryptographic Failures
- A03: Injection
- A04: Insecure Design
- A05: Security Misconfiguration
- A06: Vulnerable Components
- A07: Auth Failures
- A08: Integrity Failures
- A09: Logging Failures
- A10: SSRF
