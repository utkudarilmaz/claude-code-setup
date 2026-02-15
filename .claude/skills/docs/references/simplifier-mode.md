# Simplifier Mode: `/docs simplifier`

Perform a documentation restructuring analysis and execution to transform monolithic documentation into a modular structure.

**Purpose:** Analyze existing documentation, identify files needing restructuring, propose a modular split plan, and execute with proper cross-linking.

## Execution Flow

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

## Analysis Checklist

| Check | Threshold | Action |
|-------|-----------|--------|
| README.md length | >300 lines | Extract to docs/guides/ |
| CLAUDE.md length | >200 lines | Extract examples to docs/ |
| Single doc file | >300 lines | Split by H2 sections |
| API documentation | >10 endpoints | Create docs/api/endpoints/ |
| Architecture docs | >3 diagrams | Create docs/architecture/diagrams/ |

## Restructuring Criteria

| Indicator | Recommended Action |
|-----------|-------------------|
| README.md > 300 lines | Extract detailed sections to docs/guides/ |
| Single topic > 100 lines | Consider dedicated file |
| Repeated content | Consolidate and link |
| Deep nesting in one file | Split by heading level 2 |
| No table of contents | Add TOC or split into smaller files |

## Cross-Linking Template

```markdown
<!-- In README.md -->
For detailed configuration, see [Configuration Guide](docs/guides/configuration.md).

<!-- In docs/guides/configuration.md -->
> **Navigation:** [Back to README](../../README.md) | [Installation](installation.md)
```

## Target Modular Structure

```
docs/
├── architecture/          # System design and technical decisions
│   ├── overview.md        # High-level architecture
│   ├── data-flow.md       # Data flow documentation
│   ├── decisions/         # Architecture Decision Records (ADRs)
│   └── diagrams/          # .drawio source files
├── guides/                # User-facing documentation
│   ├── getting-started.md # Quick start guide
│   ├── installation.md    # Detailed setup
│   ├── configuration.md   # Config options
│   └── troubleshooting.md # Common issues
├── api/                   # API documentation
│   ├── overview.md        # API introduction
│   ├── authentication.md  # Auth documentation
│   ├── endpoints/         # Per-resource endpoint docs
│   └── schemas/           # Request/response schemas
└── contributing/          # Contributor documentation
```
