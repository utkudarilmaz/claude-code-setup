---
name: security-review
description: This skill should be used when the user asks to "security review", "check for vulnerabilities", "audit security", "review code for security", "check for secrets", "OWASP review", "check for injection", "review API security", or "/security-review". Covers authentication, input validation, data exposure, secrets, and OWASP Top 10.
---

# Security Review Skill

## Purpose

Dispatch the security-reviewer agent to perform security-focused code review. The agent identifies vulnerabilities across 13 security areas including authentication, injection, data exposure, secrets management, OWASP Top 10, API security, cryptography, and modern attack vectors.

## When to Invoke

Invoke this skill when:

- Reviewing authentication or authorization code
- Handling payment or sensitive data processing
- Implementing or modifying API endpoints
- Reviewing user input handling
- Preparing for a security audit or release
- Explicit request to check for vulnerabilities or secrets

## Invocation Modes

### Default: `/security-review`

Review recent code changes for security vulnerabilities.

```
Task tool with subagent_type="security-reviewer"
prompt: "Review recent code changes for security vulnerabilities.
Focus on: auth, input validation, data exposure, secrets, OWASP Top 10.
Report findings with severity, location, and remediation."
```

### Scoped: `/security-review <path>`

Review specific files or modules for security issues.

```
Task tool with subagent_type="security-reviewer"
prompt: "Perform security review of: [path]
Focus on: auth, input validation, data exposure, secrets, OWASP Top 10.
Report findings with severity, location, and remediation."
```

**Scope examples:**
- `/security-review src/auth` - authentication module
- `/security-review api/handlers` - API endpoints
- `/security-review lib/payment.ts` - specific file
- `/security-review controllers/` - all controllers

### Comprehensive: `/security-review all`

Perform a full security audit of the entire codebase across all 13 security areas.

```
Task tool with subagent_type="security-reviewer"
prompt: "Perform comprehensive security audit of the entire codebase.
Create a TodoWrite plan with one item per security area, then process sequentially.
Consult references/comprehensive-mode.md for the 13 security areas and OWASP cross-reference."
```

For the full 13-area checklist, OWASP cross-reference table, and example plan, consult **`references/comprehensive-mode.md`**.

## Usage Examples

```
/security-review                   # Review recent changes for vulnerabilities
/security-review src/auth          # Deep review of authentication code
/security-review api/handlers      # Review API endpoints
/security-review all               # Full 13-area security audit
```

## Additional Resources

### Reference Files

For detailed mode execution flows, consult:
- **`references/comprehensive-mode.md`** - Full audit execution flow, 13 security areas checklist, OWASP Top 10 cross-reference table, example TodoWrite plan
