---
name: docs
description: Use when code changes are made that could affect documentation, or with "all" argument for comprehensive repository-wide documentation audit
---

# Docs

## Overview

Dispatch the docs agent to synchronize documentation with code changes. The agent updates README.md, CLAUDE.md, API docs, and other documentation files.

## When to Use

- After implementing new features
- After modifying APIs or endpoints
- After changing configuration options
- After restructuring files or directories
- After updating dependencies
- After any significant code modification
- With "all" for full repository documentation audit
- With specific scope for targeted documentation

## Invocation Modes

### Default: `/docs`

Documents current or recent changes. Agent identifies recently modified files and updates related documentation.

```
Task tool with subagent_type="docs"
prompt: "Review recent code changes and update all affected documentation.
Identify modified files, update relevant docs."
```

### Scoped: `/docs <scope>`

Documents only the specified scope (file, module, feature).

```
Task tool with subagent_type="docs"
prompt: "Review and update documentation for: [scope]
Focus only on this area. Update all relevant documentation files."
```

**Scope examples:**
- `/docs src/auth` - document authentication module
- `/docs API` - document all API endpoints
- `/docs README` - update only README.md
- `/docs config` - document configuration options
- `/docs UserService` - document specific class/service

### Comprehensive: `/docs all`

When invoked with `/docs all`, perform a **planned, modular documentation update** covering every aspect of the repository.

**CRITICAL: Do not skip any aspect. Continue until ALL areas are reviewed.**

### Execution Flow

1. **Explore repository structure** - Identify all code areas requiring documentation
2. **Create TodoWrite plan** - One todo item per documentation aspect
3. **Process sequentially** - Complete each aspect before moving to next
4. **Mark progress** - Update todos as each section completes

### Documentation Aspects to Review

Process each area one-by-one:

| Aspect | What to Document |
|--------|------------------|
| Project overview | README.md intro, badges, description |
| Installation | Setup steps, prerequisites, dependencies |
| Configuration | Environment variables, config files, options |
| API reference | Endpoints, functions, parameters, responses |
| Architecture | Directory structure, design patterns, data flow |
| Components/Modules | Each major module's purpose and usage |
| Database/Models | Schema, relationships, migrations |
| Authentication | Auth flows, permissions, security |
| Testing | How to run tests, test structure, coverage |
| Deployment | Build process, CI/CD, hosting |
| Contributing | Code style, PR process, conventions |
| CLAUDE.md | Codebase instructions for AI assistants |

### Example: Full Audit

```
/docs all
```

Creates todos like:
- [ ] Document project overview in README.md
- [ ] Document installation and setup
- [ ] Document configuration options
- [ ] Document API endpoints
- [ ] Document architecture and directory structure
- [ ] Document each major module
- [ ] Document database models
- [ ] Document authentication flow
- [ ] Document testing approach
- [ ] Document deployment process
- [ ] Update CLAUDE.md with codebase patterns

Then dispatches docs agent for each aspect sequentially, marking complete as each finishes.

## What the Agent Updates

- README.md - project overview, setup, usage
- CLAUDE.md - codebase instructions
- API documentation
- Configuration docs
- Any docs/* files

## Examples

**After adding a feature:**
```
/docs
→ Reviews recent changes, updates affected documentation
```

**Document specific module:**
```
/docs src/services/payment
→ Focuses only on payment service documentation
```

**Document API only:**
```
/docs API
→ Updates only API-related documentation
```

**Full project audit:**
```
/docs all
→ Creates plan, systematically documents every aspect
```
