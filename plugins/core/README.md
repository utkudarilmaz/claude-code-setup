# core

Agents, skills and hooks for everyday work in Claude Code: docs, tests,
security audits, code cleanups, review checks, changelogs, release tags and
pull requests.

## Install

```
/plugin install core --marketplace utkudarilmaz/claude-code-setup
```

## What It Adds

- **Skills:** `/changelog`, `/code-slop-cleaner`, `/create-pr`, `/docs`,
  `/pr-comment-cleaner`, `/release-tag`, `/review-analyzer`, `/security-audit`,
  `/seo`, `/simplifier`, `/tester`, `/text-slop-cleaner`. Each also works as
  `/core:<name>`, which you need when another command has the same name.
- **Agents:** the ten skills other than `/changelog` and `/release-tag` each
  dispatch an agent of the same name. `/changelog` uses `changelog-generator`
  and `release-notes`. All are named `core:<agent>`.
- **Hooks:** block edits to secret files such as `.env`, block `git merge` and
  `gh pr merge` while the tree has uncommitted changes, and play a sound on
  notifications.

The hooks need Bash. The notification sound uses `afplay` on macOS and
`paplay` or `aplay` on Linux, and stays silent when none is found.

See the [repository README](../../README.md) for the shared settings that go
with this plugin, and [Skills Reference](../../docs/reference/skills.md) for
every command.
