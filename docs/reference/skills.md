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

**Language Support:** Go, JavaScript/TypeScript, Python, Rust (language-specific pattern references loaded automatically per scope)

**Reference Files:** `references/comprehensive-mode.md` (quality aspect checklist, execution flow), `references/go-patterns.md`, `references/js-ts-patterns.md`, `references/python-patterns.md`, `references/rust-patterns.md`

**Examples:**
```
/simplifier                  # Cleanup recent changes
/simplifier src/utils        # Cleanup utils directory
/simplifier handlers/        # Cleanup all handlers
/simplifier all              # Full code quality audit with planning
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

## /create-pr

Commit, push, and open a pull request with a real title and body.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/create-pr` | Commit, push, write the title and body, open the PR |
| Draft | `/create-pr draft` | Same, opened as a GitHub draft PR |
| Show | `/create-pr show` | Print the title and body, touch neither git nor GitHub |
| Refresh | `/create-pr refresh` | Update this branch's existing PR, keeping hand-written notes |
| Targeted | `/create-pr <number\|url>` | Update the title and body of a specific PR |

**What it does:**
- **Default:** Runs the preflight checks, branches off the default branch when needed, commits a dirty tree with a conventional commit message, pushes with upstream tracking, reads the commits and diff plus any linked issue, writes the title and body, sets the fields, and opens the PR with `gh pr create`
- **Draft:** The same flow, with `--draft`
- **Show:** Prints the title, body, and the fields it would set, and makes no git or GitHub call
- **Refresh:** Reads the current body first, keeps the author's own writing and heading style, and rewrites the template sections to the short default shape, whether they went stale or just grew padded
- **Targeted:** Updates the body of a PR given by number or URL, and the title only when it no longer fits

A branch that already has an open PR routes to the update path in every mode, so the default mode never fails with "PR already exists".

Anything typed after the mode is passed through as plain text: `/create-pr base develop`, `/create-pr draft reviewer alice`, `/create-pr label bug`.

**Cleanup pass:** Every mode except show ends with a cleanup pass over each PR the run created or updated. The skill dispatches three agents against the finished PR: `pr-comment-cleaner` removes unnecessary code comments in the PR's changed files and leaves the edits uncommitted, `text-slop-cleaner` rewrites the PR body and your own comments into plain English, and `code-slop-cleaner` reports whether the diff matches its scope. They run concurrently when the run was for the current branch; a targeted PR runs `pr-comment-cleaner` first because it checks the PR branch out. Add `no-clean` to skip the pass.

**Title:** Conventional commit form, under 70 characters, lower case after the type, no ticket ID. The repository's own convention wins when recent merged PRs show one.

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

**PR fields:**

| Field | Set when |
|-------|----------|
| Base | Always. The repository default branch, or the branch you named |
| Draft | Draft mode, or the work is unfinished |
| Assignee | Always, set to you |
| Reviewer | You name one, or a CODEOWNERS entry matches a changed file |
| Label | An existing label fits the change. Labels are never created |
| Milestone | You name one, or the linked issue carries one |

**Commit and push:** One commit per run with a conventional commit message, staged from explicit paths. Files the sensitive file hook blocks are left out and reported. The push uses `git push -u origin <branch>`. Never a force push, never a commit on the default branch, never a rebase or amend of commits that already exist.

**Rules:** Under 120 words of prose, plain simple English, no emoji, no bold-label bullets in prose, no AI attribution, no invented test results. The Files list is exempt from the word budget and is always complete. Short is the default in every mode, including refresh; a large change gets the same shape, with the Files list carrying the detail.

**Scope:** The whole path from a dirty tree to a PR URL. Use this instead of `/commit-commands:commit-push-pr`, which opens a PR without writing a real description.

**Examples:**
```
/create-pr                                          # Commit, push, and open the PR
/create-pr draft                                    # Same, opened as a draft
/create-pr show                                     # Print the title and body, change nothing
/create-pr refresh                                  # Update the existing PR, keep hand-written notes
/create-pr 142                                      # Update the title and body of PR 142
/create-pr https://github.com/owner/repo/pull/142   # Same, by URL
/create-pr base develop reviewer alice              # Open against develop, request alice
/create-pr no-clean                                 # Open the PR, skip the cleanup pass
```

**Reference Files:** `references/pr-creation.md` (preflight, branch naming, commit and push rules, title rules, field selection, gh commands)

---

## /text-slop-cleaner

Rewrite machine sounding prose into plain English and remove every comment that is not 100% necessary.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/text-slop-cleaner` | Clean whatever the branch has in flight, target resolved automatically |
| Scoped | `/text-slop-cleaner <path>` | Clean a specific file or directory |
| Pull request | `/text-slop-cleaner <number\|url>` | Clean a PR body and your own comments on it |
| All | `/text-slop-cleaner all` | Clean every markdown file in the repository |
| Check | `/text-slop-cleaner check` | Report what would change, change nothing |

**What it does:**
- **Default:** Resolves its own target with a cascade, then rewrites padded prose and cuts unnecessary comments in it
- **Scoped:** Reads each file in the path fully before cutting anything, then cleans its prose and comments
- **Pull request:** Rewrites the body and your own comments with `gh pr edit` and `gh api`; lists what reads as slop in other people's comments and leaves them alone, since GitHub does not allow editing them
- **All:** Cleans every markdown file, skipping vendored, generated, and dependency directories, and reports per file plus a total word count
- **Check:** Resolves the same target as the default, then shows the current text and the proposed replacement for each finding; edits no file and applies nothing

Default, scoped, pull request, and all modes apply changes directly without asking. Use `check` to review first.

**Default target cascade:** With no argument the agent stops at the first of these that has something in it, and names the step it picked in the first line of the report.

| Order | When | Target |
|-------|------|--------|
| 1 | `git status --porcelain` is not empty | The uncommitted changes, on the lines they touch |
| 2 | The branch has commits the base does not, pushed or not | Every file those commits touched |
| 3 | The branch has an open PR | The PR body and your own comments on it |
| 4 | None of the above | One line saying there is nothing to clean |

Steps 1 and 2 need only `git`; step 3 needs `gh`. The cascade never falls through to every markdown file in the repository, which is what `all` is for.

**What it never touches:**

| Kind | Examples |
|------|----------|
| Lint and type directives | `//nolint`, `# noqa`, `# type: ignore`, `// eslint-disable` |
| Build and tooling markers | build tags, `//go:generate`, encoding lines, shebangs |
| Generated file markers | `Code generated by ... DO NOT EDIT` |
| Legal | license headers, copyright notices, SPDX identifiers |
| Required doc comments | godoc on exported symbols, JSDoc on published APIs |
| Pragma comments that are code | `# frozen_string_literal: true`, webpack magic comments, `/** @type {...} */` |
| Sole statement docstrings | removing one breaks the syntax of the block |
| Other people's comments | reported, never edited |

**Two standards:** Prose is held to preserved meaning, so a padded sentence that carries information is rewritten, not deleted. Comments are held to the 100% necessary rule: a comment stays only when the code cannot tell the reader what it says, and every removal is verified by reading that code first. A stale or padded comment whose information is real gets rewritten instead of cut.

**Scope:** Text only. Never changes code behavior, never edits string literals, and never adds headings or summaries that were not there. Code blocks, commands, paths, and numbers are copied through exactly. When a run touches a source file, the working tree is reviewed with `git diff` and the project's tests are run, since a comment edit can break syntax.

**Examples:**
```
/text-slop-cleaner              # Clean whatever is in flight: changes, commits, or the PR
/text-slop-cleaner README.md    # Clean one file
/text-slop-cleaner docs/        # Clean a directory
/text-slop-cleaner 142          # Clean the body and your comments on PR 142
/text-slop-cleaner all          # Clean every markdown file
/text-slop-cleaner check        # Show what would change, change nothing
```

**Reference Files:** `references/slop-patterns.md` (full prose and comment pattern list with before and after examples)

---

## /code-slop-cleaner

Judge a diff against its ticket or stated purpose in both directions: needed work, extra work, and missing work.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/code-slop-cleaner` | Review whatever the branch has in flight, target resolved automatically |
| Scoped | `/code-slop-cleaner <path>` | Review only the changes under a path |
| Pull request | `/code-slop-cleaner <number\|url>` | Review a pull request's diff against its base branch |
| Ticket | `/code-slop-cleaner <ticket-url>` | Review the current changes against an explicit ticket |
| PR with ticket | `/code-slop-cleaner <pr> <ticket-url>` | Review a pull request against an explicit ticket |
| Branch | `/code-slop-cleaner branch` | Review the whole branch against the default branch |
| Apply | `/code-slop-cleaner apply` | Remove the unnecessary parts, then run the tests |

**What it does:**
- **Default:** Resolves the target with a cascade, establishes the scope separately, groups the diff into units by concern, classifies each one, and reports
- **Scoped:** Same review, limited to the changes under the given path
- **Pull request:** Resolves the PR with `gh pr view`, reads the body and any linked issue for the scope, and diffs against that PR's base branch; posts no comments and changes nothing on the PR
- **Ticket:** Fetches the ticket with WebFetch (asks for pasted text if the tracker needs auth), extracts a requirement list, and checks the current changes against it
- **PR with ticket:** Same, but for a pull request's diff against its base branch
- **Branch:** Reviews every commit on the branch against the default branch, paying attention to work added in later commits that the original purpose does not cover
- **Apply:** Removes the UNNECESSARY units smallest blast radius first, then finds and runs the project test command and reports the result, including the failure output when it fails

Only `apply` changes files. Every other mode reports.

**Default target cascade:** With no argument the agent stops at the first of these that has something in it, and names the step it picked in the first line of the report.

| Order | When | Target |
|-------|------|--------|
| 1 | `git status --porcelain` is not empty | The uncommitted changes |
| 2 | The branch has commits the base does not, pushed or not | The whole branch diff against the base |
| 3 | The branch has an open PR | That PR's diff against its base |
| 4 | None of the above | One line saying there is nothing to review |

Steps 1 and 2 need only `git`; step 3 needs `gh`. `apply` follows the same cascade but stops at step 2, since it will not edit files for a PR that is not checked out. The target cascade is separate from the scope gate below: the target is the diff being judged, the scope is what that diff owed.

**The scope gate:** The agent reads the scope from pasted ticket text, an explicit ticket URL, the linked issue, the pull request body, or the commit messages, in that order. External tracker URLs are fetched with WebFetch. If it cannot find any scope, it stops and asks. This is deliberate: a scope guessed from the diff makes every line look necessary and every requirement look delivered, and the review then returns nothing.

**Classification:**

| Class | Meaning | Action |
|-------|---------|--------|
| REQUIRED | The purpose fails without it | Keep |
| SUPPORTING | Needed to ship the required work: tests, a migration, an import | Keep |
| UNNECESSARY | Serves nothing, and nothing depends on it | Remove |
| UNRELATED | Real work, wrong change | Split out |

UNRELATED is not criticism. The work is fine and belongs in its own commit, so it is named and never removed.

Requirements get their own status: COVERED, PARTIAL, or MISSING (verified by a codebase search). The report opens with a verdict: IN SCOPE, INCOMPLETE, SCOPE CREEP, or BOTH.

**How it differs from `/simplifier`:**

| Skill | Question it answers | Use it for |
|-------|--------------------|------------|
| `/simplifier` | Is this code well written? | Dead code, complexity, duplication, style, and naming, anywhere in the codebase |
| `/code-slop-cleaner` | Did this change need to happen, and did it deliver everything asked? | Work that crept into a diff and requirements that never made it in, judged against the scope behind it |

**Rules:** Every finding is verified by a search before it is reported. Tests for new behavior and error handling at real input and output boundaries are never flagged. Style, naming, and formatting are out of scope; use `/simplifier` for those. A requirement is only MISSING after a codebase search comes up empty, and missing work is reported, never written.

**Examples:**
```
/code-slop-cleaner            # Report on whatever is in flight: changes, branch, or PR
/code-slop-cleaner src/auth   # Report on the auth changes only
/code-slop-cleaner 142        # Report on PR 142
/code-slop-cleaner https://acme.atlassian.net/browse/APP-42   # Current changes vs ticket
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

---

## /review-analyzer

Check each issue in a code review against the actual code, judge the proposed fixes, and explain everything in plain language.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/review-analyzer` | Analyze the review pasted in the conversation |
| File | `/review-analyzer <file>` | Analyze a review saved to a file |

**What it does:**
- Parses the review into a numbered issue list and states it first, so a misread review is visible
- Verifies each issue in the code: CONFIRMED, NOT A BUG, or CANNOT VERIFY, with the file and lines that prove it
- Judges each proposed fix on a confirmed issue: VALID, PARTIAL, or INVALID, naming what it misses or breaks
- Proposes a better fix in words when the proposed one falls short, or when a confirmed issue has no fix
- Reports every parsed issue as its own numbered section answering five questions: what the issue is, whether it is valid, what fix the review suggests, whether that fix is the right fix, and what the agent suggests
- Explains every issue, the reviewer's fix, and the suggested fix in plain language for a reader who does not know the codebase

**Scope:** Report only. Terminal output, no code edits, no files written. Never fetches pull requests or review comments with gh; given a PR number or URL, it asks for the text or a file. If no review is given at all, it stops and asks.

**Rules:** Every parsed issue gets its own section with all six questions answered; no item is skipped or merged, and every item ends with one concrete closing recommendation. Every verdict names its evidence in the code, and nothing is judged from the review text alone. Better fixes are proposed in words, never applied. A review that is entirely right is reported as such. Never `simply`, `just`, `obviously`, `of course`, or `as you know`.

**Examples:**
```
/review-analyzer                      # The review pasted above in the chat
/review-analyzer reviews/pr-142.md    # A review saved to a file
```

**Reference Files:** `references/fix-validity-patterns.md` (what makes a proposed fix invalid or partial, what makes an issue not a bug, and what a better fix must state)

---

## /pr-comment-cleaner

Remove code comments in a PR's changed files that are not 100% necessary and rewrite the ones that must stay.

| Mode | Command | Description |
|------|---------|-------------|
| Default | `/pr-comment-cleaner` | Clean comments in the current branch's PR |
| Pull request | `/pr-comment-cleaner <number\|url>` | Check out a PR and clean its comments |
| Scoped | `/pr-comment-cleaner <path>` | Clean only the PR's changed files under a path |
| Check | `/pr-comment-cleaner check [target]` | Report what would change, change nothing |

**What it does:**
- **Default:** Resolves the current branch's PR with `gh pr view`, or falls back to the branch diff against the merge base with the default branch including uncommitted changes, then cleans the comments in the changed files
- **Pull request:** Requires a clean working tree, checks the PR out with `gh pr checkout`, cleans its comments, and leaves the edits uncommitted on the PR branch, stating that the repository is now on that branch
- **Scoped:** Intersects the PR's changed file list with the given path and cleans only that intersection
- **Check:** Shows every finding with the comment, its location, whether this PR introduced it, and the verification behind the removal or rewrite; edits nothing and checks out nothing

Default, pull request, and scoped modes apply changes directly without asking. Use `check` to review first. Edits always stay uncommitted; the agent never commits, pushes, or stashes.

**Classification:** Every comment in a changed file is classified as REMOVE (adds nothing the code does not say), REWRITE (real information, but stale or padded), KEEP (deleting it loses information not in the code), or PROTECTED. Removal is the default: a comment that is merely accurate or helpful goes, and a keep must name the fact the code cannot give back. Verification runs both ways; doubt about protection or about the code itself being wrong keeps the comment, doubt about whether it is useful enough does not.

**What it never touches:**

| Kind | Examples |
|------|----------|
| Lint and type directives | `//nolint`, `# noqa`, `# type: ignore`, `// eslint-disable` |
| Build and tooling markers | build tags, `//go:generate`, encoding lines, shebangs |
| Generated file markers | `Code generated by ... DO NOT EDIT` |
| Legal | licence headers, copyright notices, SPDX identifiers |
| Required doc comments | godoc on exported symbols, JSDoc on published APIs, docstrings a generator consumes |
| Pragma comments that are code | `# frozen_string_literal: true`, webpack magic comments, coverage pragmas |
| Sole statement docstrings | removing one breaks the syntax |

**How it differs from `/text-slop-cleaner` and `/simplifier`:** `/text-slop-cleaner` rewrites prose anywhere and handles PR bodies and GitHub comments; this skill never touches GitHub comments or prose files and works only on code comments inside the PR's diff. `/simplifier` judges code quality; this skill never changes code. There is no repo-wide mode; whole-repository comment cleanup is `/text-slop-cleaner <path>`'s job.

**Scope:** Only files in the PR's diff, and only comment lines in them. After applying, the agent reviews its own `git diff` to confirm nothing else changed, then runs the project test command when one is discoverable.

**Examples:**
```
/pr-comment-cleaner              # Clean comments in the current branch's PR
/pr-comment-cleaner 142          # Check out PR 142 and clean its comments
/pr-comment-cleaner src/auth/    # Only PR-changed files under src/auth/
/pr-comment-cleaner check        # Report only, change nothing
/pr-comment-cleaner check 142    # Report on PR 142 without checking it out
```

**Reference Files:** `references/comment-necessity.md` (remove, rewrite, keep, and protected comment patterns, each with the verification step that must pass first)
