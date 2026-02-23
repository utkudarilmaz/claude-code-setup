---
name: seo
description: This skill should be used when the user asks to "optimize SEO", "improve meta tags", "add structured data", "optimize for AI", "improve search ranking", "add Open Graph", "GEO optimization", "AIO optimization", "check SEO score", "audit SEO", or "/seo". Supports scoped, comprehensive ("all"), and audit modes.
---

# SEO Skill

## Purpose

Dispatch the seo-optimizer agent to optimize web content for search engines (SEO), generative AI engines (GEO), and AI crawlers (AIO). The agent improves meta tags, heading hierarchy, structured data (JSON-LD), Open Graph, image optimization, internal linking, entity clarity, FAQ schemas, and machine-readable content by directly editing files.

## When to Invoke

Invoke this skill when:

- Creating or modifying HTML pages or web templates
- Adding new web-facing content to a project
- Preparing a site for release or launch
- Improving search engine rankings or AI discoverability
- Adding structured data (JSON-LD, Schema.org)
- Optimizing for generative AI citation (Google SGE, Perplexity)
- Explicit request to audit or improve SEO scores

## Invocation Modes

### Default: `/seo`

Optimize recently changed or uncommitted web files. The agent identifies recently modified HTML, templates, and configuration files and applies SEO/GEO/AIO improvements.

```
Task tool with subagent_type="seo-optimizer"
prompt: "Review recent code changes and optimize all affected web content for SEO, GEO, and AIO.
Identify modified HTML files, templates, and web configuration. Apply improvements to meta tags, headings, structured data, Open Graph, and semantic HTML.
Report all changes applied with before/after comparison."
```

### Scoped: `/seo <scope>`

Optimize only the specified scope (file, page, section, or directory).

```
Task tool with subagent_type="seo-optimizer"
prompt: "Optimize web content for SEO, GEO, and AIO in: [scope]
Focus only on this area. Apply improvements to meta tags, headings, structured data, Open Graph, images, linking, and semantic HTML.
Report all changes applied with before/after comparison."
```

**Scope examples:**
- `/seo src/pages/about.html` - specific page
- `/seo templates/` - all templates directory
- `/seo index.html` - homepage only
- `/seo src/components/ProductPage` - product page component
- `/seo public/` - all public-facing files

### Comprehensive: `/seo all`

Perform a planned, full-project SEO/GEO/AIO audit and optimization covering every web content aspect.

```
Task tool with subagent_type="seo-optimizer"
prompt: "Perform comprehensive SEO/GEO/AIO optimization of all web content in the project.
Create a TodoWrite plan with one item per optimization aspect, then process sequentially.
Consult references/comprehensive-mode.md for the full aspect checklist and execution flow.
Do not skip any aspect. Continue until ALL areas are optimized."
```

For detailed aspect checklist and example plan, consult **`references/comprehensive-mode.md`**.

### Audit: `/seo audit`

Score all web content and produce a report card WITHOUT editing any files. Useful for baseline assessment or pre-release checks.

```
Task tool with subagent_type="seo-optimizer"
prompt: "Perform SEO/GEO/AIO audit of all web content in the project.
Do NOT modify any files. Score each aspect 0-100 and produce a report card.
Consult references/audit-mode.md for the scoring rubric, weighted calculation, and report card template.
Include specific actionable recommendations for each finding."
```

For scoring rubric and report card template, consult **`references/audit-mode.md`**.

## Usage Examples

```
/seo                              # Optimize recent web content changes
/seo src/pages/about.html         # Optimize specific page
/seo templates/                   # Optimize all templates
/seo all                          # Full project SEO/GEO/AIO optimization
/seo audit                        # Score-only report card (no edits)
/seo public/blog/                 # Optimize blog section
```

## Additional Resources

### Reference Files

For detailed mode execution flows, consult:
- **`references/comprehensive-mode.md`** - Full audit execution flow, 12-aspect optimization checklist, example TodoWrite plan
- **`references/audit-mode.md`** - Scoring rubric (0-100), weighted score calculation, grade thresholds, report card template
