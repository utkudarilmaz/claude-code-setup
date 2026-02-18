# Comprehensive Mode: `/security-review all`

Perform a full security audit of the entire codebase.

**Do not skip any area. Continue until ALL code is reviewed.**

## Execution Flow

1. **Map attack surface** - Identify all entry points and data flows
2. **Create TodoWrite plan** - One todo item per security area
3. **Process sequentially** - Review each area thoroughly
4. **Mark progress** - Update todos as each section completes

## 13 Security Areas to Review

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

## OWASP Top 10 Cross-Reference

The agent extends OWASP Top 10 with 8 additional security focus areas (§6-§13):

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

## Example TodoWrite Plan

When `/security-review all` is invoked, create todos such as:

- [ ] Review authentication and authorization flows
- [ ] Check all input validation and injection points
- [ ] Audit data exposure (PII, logs, error messages)
- [ ] Scan for hardcoded secrets and credentials
- [ ] Verify OWASP Top 10 compliance
- [ ] Review API security (rate limiting, CORS, OAuth)
- [ ] Check file upload security
- [ ] Audit cryptographic implementations
- [ ] Review business logic for race conditions and bypass
- [ ] Check client-side security
- [ ] Verify HTTP security headers and cookie settings
- [ ] Scan dependencies for CVEs and supply chain risks
- [ ] Check for modern attack vectors (ReDoS, SSRF, deserialization)

Dispatch the security-reviewer agent for each area sequentially, marking each complete as it finishes.
