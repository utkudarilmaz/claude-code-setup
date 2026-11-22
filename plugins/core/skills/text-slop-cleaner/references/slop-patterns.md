# Slop Patterns

The full pattern list for the `text-slop-cleaner` agent. Each entry gives the pattern, a before, and an after.

## Prose

### Hedge padding

Words that delay the sentence without adding to it.

```
Before: It is worth noting that the cache expires after ten minutes.
After:  The cache expires after ten minutes.
```

Openers to cut: `It is worth noting that`, `It is important to understand that`, `Keep in mind that`, `Note that`, `As mentioned above`, `Essentially`, `Basically`, `In essence`, `At the end of the day`.

### Throat clearing

Long forms of short things.

```
Before: In order to be able to run the tests, you will need to have Docker installed.
After:  To run the tests, install Docker.
```

Replace: `in order to` with `to`, `has the ability to` with `can`, `at this point in time` with `now`, `due to the fact that` with `because`, `a large number of` with `many`.

### Rule of three

Three adjectives where one measured fact belongs.

```
Before: A fast, reliable, and scalable message queue.
After:  A message queue that handles 50k messages a second.
```

If no number exists, name the single property that is actually true.

### Antithesis

The "not X, but Y" construction. It sounds profound and says one thing twice.

```
Before: This is not just a parser, it is a complete platform for text processing.
After:  This parses text and runs transformations on the result.
```

Also: `it is less about X and more about Y`, `X is not the point, Y is`.

### Bold label bullets

A bold word, a colon, then a sentence. Turns prose into a form.

```
Before: - **Performance**: The new index makes lookups faster.
        - **Reliability**: Retries are now automatic.
After:  The new index makes lookups faster, and retries are now automatic.
```

Keep the bold label form only in reference tables where the label is genuinely a key.

### Marketing adjectives

Delete, or replace with the fact behind them.

`robust`, `seamless`, `powerful`, `comprehensive`, `cutting edge`, `state of the art`, `world class`, `enterprise grade`, `blazing fast`, `elegant`, `intuitive`, `rich`, `flexible`.

```
Before: A robust and flexible configuration system.
After:  Configuration comes from a file, environment variables, or flags.
```

### Inflated verbs

```
leverage    -> use
utilise     -> use
delve into  -> look at
unlock      -> allow
empower     -> let
facilitate  -> help
orchestrate -> run
surface     -> show
```

### Hollow transitions

`Additionally`, `Furthermore`, `Moreover`, `That said`, `With that in mind`, `It should be noted`.

Delete them. The next sentence stands on its own. Keep genuine connectors like `but`, `so`, and `because`.

### Empty openers and closers

```
Cut: "Great question!" "Certainly!" "Absolutely!" "I hope this helps!"
Cut: "Let me know if you have any questions!" "Feel free to reach out!"
```

### Restated conclusions

A closing paragraph that repeats the document.

```
Cut: "In conclusion, as we covered above, this module handles authentication."
```

Delete it. The document already said this.

### Prompt restatement

Opening by repeating the question.

```
Before: You asked about how retries work. Retries work by ...
After:  Retries use exponential backoff, starting at 100ms.
```

### Unmeasured claims

```
Before: This significantly improves performance.
After:  This cuts the p99 from 400ms to 90ms.
```

If the number is unknown, drop the claim. Do not invent one.

### Emoji and decoration

Remove emoji from headings, bullets, and status markers. Keep the text. Replace checkmark and cross bullets with plain words or a table.

### Fake structure

Three headings on a four sentence document. A table with two rows and one column. A numbered list where order does not matter.

Remove the structure, keep the sentences.

### Repetition across sections

An overview, then a summary, then a conclusion, all saying the same thing. Keep one.

## Comments

A comment that is not 100% necessary does not stay. Accuracy is not the test: a comment can be perfectly true and still add nothing. Read the code the comment describes before cutting it, and cut it when that code already says the same thing.

### Remove: restating the code

```go
// increment the counter
counter++

// loop over the users
for _, u := range users {
```

### Remove: banner separators

```go
// ============================
// HELPER FUNCTIONS
// ============================
```

### Remove: docstrings that repeat the signature

```python
def get_user_by_id(user_id: int) -> User:
    """Get a user by ID.

    Args:
        user_id: The user ID.
    Returns:
        The user.
    """
```

Nothing here is not already in the signature. Cut it, unless a doc generator publishes it.

### Remove: change history

```go
// Added 2024-01-01 by the platform team
// Modified to handle the new format
// TODO: clean this up
```

Git holds this. A `TODO` with no owner, no date, and no issue is noise.

### Remove: commented out code

Delete it. Git has the old version.

### Remove: section and edit narration

```go
// handle errors
if err != nil {

// updated to use the new client
client := api.NewV2Client()
```

The first narrates what the reader can see. The second narrates the commit, which git already holds.

### Rewrite: stale, padded, or half useful

```go
// Retries three times.        ->  // Retries five times; the gateway
for i := 0; i < 5; i++ {       //     drops the first four under load.
```

A comment carrying real information that is stale, padded, or mixed with narration gets rewritten down to the part the code cannot say. Reach for rewrite before delete when any of the information is real.

### Keep: why, not what

```go
// The API rejects batches over 500, and returns 200 with a partial
// result rather than an error, so we chunk before sending.
for _, chunk := range chunkBy(items, 500) {
```

### Keep: invisible constraints

```go
// Must run before the cache warms, or the first request sees stale data.
```

### Keep: workarounds with a reference

```go
// Works around https://github.com/example/lib/issues/412.
// Remove once we are on v2.
```

### Keep: units, ranges, invariants

```go
// Timeout is in milliseconds. Values under 50 are rejected upstream.
```

## Protected

Never remove, never rewrite:

```
//nolint:gosec
# noqa: E501
# type: ignore
// eslint-disable-next-line no-console
# pylint: disable=too-many-arguments
// @ts-expect-error
//go:build linux
//go:generate mockgen ...
# -*- coding: utf-8 -*-
#!/usr/bin/env bash
// Code generated by protoc-gen-go. DO NOT EDIT.
// SPDX-License-Identifier: MIT
```

Also protected: godoc comments on exported Go symbols, JSDoc on published package APIs, and any docstring a documentation generator consumes.

Two more that are easy to miss, and both break the code when removed:

```ruby
# frozen_string_literal: true
```

```python
def handler():
    """The only statement in this block."""
```

The first is a pragma the interpreter reads. The second is the whole body of the function, so deleting it is a syntax error.

Also beware of lines that match a comment marker and are not comments: `//` and `#` inside string literals, URLs, YAML values, JSX. Parse by language, not by grep.

When unsure whether a comment is protected, keep it. The 100% necessary rule decides whether a comment earns its place; it never overrides this list.
