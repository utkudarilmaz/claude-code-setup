# Deep Mode

The walkthrough structure for the `explain` agent when the user asks for depth.

Deep mode adds detail. It does not change the tone. Every rule from the default mode still applies: everyday words, terms defined where they first appear, no invented reasons.

## Structure

Start with the whole default output, then add three parts.

### 1. Walkthrough

Follow execution order, not file order. Each step gets an anchor and a plain sentence.

```markdown
## Step by step

1. `cmd/server/main.go:42` reads the config file. If the file is missing
   it uses the built in defaults rather than failing.
2. `internal/queue/queue.go:88` opens the connection. This blocks until
   the broker answers or five seconds pass.
3. `internal/queue/retry.go:31` wraps the handler. Every message now goes
   through the retry path, including the ones that would have succeeded.
```

Rules:

- One step per thing that happens, not one per line of code
- Anchor every step with `file:line`
- Say what happens, then say what is surprising about it
- Quote code only when the code itself is the point, and keep the quote short
- When execution branches, follow the common path first and name the other one

### 2. Worked Example

Trace one concrete input all the way to its output. Use real values, never placeholders.

```markdown
## Worked example

A message arrives with `id=8821` and `attempts=2`.

- `retry.go:31` sees `attempts=2`, which is under the limit of 5, so it
  continues rather than sending the message to the dead letter queue.
- `retry.go:44` works out the wait: 100ms doubled twice, giving 400ms.
- The handler runs and returns a timeout error.
- `retry.go:52` writes back `attempts=3` and requeues.

The same message with `attempts=5` skips all of this and goes straight to
the dead letter queue at `retry.go:35`.
```

Pick an input that goes through the interesting path. A trivial input that returns early teaches nothing.

### 3. Edge Cases

What the code does when things are not normal.

```markdown
## Edge cases

| Situation | What happens |
|-----------|--------------|
| Empty batch | Returns immediately, no call is made |
| Broker unreachable | Blocks for 5s, then returns a wrapped error |
| Attempts above the limit | Straight to the dead letter queue, handler never runs |
| Negative timeout in config | Not checked. The ticker panics at `queue.go:96` |
```

Include the cases the code does not handle. Those are the useful ones.

## Code You Cannot Fully Explain

This is where deep mode is most likely to go wrong. More space invites filling it.

When something is unclear, write it as unclear:

```markdown
`retry.go:61` skips the backoff when the error message contains
"throttled". I could not find why. The commit that added it says only
"fix retries", there is no linked issue, and no test covers this branch.
Asking whoever added it, or checking the broker's throttling docs, would
answer it.
```

That paragraph is more useful than a confident guess. The reader now knows there is a real question here.

Signs the walkthrough is drifting into invention:

- A step describes what the code does and calls it why it exists
- The explanation uses the function's own name as its meaning
- The words "presumably", "likely intended to", or "this is probably for" appear
- A design decision is explained with no commit, issue, or comment behind it

When any of those appear, replace the sentence with what is actually known and what is not.

## Length

Deep mode is longer than default mode because it covers more, not because it says the same things at greater length.

A 40 line file does not need 400 lines of walkthrough. Stop when the code is covered.
