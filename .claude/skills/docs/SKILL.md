---
name: docs
description: Use when code changes are made that could affect documentation, with "all" for comprehensive audit, or "simplifier" to restructure and modularize existing documentation
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

### Simplifier Mode: `/docs simplifier`

When invoked with `/docs simplifier`, perform a **documentation restructuring analysis and execution** to transform monolithic documentation into a modular structure.

**Purpose:** Analyze existing documentation, identify files needing restructuring, propose a modular split plan, and execute with proper cross-linking.

#### Execution Flow

1. **Analyze Current Structure**
   - Measure line counts of all documentation files
   - Identify files exceeding 300 lines
   - Map existing cross-references and links
   - Detect logical sections that can be extracted

2. **Create TodoWrite Plan** - One todo per restructuring action

3. **Execute Restructuring**
   - Create modular directory structure (docs/architecture/, docs/guides/, docs/api/)
   - Extract sections to new files
   - Add navigation breadcrumbs
   - Update cross-references in original files

4. **Report Summary**
   - Files created/modified
   - Links added
   - Size reduction achieved

#### Simplifier Analysis Checklist

| Check | Threshold | Action |
|-------|-----------|--------|
| README.md length | >300 lines | Extract to docs/guides/ |
| CLAUDE.md length | >200 lines | Extract examples to docs/ |
| Single doc file | >300 lines | Split by H2 sections |
| API documentation | >10 endpoints | Create docs/api/endpoints/ |
| Architecture docs | >3 diagrams | Create docs/architecture/diagrams/ |

#### Simplifier vs All Mode

| Aspect | `/docs all` | `/docs simplifier` |
|--------|-------------|-------------------|
| **Purpose** | Comprehensive content audit | Structure optimization |
| **Focus** | Documentation completeness | Documentation organization |
| **Creates** | Missing documentation | Modular file structure |
| **When to use** | Content gaps exist | Files too large/complex |

## What the Agent Updates

- README.md - project overview, setup, usage
- CLAUDE.md - codebase instructions
- API documentation
- Configuration docs
- Any docs/* files

## Supported File Types

| File Type | Extension | Purpose | Validation Rules |
|-----------|-----------|---------|------------------|
| Markdown | .md | Primary documentation | Valid markdown, working links |
| Postman | .json | API testing collection | Valid JSON, camelCase fields |
| Draw.io | .drawio | Architecture diagrams | Opens in draw.io, has export |
| Images | .png, .svg | Diagram exports | Referenced in markdown |

### Postman Collection Validation

When updating `postman_collection.json`:
- Validate JSON structure
- Ensure all field names use camelCase
- Add missing endpoints from codebase
- Include realistic example data

### Draw.io Diagram Guidelines

When working with `.drawio` files:
- Store in `docs/architecture/diagrams/`
- Export PNG to same directory
- Reference in markdown with relative paths

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

**Restructure large documentation:**
```
/docs simplifier
→ Analyzes file sizes, proposes modular structure, executes split
```

**Document with diagram:**
```
/docs architecture
→ Updates docs/architecture/, ensures .drawio files have exports
```

**Validate API collection:**
```
/docs postman
→ Validates postman_collection.json, ensures camelCase
```
