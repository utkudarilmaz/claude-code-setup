---
name: docs
description: This skill should be used when the user asks to "update documentation", "document this change", "sync docs with code", "audit documentation", "restructure docs", "update README", "update CLAUDE.md", "document API", "update postman collection", or "/docs". Supports scoped, comprehensive ("all"), and restructuring ("simplifier") modes.
---

# Docs Skill

## Purpose

Dispatch the docs agent to synchronize documentation with code changes. The agent updates README.md, CLAUDE.md, API docs, postman collections, and other documentation files to keep them accurate and current.

## When to Invoke

Invoke this skill after:

- Implementing new features or modifying existing ones
- Modifying APIs, endpoints, or response schemas
- Changing configuration options or environment variables
- Restructuring files or directories
- Updating dependencies
- Any significant code modification
- Explicit request to audit or restructure documentation

## Invocation Modes

### Default: `/docs`

Document current or recent changes. The agent identifies recently modified files and updates related documentation.

```
Task tool with subagent_type="docs"
prompt: "Review recent code changes and update all affected documentation.
Identify modified files, update relevant docs."
```

### Scoped: `/docs <scope>`

Document only the specified scope (file, module, feature).

```
Task tool with subagent_type="docs"
prompt: "Review and update documentation for: [scope]
Focus only on this area. Update all relevant documentation files."
```

**Scope examples:**
- `/docs src/auth` - authentication module
- `/docs API` - all API endpoints
- `/docs README` - only README.md
- `/docs config` - configuration options
- `/docs UserService` - specific class or service

### Comprehensive: `/docs all`

Perform a planned, modular documentation update covering every repository aspect.

```
Task tool with subagent_type="docs"
prompt: "Perform comprehensive documentation audit of all repository areas.
Create a TodoWrite plan with one item per documentation aspect, then process sequentially.
Consult references/comprehensive-mode.md for the full aspect checklist and execution flow."
```

For detailed aspect checklist and example plan, consult **`references/comprehensive-mode.md`**.

### Simplifier: `/docs simplifier`

Perform documentation restructuring to transform monolithic files into a modular structure with proper cross-linking.

```
Task tool with subagent_type="docs"
prompt: "Perform documentation restructuring analysis and execution.
Analyze file sizes, identify files exceeding thresholds, propose modular split plan, and execute.
Consult references/simplifier-mode.md for analysis checklist and target structure."
```

For detailed restructuring criteria and target structure, consult **`references/simplifier-mode.md`**.

## Usage Examples

```
/docs                          # Document recent changes
/docs src/services/payment     # Document payment service only
/docs API                      # Update API documentation only
/docs all                      # Full project documentation audit
/docs simplifier               # Restructure large docs into modular files
/docs architecture             # Update architecture docs and .drawio diagrams
/docs postman                  # Validate and update postman_collection.json
```

## Additional Resources

### Reference Files

For detailed mode execution flows, consult:
- **`references/comprehensive-mode.md`** - Full audit execution flow, aspect checklist, example TodoWrite plan
- **`references/simplifier-mode.md`** - Restructuring analysis, thresholds, cross-linking templates, target structure
