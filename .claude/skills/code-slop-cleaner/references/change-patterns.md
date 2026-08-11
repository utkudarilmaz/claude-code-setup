# Change Patterns

The pattern list for the `code-slop-cleaner` agent. Every pattern comes with the check that must pass before it can be reported. An unverified suspicion is not a finding.

## Establishing the Purpose

Read in this order, and stop at the first that gives a clear answer:

1. The linked issue or ticket, found in the PR body or a commit trailer
2. The pull request body
3. The commit messages on the branch
4. The user's own description

If none give a clear purpose, ask:

> "I could not find what this change is for. I checked [what you checked]. What was the goal, in one sentence?"

Do not proceed without an answer. A purpose read out of the diff will justify the whole diff.

Write the purpose at the top of the report so a wrong reading is visible.

## Patterns

### Defensive check the caller already guarantees

```go
func process(u *User) error {
    if u == nil {
        return errors.New("user is nil")
    }
```

**Verify:** find every caller. If the type system, a prior check, or the language guarantees non nil at every call site, name the guarantee. If any caller can pass nil, this is REQUIRED.

### Catch that rethrows unchanged

```python
try:
    result = compute()
except Exception as e:
    raise e
```

**Verify:** confirm nothing happens in the handler. No logging, no wrapping, no translation, no cleanup. If anything happens, it stays.

### Abstraction with one implementation

An interface, factory, strategy, or registry with exactly one concrete type behind it.

**Verify:** count the implementations in the repository. One means premature. Also check whether a test double is the second implementation, which does not count as a real one, and whether the interface exists to break an import cycle, which does.

### Config flag with one caller on the default

```go
func NewClient(opts ...Option) *Client
// WithTimeout added, never called
```

**Verify:** search every call site for a non default value. Include tests and other repositories if this is a shared library. A public API's option is not unnecessary just because this repository does not use it.

### Compatibility shim for code that never shipped

A fallback path, a deprecated alias, or a version check for a format that has no released version using it.

**Verify:** check the git history and tags for a release containing the old form. If none exists, nothing can be on it.

### Duplicate helper

A new utility that repeats something already present.

**Verify:** find the existing one and name it with its path. "This looks like something that probably exists" is not a finding.

### Demo and example blocks

```python
if __name__ == "__main__":
    print(process("example"))
```

**Verify:** check for a caller, a documented use, or a test that runs it. Entry points for real commands are REQUIRED.

### Tests that assert a mock was called

```python
service.save(user)
mock_repo.save.assert_called_once_with(user)
```

**Verify:** read what the test proves. If the only assertion is that the code called the thing it obviously calls, the test restates the implementation. If it checks a real contract, ordering, or a value transformation, it stays.

This is the one place to be careful. Never flag a test that covers behaviour.

### Parameter added, defaulted, never passed

**Verify:** search every call site, including tests, reflection, dynamic dispatch, and any serialised call.

### New dependency replacing a few lines

**Verify:** read what the dependency is actually used for. One function used once is a finding. Broad use is not.

### Error type nobody catches distinctly

```go
type ValidationError struct{ ... }
```

**Verify:** search for a catch or type switch that treats it differently from a plain error. If everything handles it the same way, the type adds nothing.

### Logging on every line

**Verify:** compare with the logging density in nearby existing code. Match the project, do not impose a level.

### Reformatting in an unrelated diff

Whitespace, import reordering, or renames that touch lines the change does not need.

**Verify:** check whether a formatter did it automatically on save. If the project runs one, this is noise, not a finding. Report it as UNRELATED at most.

### Documentation for an internal one liner

**Verify:** check whether a doc generator publishes it, or the language convention requires it on exported symbols.

## Never Flag

- Tests covering behaviour the change introduces
- Error handling at real boundaries: network, disk, user input, external APIs, parsing untrusted data
- A public API's compatibility layer
- Anything as unused without having searched for its users
- Framework contracts: lifecycle hooks, registered handlers, middleware, `init` functions, dependency injection providers
- Work the user explicitly asked for. If it does not fit the written purpose, say the purpose looks out of date

## Choosing Between Unnecessary and Unrelated

| Question | Unnecessary | Unrelated |
|----------|-------------|-----------|
| Would you want this in a separate commit? | No | Yes |
| Does it solve a real problem? | No | Yes |
| Does it serve this change's purpose? | No | No |

When both fit, choose UNRELATED. Removing useful work is the more expensive mistake.

## Apply Mode

1. Remove UNNECESSARY units only, smallest blast radius first
2. Find the test command from the build files, the README, or the CI config
3. Run it
4. Report the result honestly, including the failure output when it fails

Never claim a passing test run without having run it. Never remove UNRELATED work.
