# Comprehensive Mode: `/docs all`

Perform a planned, modular documentation update covering every aspect of the repository.

**Do not skip any aspect. Continue until ALL areas are reviewed.**

## Execution Flow

1. **Explore repository structure** - Identify all code areas requiring documentation
2. **Create TodoWrite plan** - One todo item per documentation aspect
3. **Process sequentially** - Complete each aspect before moving to the next
4. **Mark progress** - Update todos as each section completes

## Documentation Aspects to Review

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

## Example TodoWrite Plan

When `/docs all` is invoked, create todos such as:

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

Dispatch the docs agent for each aspect sequentially, marking each complete as it finishes.

## Comprehensive vs Simplifier Mode

| Aspect | `/docs all` | `/docs simplifier` |
|--------|-------------|-------------------|
| **Purpose** | Comprehensive content audit | Structure optimization |
| **Focus** | Documentation completeness | Documentation organization |
| **Creates** | Missing documentation | Modular file structure |
| **When to use** | Content gaps exist | Files too large or complex |
