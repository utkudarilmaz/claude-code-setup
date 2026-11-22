# Rust Simplification Patterns

## Dead Code

```rust
// DEAD: Unused import
use std::fmt; // Never used

// DEAD: Unused variable
let config = load_config(); // Never referenced

// DEAD: Unreachable code
fn process() -> i32 {
    return compute();
    println!("never runs");
}

// DEAD: Unused function
fn old_helper() {} // No callers found

// DEAD: Warning suppression hiding dead code
#[allow(dead_code)]
fn unused() {} // Remove the function instead of silencing the compiler
```

## Complexity

```rust
// COMPLEX: Nested matching
fn user_name(id: u32) -> Option<String> {
    match find_user(id) {
        Some(user) => match user.profile {
            Some(profile) => Some(profile.name),
            None => None,
        },
        None => None,
    }
}

// SIMPLIFIED: Combinators
fn user_name(id: u32) -> Option<String> {
    find_user(id).and_then(|user| user.profile).map(|profile| profile.name)
}
```

```rust
// COMPLEX: Deeply nested if-let
fn handle(input: Option<Input>) {
    if let Some(input) = input {
        if input.valid {
            if let Some(items) = input.items {
                // logic buried
            }
        }
    }
}

// SIMPLIFIED: let-else and early returns
fn handle(input: Option<Input>) {
    let Some(input) = input else { return };
    if !input.valid {
        return;
    }
    let Some(items) = input.items else { return };
    // logic at top level
}
```

```rust
// COMPLEX: Manual accumulation loop
let mut names = Vec::new();
for user in users {
    if user.active {
        names.push(user.name.clone());
    }
}

// SIMPLIFIED: Iterator chain
let names: Vec<_> = users.iter().filter(|u| u.active).map(|u| u.name.clone()).collect();
```

## Rust-Specific Checks

| Pattern | Issue | Fix |
|---------|-------|-----|
| `.unwrap()` / `.expect()` outside tests | Panics in production on the error path | Propagate with `?` or handle the `Err`/`None` case |
| Unneeded `.clone()` | Extra allocation to satisfy the borrow checker quickly | Borrow instead, or restructure ownership |
| `fn f(s: String)` for read-only use | Forces callers to allocate or move | Take `&str` (or `&[T]` instead of `Vec<T>`) |
| `match` with two arms returning bool | Verbose for a predicate | Use `matches!` or the condition directly |
| `if x { true } else { false }` | Restates the condition | Return the condition itself |
| `.iter().map(...).collect()` for side effects | Allocates a throwaway collection | Use a `for` loop |
| `collect()` then immediately iterate again | Intermediate allocation | Keep the iterator chain lazy |
| `return expr;` as the last statement | Non-idiomatic | Use the tail expression |
| `Rc<RefCell<T>>` where one owner exists | Runtime borrow checking without need | Use plain ownership or `&mut` |
| `Box<T>` for small sized types | Pointless heap allocation | Store the value directly |
| `#[allow(...)]` without a reason | Hides a warning the code should fix | Fix the warning or justify the allow |
| Ignored `Result` (`let _ = fallible()`) | Error silently dropped | Handle or propagate the error |
| `unsafe` block wider than needed | Enlarges the audit surface | Shrink to the exact unsafe operation |
| String building with repeated `format!` | Allocation per iteration | Use `push_str` or `write!` into one buffer |
