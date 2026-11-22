# Fix Validity Patterns

What to check before giving a proposed fix its verdict, and what a better fix must state. Every pattern comes with the check that must pass before it can be reported. A pattern spotted without its check is a suspicion, not a verdict.

## Patterns That Make a Fix INVALID

| Pattern | What to check first |
|---------|--------------------|
| Fix targets a different code path than the bug | Trace the failing input through the code and confirm it never reaches the changed lines |
| Fix breaks other callers | Search every call site of the changed function, including tests and dynamic dispatch |
| Fix reintroduces the bug under another input | Walk the fix with the input from the issue and at least one variation of it |
| Fix contradicts a framework contract | Name the lifecycle rule, hook signature, or interface the fix violates |
| Fix suppresses the symptom | Confirm the catch swallows the error or the null check hides the real failure instead of handling it |

## Patterns That Make a Fix PARTIAL

| Pattern | What to check first |
|---------|--------------------|
| Fixes the symptom, not the cause | Name the root cause and show the fix leaves it in place |
| Covers some call sites but not all | List the call sites and name the ones the fix misses |
| Misses an edge case the issue names or implies | Walk the fix with the empty input, the error path, or the concurrent case the issue points at |
| Fix in the wrong layer | Show the broken callee being patched around in the caller, or handler validation that belongs in the model |
| Missing the test the review asked for | Confirm the review asked for a test and the fix does not include one |

## Patterns That Make an Issue NOT A BUG

| Pattern | What to check first |
|---------|--------------------|
| The concern is already guaranteed | Name the type, caller check, or validation that makes the feared input impossible |
| The behaviour is intentional | Name the test, comment, or documentation that pins the behaviour |
| The reviewer read outdated code | Show the current lines and note when they changed relative to the review |

## What a Better Fix Must State

A proposed replacement fix is only useful when it is concrete. Every better fix states:

1. The root cause in one sentence
2. The file and place to change
3. What the change is, in plain words
4. Why other callers stay correct after the change
5. The existing helper or pattern it reuses, when one exists

A better fix that cannot state all of these is not ready to propose. Say what is still unknown instead.

## When No Verdict Is Possible

Some fixes cannot be judged from the code alone: they depend on runtime behaviour, external services, or data that is not in the repository. Do not guess. Give the issue CANNOT VERIFY, say what was checked, and say what would settle it: a log line, a reproduction, a question to the reviewer.
