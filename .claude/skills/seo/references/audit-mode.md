# Audit Mode: `/seo audit`

Score all web content for SEO, GEO, and AIO quality and produce a report card WITHOUT editing any files.

**Do NOT modify any files. This mode is assessment only.**

## Scoring Rubric

Score each aspect on a 0-100 scale:

| Score Range | Grade | Indicator | Meaning |
|-------------|-------|-----------|---------|
| 90-100 | A | GREEN | Excellent - meets or exceeds best practices |
| 70-89 | B | YELLOW | Good - minor improvements possible |
| 50-69 | C | ORANGE | Needs Work - significant gaps to address |
| 0-49 | D/F | RED | Critical - fundamental issues blocking discoverability |

## Aspect Scoring Criteria

### SEO Aspects (50% of overall score)

| Aspect | 90-100 | 70-89 | 50-69 | 0-49 |
|--------|--------|-------|-------|------|
| Title tags | All pages have unique, 50-60 char titles with keywords | Most pages have titles, minor length issues | Some pages missing titles or very poor quality | Most/all pages missing titles |
| Meta descriptions | All pages, 150-160 chars, action-oriented | Most pages have descriptions, some too long/short | Sporadic descriptions, many missing | No meta descriptions |
| Heading hierarchy | Single H1 per page, logical nesting throughout | Minor nesting issues (occasional skip) | Multiple H1s or frequent skipped levels | No heading structure |
| Image optimization | All images have alt text, lazy loading, dimensions | Most have alt text, some missing lazy load | Many images missing alt text | No alt text, no optimization |
| Internal linking | Descriptive anchors, good link depth, no orphans | Good linking, minor anchor text issues | Weak linking structure, some orphan pages | Poor/no internal linking |
| URL & canonicals | Clean slugs, canonical tags on all pages | Most have canonicals, minor slug issues | Inconsistent canonicals, poor slug patterns | No canonicals, messy URLs |
| Sitemap & robots | Complete, accurate, up-to-date | Minor inaccuracies or missing entries | Incomplete or outdated | Missing sitemap or robots.txt |
| Page speed hints | Preload/preconnect/defer used throughout | Some resource hints present | Minimal resource hints | No resource hints |

### GEO Aspects (25% of overall score)

| Aspect | 90-100 | 70-89 | 50-69 | 0-49 |
|--------|--------|-------|-------|------|
| Entity clarity | Clear definitions, unambiguous names, consistent terminology | Good clarity, minor ambiguities | Vague entity references, inconsistent terms | Unclear entities throughout |
| Factual density | Data-backed claims, specific numbers, citations | Mostly specific, occasional vague claims | Mix of specific and vague, few citations | Vague qualifiers, no supporting data |
| Structured answers | FAQ/How-to schema, Q&A patterns, direct answers | Some structured patterns, partial schema | Minimal structured answer patterns | No structured answer content |
| Passage optimization | Self-contained paragraphs, clear topics, extractable | Mostly good paragraphs, some dense blocks | Long run-on paragraphs, unclear boundaries | Wall-of-text content |

### AIO Aspects (25% of overall score)

| Aspect | 90-100 | 70-89 | 50-69 | 0-49 |
|--------|--------|-------|-------|------|
| JSON-LD structured data | Complete Schema.org coverage, valid, all types | Good coverage, minor missing properties | Partial JSON-LD, some validation errors | No structured data |
| Semantic HTML | Full HTML5 elements (article, section, nav, main) | Most semantic elements used | Div-heavy with some semantic elements | No semantic HTML (all divs/spans) |
| Machine readability | Clear outline, structured tables, definition lists | Good structure, minor gaps | Partially structured, some machine-readable content | Unstructured content |
| Context density | Definitions early, topic sentences, TL;DR blocks | Good context provision, minor gaps | Sparse context, buried key information | No context scaffolding |

## Weighted Score Calculation

```
Overall Score = (SEO Score * 0.50) + (GEO Score * 0.25) + (AIO Score * 0.25)

SEO Score = average of 8 SEO aspect scores
GEO Score = average of 4 GEO aspect scores
AIO Score = average of 4 AIO aspect scores
```

## Report Card Template

```markdown
## SEO/GEO/AIO Audit Report Card

**Project**: [project name/path]
**Date**: [audit date]
**Files analyzed**: [count]
**Overall Score**: [X]/100 [GRADE]

### Category Scores

| Category | Score | Grade | Weight |
|----------|-------|-------|--------|
| SEO | [X]/100 | [GRADE] | 50% |
| GEO | [X]/100 | [GRADE] | 25% |
| AIO | [X]/100 | [GRADE] | 25% |

### Detailed Aspect Scores

#### SEO (50%)
| Aspect | Score | Grade | Key Finding |
|--------|-------|-------|-------------|
| Title tags | [X] | [GRADE] | [one-line finding] |
| Meta descriptions | [X] | [GRADE] | [one-line finding] |
| Heading hierarchy | [X] | [GRADE] | [one-line finding] |
| Image optimization | [X] | [GRADE] | [one-line finding] |
| Internal linking | [X] | [GRADE] | [one-line finding] |
| URL & canonicals | [X] | [GRADE] | [one-line finding] |
| Sitemap & robots | [X] | [GRADE] | [one-line finding] |
| Page speed hints | [X] | [GRADE] | [one-line finding] |

#### GEO (25%)
| Aspect | Score | Grade | Key Finding |
|--------|-------|-------|-------------|
| Entity clarity | [X] | [GRADE] | [one-line finding] |
| Factual density | [X] | [GRADE] | [one-line finding] |
| Structured answers | [X] | [GRADE] | [one-line finding] |
| Passage optimization | [X] | [GRADE] | [one-line finding] |

#### AIO (25%)
| Aspect | Score | Grade | Key Finding |
|--------|-------|-------|-------------|
| JSON-LD structured data | [X] | [GRADE] | [one-line finding] |
| Semantic HTML | [X] | [GRADE] | [one-line finding] |
| Machine readability | [X] | [GRADE] | [one-line finding] |
| Context density | [X] | [GRADE] | [one-line finding] |

### Top Recommendations

Prioritized by impact (highest first):

1. **[CRITICAL/HIGH]** [Most impactful recommendation with specific action]
2. **[CRITICAL/HIGH]** [Second priority recommendation]
3. **[MEDIUM]** [Third priority recommendation]
4. **[MEDIUM]** [Fourth recommendation]
5. **[LOW]** [Fifth recommendation]

### Per-Page Summary

| Page | SEO | GEO | AIO | Overall | Top Issue |
|------|-----|-----|-----|---------|-----------|
| [path] | [score] | [score] | [score] | [score] | [one-line] |
```
