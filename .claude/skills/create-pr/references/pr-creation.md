# PR Creation Reference

The mechanics behind `/create-pr`: what to check before touching anything, how to commit and push, how to write the title, and which fields to set.

## Preflight

| Check | Command | Message on failure |
|-------|---------|--------------------|
| `gh` installed | `gh --version` | `gh CLI is not installed. Install it and try again.` |
| Authenticated | `gh auth status` | `gh is not authenticated. Run: gh auth login` |
| In a repository | `git rev-parse --show-toplevel` | `Not inside a git repository.` |
| Has a remote | `git remote get-url origin` | `This repository has no origin remote. Add one and try again.` |
| On a branch | `git branch --show-current` | `HEAD is detached. Check out a branch first.` |

Stop on the first failure with that one line and nothing else. No retries, no workarounds.

## Reading the State

```bash
BRANCH=$(git branch --show-current)
DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
git status --porcelain
gh pr view --json number,title,body,baseRefName,url,isDraft
```

`gh pr view` exiting non-zero means there is no PR for the branch. That is the create path, not an error. A PR that already exists is the update path, whatever mode the user asked for.

## Branch Naming

Only when the current branch is the default branch. Read `git branch -r` first and follow whatever the repository already does. With no clear convention, use `type/short-slug` with the same type word as the commit:

| Change | Branch |
|--------|--------|
| New retry wrapper | `feat/webhook-retry` |
| Fixing double charges | `fix/duplicate-charges` |
| Docs pass | `docs/readme-install` |

Slugs are lower case, words joined by hyphens, three words at most.

## Commit

Skip entirely when `git status --porcelain` prints nothing.

Stage tracked changes and untracked files git does not ignore:

```bash
git add <explicit paths>
```

Rules:

- List the paths explicitly. `git add .` sweeps in files nobody meant to commit
- Never pass `-f`. If the sensitive file hook blocks a path, leave it out and say which file was skipped
- One commit per run. Split only when the user asked for it
- Conventional commit message, present tense, no body unless the change needs one:

```bash
git commit -m "feat: retry the Stripe webhook handler on timeout"
```

| Type | Use for |
|------|---------|
| `feat` | New behaviour |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `refactor` | Restructuring with no behaviour change |
| `perf` | Speed or resource use |
| `test` | Tests only |
| `chore` | Tooling, dependencies, config |

Print the staged paths and the message before committing. Do not wait for approval; invoking the skill was the approval.

Never add a `Co-Authored-By` line, an AI attribution footer, or a task ID.

## Push

```bash
git push -u origin "$BRANCH"
```

`-u` sets the upstream so later `git push` and `gh pr` calls resolve without arguments. A branch that already tracks a remote just needs `git push`.

If the push is rejected, stop and report it. Never force push, and never rebase or reset to make the push go through.

## Title

One line, conventional commit form, under 70 characters, lower case after the type, no trailing period.

| Do not write | Write |
|--------------|-------|
| Update files | `fix: stop duplicate charges on webhook retry` |
| feat: This PR adds a new retry wrapper for the Stripe webhook handler | `feat: retry the Stripe webhook handler on timeout` |
| Bug fixes and improvements | `fix: clear the session cookie on logout` |
| feat: PROJ-1421 add retry | `feat: retry the Stripe webhook handler on timeout` |

Check the repository first:

```bash
gh pr list --state merged --limit 5 --json title
```

When merged PRs clearly follow another convention, follow the repository instead.

On the update path, replace the title only when it is vague, wrong, or no longer matches the commits. A title that still fits stays as the author wrote it.

## Fields

| Field | Flag | Rule |
|-------|------|------|
| Base | `--base` | The default branch, or the branch the user named. On update, the PR's existing base |
| Head | `--head` | The current branch |
| Draft | `--draft` | `draft` mode, or the user says the work is unfinished |
| Assignee | `--assignee @me` | Always |
| Reviewer | `--reviewer` | The user names one, or CODEOWNERS matches a changed file |
| Label | `--label` | An existing label fits the change |
| Milestone | `--milestone` | The user names one, or the linked issue carries one |

Leave a flag off when its rule does not fire. An empty field beats a guessed one.

### Reviewers

Read CODEOWNERS from `.github/CODEOWNERS`, `CODEOWNERS`, or `docs/CODEOWNERS`, and match the changed paths against its patterns. Team entries (`@org/team`) pass to `--reviewer` the same way users do. Print who was requested so the author sees who got pinged.

### Labels

```bash
gh label list --json name -q '.[].name'
```

Match the commit type to a label that already exists: `fix` to a bug label, `feat` to a feature or enhancement label, `docs` to a documentation label. No match means no label. Never run `gh label create`.

## Creating

```bash
gh pr create \
  --base "$DEFAULT" \
  --head "$BRANCH" \
  --title "feat: retry the Stripe webhook handler on timeout" \
  --assignee @me \
  --body "$(cat <<'EOF'
## What

...
EOF
)"
```

The quoted heredoc keeps backticks and dollar signs in the body from being expanded by the shell.

## Updating

```bash
gh pr edit <number> --body "$(cat <<'EOF'
## What

...
EOF
)"

gh pr edit <number> --title "fix: stop duplicate charges on webhook retry"
```

Add `--add-label`, `--add-reviewer`, `--add-assignee`, or `--milestone` only when the user asked for that change. Editing a PR never removes a field somebody set by hand.

## Reporting

Print, in this order:

1. The branch, and whether it was created
2. The commit message, or that the tree was already clean
3. The fields that were set
4. The PR URL
