# Skills Reference

Skills are user-facing slash commands that dispatch work to agents. Each skill supports multiple invocation modes.

## /docs

Synchronize documentation with code changes.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/docs` | Document recent changes |
| Scoped | `/docs <scope>` | Document specific area (file, module, feature) |
| Comprehensive | `/docs all` | Complete repository documentation audit with TodoWrite planning |
| Simplifier | `/docs simplifier` | Restructure large documentation into modular files |

**What it does:**
- **Default:** Reviews recent changes and updates affected documentation (README.md, CLAUDE.md, API docs)
- **Scoped:** Focuses only on specified area (e.g., module, API, specific file)
- **Comprehensive:** Creates TodoWrite plan covering all documentation aspects (overview, installation, API, architecture, etc.), processes each aspect sequentially. Every area is covered; none of them gets padded
- **Simplifier:** Analyzes documentation structure, identifies files >300 lines, proposes and executes modular split with cross-linking

**Writing:** Plain simple English is the default in every mode. The agent says each thing once, leaves out what the code or `--help` already tells the reader, and cuts stale or padded text in the sections it touches while keeping every fact, command, and caveat. `simplifier` is about where text lives, not how it reads.

**File Management:**
- Enforces 300-line limit per file
- Creates modular structure: docs/architecture/, docs/guides/, docs/api/
- Manages .drawio architecture diagrams with PNG exports
- Validates postman_collection.json with camelCase fields

**Examples:**
```
/docs                    # Document recent changes
/docs src/auth           # Document authentication module
/docs API                # Document all API endpoints
/docs README             # Update only README.md
/docs config             # Document configuration options
/docs UserService        # Document specific class/service
/docs all                # Full documentation audit with planning
/docs simplifier         # Restructure large documentation files
/docs architecture       # Update architecture docs and diagrams
/docs postman            # Validate API collection
```

---

## /tester

Verify and create test coverage.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/tester` | Test recent changes |
| Scoped | `/tester <scope>` | Test specific area (file, module, feature) |
| Comprehensive | `/tester all` | Complete test coverage audit with TodoWrite planning |

**What it does:**
- **Default:** Identifies recently modified files and ensures test coverage
- **Scoped:** Tests only specified area (file, module, or feature)
- **Comprehensive:** Creates TodoWrite plan covering all testing aspects (unit, integration, API, components, edge cases), processes each sequentially, enforces minimum 50% overall project code coverage

**Examples:**
```
/tester                      # Test recent changes
/tester src/auth             # Test authentication module
/tester utils/parser.ts      # Test specific file
/tester API endpoints        # Test all API routes
/tester UserService          # Test specific class/service
/tester all                  # Full test audit with planning
```

---

## /security-review

Perform security-focused code review.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/security-review` | Review recent changes for security vulnerabilities |
| Scoped | `/security-review <path>` | Review specific file/module for security issues |
| Comprehensive | `/security-review all` | Complete security audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent commits for security vulnerabilities
- **Scoped:** Deep security review of specified file/module
- **Comprehensive:** Creates TodoWrite plan covering all 13 security focus areas, processes each thoroughly

**13 Security Focus Areas:**
1. Authentication & Authorization
2. Input Validation
3. Data Exposure
4. Secrets Management
5. OWASP Top 10 (2021)
6. API Security
7. File Upload Security
8. Cryptography
9. Business Logic Vulnerabilities
10. Client-Side Security
11. HTTP Security Headers & Cookies
12. Dependency Security
13. Modern Attack Vectors

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Examples:**
```
/security-review                  # Review recent changes
/security-review src/auth         # Deep review of authentication module
/security-review api/handlers     # Review API endpoints
/security-review lib/payment.ts   # Review specific file
/security-review controllers/     # Review all controllers
/security-review all              # Comprehensive security audit with planning
```

---

## /changelog

Generate or update changelog, or create release notes.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/changelog` | Update CHANGELOG.md from git history (Keep a Changelog format) |
| Release | `/changelog release` | Generate user-friendly release notes for latest version |
| Versioned | `/changelog <version>` | Generate release notes for specific version or range |

**What it does:**
- **Default:** Updates or creates CHANGELOG.md using Keep a Changelog format, includes all versions from git tags plus [Unreleased] section
- **Release mode:** Generates announcement-style release notes from last tag to HEAD, formatted for GitHub releases or announcements
- **Versioned mode:** Generates release notes for specific version or version range

**Agent Dispatch:**
- `/changelog` → `changelog-generator` agent (CHANGELOG.md file)
- `/changelog release` → `release-notes` agent (release announcement markdown)
- `/changelog <version>` → `release-notes` agent (version-specific notes)

**Examples:**
```
/changelog                # Update CHANGELOG.md
/changelog release        # Generate GitHub release notes for latest version
/changelog 2.0.0          # Generate notes for version 2.0.0
/changelog 1.5.0..2.0.0   # Generate notes for version range
```

---

## /simplifier

Cleanup dead code and reduce complexity.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/simplifier` | Cleanup recent changes |
| Scoped | `/simplifier <scope>` | Cleanup specific area (file, module, directory) |
| Comprehensive | `/simplifier all` | Complete code quality audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent changes for dead code, unused imports, overly complex functions
- **Scoped:** Focuses cleanup on specified area; detects primary language(s) and applies language-specific patterns
- **Comprehensive:** Creates TodoWrite plan covering all aspects (dead code, complexity, patterns, organization), processes each sequentially

**Language Support:** Go, JavaScript/TypeScript, Python (language-specific pattern references loaded automatically per scope)

**Examples:**
```
/simplifier                  # Cleanup recent changes
/simplifier src/utils        # Cleanup utils directory
/simplifier handlers/        # Cleanup all handlers
/simplifier all              # Full code quality audit with planning
```

---

## /devops

Review and design infrastructure configurations.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/devops` | Review recent infrastructure changes |
| Scoped | `/devops <context>` | Review or design based on context |
| Comprehensive | `/devops all` | Complete infrastructure audit with TodoWrite planning |

**What it does:**
- **Default:** Reviews recent IaC changes for security, best practices, reliability
- **Scoped:** Review specific files/directories OR design new configurations based on context
- **Comprehensive:** Creates TodoWrite plan covering all infrastructure types (K8s, Helm, ArgoCD, Terraform, Terragrunt), processes each thoroughly

**Infrastructure Coverage:**
- Kubernetes: Security contexts, resource limits, probes, RBAC, NetworkPolicies
- Helm: Chart structure, values templating, defaults, documentation
- ArgoCD: Sync policies, health checks, RBAC, progressive delivery
- Terraform: State management, modules, security, variable validation
- Terragrunt: DRY patterns, dependencies, remote state configuration

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Examples:**
```
/devops                              # Review recent infrastructure changes
/devops review k8s/                  # Review Kubernetes manifests
/devops review terraform/modules/vpc # Review Terraform module
/devops design helm chart for redis  # Generate Helm chart
/devops design argocd app for apis   # Generate ArgoCD config
/devops review values.yaml           # Review Helm values
/devops all                          # Full infrastructure audit with planning
```

---

## /seo

Optimize web content for search engines (SEO), generative AI engines (GEO), and AI crawlers (AIO).

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/seo` | Optimize recently changed web files |
| Scoped | `/seo <scope>` | Optimize specific page, directory, or component |
| Comprehensive | `/seo all` | Full project SEO/GEO/AIO optimization with TodoWrite planning |
| Audit | `/seo audit` | Score all web content (no file edits) |

**What it does:**
- **Default:** Identifies recently modified HTML, templates, and web config files and applies SEO/GEO/AIO improvements
- **Scoped:** Focuses only on specified area (file, directory, or component)
- **Comprehensive:** Creates TodoWrite plan covering all 12 optimization aspects (meta, headings, structured data, Open Graph, images, linking, technical SEO, GEO, AIO, sitemap, robots.txt, performance hints), processes each sequentially
- **Audit:** Scores each aspect 0-100, calculates weighted total, produces report card with letter grade and prioritized recommendations without modifying any files

**12 Optimization Aspects:**

| Pillar | Focus Areas |
|--------|------------|
| SEO | Meta tags, heading hierarchy, Open Graph, Twitter Cards, images, internal linking, canonical URLs |
| GEO | Entity clarity, factual density, FAQ/HowTo schemas, passage-level optimization |
| AIO | JSON-LD structured data, semantic HTML5, machine-readable structure, context density |
| Technical | sitemap.xml, robots.txt, resource hints, async/defer scripts |

**Severity Levels:** CRITICAL, HIGH, MEDIUM, LOW

**Examples:**
```
/seo                           # Optimize recent web content changes
/seo src/pages/about.html      # Optimize specific page
/seo templates/                # Optimize all templates in directory
/seo all                       # Full project optimization with planning
/seo audit                     # Score-only report card (no edits)
```

**Reference Files:** `references/comprehensive-mode.md` (12-aspect checklist), `references/audit-mode.md` (scoring rubric, report card template)

---

## /release-tag

Bump semantic version, update changelog, and create annotated git tag.

| Mode | Command | Description |
|------|---------|-------------|
| Patch | `/release-tag patch` | Bump patch version (1.2.3 -> 1.2.4) |
| Minor | `/release-tag minor` | Bump minor version (1.2.3 -> 1.3.0) |
| Major | `/release-tag major` | Bump major version (1.2.3 -> 2.0.0) |

**What it does:**
- Reads the latest git tag (defaults to `0.0.0` if none exist)
- Calculates new version based on bump type
- Verifies clean working tree (refuses to tag with uncommitted changes)
- Invokes `/changelog` to update CHANGELOG.md, then commits the changelog
- Builds tag message from grouped commit summary (conventional commit types)
- Creates annotated git tag (no "v" prefix)
- Reminds user to push manually (never auto-pushes)

**Examples:**
```
/release-tag patch       # Bump patch version and tag
/release-tag minor       # Bump minor version and tag
/release-tag major       # Bump major version and tag
```

---

## /pr-body

Write a pull request description and apply it with `gh`.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/pr-body` | Write and apply the body for the current branch's PR |
| Targeted | `/pr-body <number\|url>` | Rewrite the body of a specific PR |
| Draft | `/pr-body draft` | Print a draft body without touching GitHub |
| Refresh | `/pr-body refresh` | Update an existing body, keeping hand-written notes |

**What it does:**
- **Default:** Resolves the current branch's open PR, reads the commits and diff against the base branch plus any linked issue, writes a short body, and applies it with `gh pr edit`
- **Targeted:** Same, against a PR given by number or URL
- **Draft:** Prints the body only, makes no GitHub call
- **Refresh:** Reads the current body first, keeps the author's own writing and heading style, and rewrites the template sections to the short default shape, whether they went stale or just grew padded

**Body shape:**

| Section | Required | Content |
|---------|----------|---------|
| What | Yes | What the change does, in one or two sentences |
| Why | Yes | The problem or reason behind it, in one or two sentences |
| Files | Yes | Every changed file, grouped Added / Changed / Removed |
| Testing | Optional | What was actually run or verified |
| Next | Optional | Follow-up work left out on purpose |

Optional sections are dropped entirely when empty, never filled with "N/A".

**Files section:** Built from `git diff --name-status -M` against the PR's base branch. Every file is listed, with no truncation and no directory rollups. A file gets a note only when its path leaves a reviewer guessing. Renames are detected and shown as a single line under Changed rather than as a delete plus an add. In refresh mode this section is always rebuilt from the current diff, since a stale file list is simply wrong; the author's per-file notes carry over for files still in the diff.

**Rules:** Under 120 words of prose, plain simple English, no emoji, no bold-label bullets in prose, no AI attribution, no invented test results. The Files list is exempt from the word budget and is always complete. Short is the default in every mode, including refresh; a large change gets the same shape, with the Files list carrying the detail.

**Scope:** Writing only. Never creates a PR and never pushes commits; use `/commit-commands:commit-push-pr` for that.

**Examples:**
```
/pr-body                                          # Apply body to this branch's PR
/pr-body 142                                      # Rewrite the body of PR 142
/pr-body https://github.com/owner/repo/pull/142   # Same, by URL
/pr-body draft                                    # Print a draft, change nothing
/pr-body refresh                                  # Update body, keep hand-written notes
```

---

## /text-slop-cleaner

Rewrite machine sounding prose into plain English and remove comments that add nothing.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/text-slop-cleaner` | Clean prose and comments in the uncommitted changes |
| Scoped | `/text-slop-cleaner <path>` | Clean a specific file or directory |
| Pull request | `/text-slop-cleaner <number\|url>` | Clean a PR body and your own comments on it |
| All | `/text-slop-cleaner all` | Clean every markdown file in the repository |
| Check | `/text-slop-cleaner check` | Report what would change, change nothing |

**What it does:**
- **Default:** Runs `git diff` to find changed files, then rewrites padded prose and cuts empty comments on the lines those changes touched
- **Scoped:** Reads each file in the path fully before cutting anything, then cleans its prose and comments
- **Pull request:** Rewrites the body and your own comments with `gh pr edit` and `gh api`; lists what reads as slop in other people's comments and leaves them alone, since GitHub does not allow editing them
- **All:** Cleans every markdown file, skipping vendored, generated, and dependency directories, and reports per file plus a total word count
- **Check:** Shows the current text and the proposed replacement for each finding; edits no file and makes no `gh` call

Default, scoped, pull request, and all modes apply changes directly without asking. Use `check` to review first.

**What it never touches:**

| Kind | Examples |
|------|----------|
| Lint and type directives | `//nolint`, `# noqa`, `# type: ignore`, `// eslint-disable` |
| Build and tooling markers | build tags, `//go:generate`, encoding lines, shebangs |
| Generated file markers | `Code generated by ... DO NOT EDIT` |
| Legal | license headers, copyright notices, SPDX identifiers |
| Required doc comments | godoc on exported symbols, JSDoc on published APIs |
| Other people's comments | reported, never edited |

**Scope:** Text only. Never changes code behavior, never edits string literals, and never adds headings or summaries that were not there. Meaning is preserved: a padded sentence that carries information is rewritten, not deleted. Code blocks, commands, paths, and numbers are copied through exactly.

**Examples:**
```
/text-slop-cleaner              # Clean the uncommitted changes
/text-slop-cleaner README.md    # Clean one file
/text-slop-cleaner docs/        # Clean a directory
/text-slop-cleaner 142          # Clean the body and your comments on PR 142
/text-slop-cleaner all          # Clean every markdown file
/text-slop-cleaner check        # Show what would change, change nothing
```

**Reference Files:** `references/slop-patterns.md` (full prose and comment pattern list with before and after examples)

---

## /code-slop-cleaner

Judge a diff against its stated purpose and separate the needed work from the rest.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/code-slop-cleaner` | Review the uncommitted changes |
| Scoped | `/code-slop-cleaner <path>` | Review only the changes under a path |
| Pull request | `/code-slop-cleaner <number\|url>` | Review a pull request's diff against its base branch |
| Branch | `/code-slop-cleaner branch` | Review the whole branch against the default branch |
| Apply | `/code-slop-cleaner apply` | Remove the unnecessary parts, then run the tests |

**What it does:**
- **Default:** Establishes the purpose, groups the uncommitted changes into units by concern, classifies each one, and reports
- **Scoped:** Same review, limited to the changes under the given path
- **Pull request:** Resolves the PR with `gh pr view`, reads the body and any linked issue for the purpose, and diffs against that PR's base branch; posts no comments and changes nothing on the PR
- **Branch:** Reviews every commit on the branch against the default branch, paying attention to work added in later commits that the original purpose does not cover
- **Apply:** Removes the UNNECESSARY units smallest blast radius first, then finds and runs the project test command and reports the result, including the failure output when it fails

Only `apply` changes files. Every other mode reports.

**The purpose gate:** The agent reads the purpose from the linked issue, the pull request body, or the commit messages, in that order. If it cannot find one, it stops and asks. This is deliberate: a purpose guessed from the diff makes every line in that diff look necessary, and the review then returns nothing. Give it a purpose, or answer its question.

**Classification:**

| Class | Meaning | Action |
|-------|---------|--------|
| REQUIRED | The purpose fails without it | Keep |
| SUPPORTING | Needed to ship the required work: tests, a migration, an import | Keep |
| UNNECESSARY | Serves nothing, and nothing depends on it | Remove |
| UNRELATED | Real work, wrong change | Split out |

UNRELATED is not criticism. The work is fine and belongs in its own commit, so it is named and never removed.

**How it differs from `/simplifier`:**

| Skill | Question it answers | Use it for |
|-------|--------------------|------------|
| `/simplifier` | Is this code well written? | Dead code, complexity, duplication, style, and naming, anywhere in the codebase |
| `/code-slop-cleaner` | Did this change need to happen? | Work that crept into a diff, judged against the purpose behind it |

**Rules:** Every finding is verified by a search before it is reported. Tests for new behavior and error handling at real input and output boundaries are never flagged. Style, naming, and formatting are out of scope; use `/simplifier` for those.

**Examples:**
```
/code-slop-cleaner            # Report on the uncommitted changes
/code-slop-cleaner src/auth   # Report on the auth changes only
/code-slop-cleaner 142        # Report on PR 142
/code-slop-cleaner branch     # Report on the whole branch
/code-slop-cleaner apply      # Remove what is unnecessary, then test
```

**Reference Files:** `references/change-patterns.md` (pattern list, what to verify before flagging each one, and the never flag list)

---

## /explain

Explain code, changes, pull requests, or concepts in plain English.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/explain` | Explain the uncommitted changes, or the last commit when the tree is clean |
| Targeted | `/explain <target>` | Explain a named file, pull request, symbol, or concept |
| Deep | `/explain <target> deep` | Full walkthrough with `file:line` anchors and a worked example |

**What it does:**
- **Default and targeted:** Works out the target, states it on the first line, then covers what it is, what it does, why it exists, and how it fits
- **Deep:** Adds a walkthrough in execution order with `file:line` anchors for each step, a worked example traced from a concrete input to its output, and the edge cases the code handles with what it does in each

Deep means more detail, not more jargon. There is one command and no mode to remember beyond `deep`; the target is auto-detected.

**Target detection:**

| Argument | Target |
|----------|--------|
| none, tree dirty | The uncommitted changes |
| none, tree clean | The most recent commit |
| an existing path | That file or directory |
| a number or PR url | That pull request |
| a symbol in the repository | That function, type, or class |
| anything else | A concept question, answered in this codebase's terms |

The resolved target is printed on the first line, so a wrong guess is obvious straight away.

**Output shape:**

| Section | Included |
|---------|----------|
| What it is | Always, one line |
| What it does | Always, plain steps |
| Why it exists | Always, the problem it solves |
| How it fits | Always, callers and callees |
| Watch out for | Only when something real belongs there |

Empty sections are dropped, not padded. Length follows the target, so a small function gets a short answer.

**Scope:** Terminal output only. Nothing is written to disk and nothing is published. Explains, does not review; use `/code-review` or `/simplifier` to judge code.

**Rules:** Everyday words, with any unavoidable term defined where it first appears. Concrete values, not "the input". Never `simply`, `just`, `obviously`, `of course`, or `as you know`. Never invents a reason: an honest gap beats a plausible guess, and what was read is kept apart from what was inferred.

**Examples:**
```
/explain                                # The current changes
/explain internal/queue/retry.go        # One file
/explain 142                            # Pull request 142
/explain parseManifest                  # One function
/explain what is a reconciler here      # A concept, in this codebase's terms
/explain internal/queue/retry.go deep   # Line by line, with an example
```

**Reference Files:** `references/deep-mode.md` (walkthrough structure, worked example format, and how to handle code you cannot fully explain)
