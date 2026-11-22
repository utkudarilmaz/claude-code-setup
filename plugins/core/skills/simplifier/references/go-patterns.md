# Go Simplification Patterns

## Dead Code

```go
// DEAD: Unused import
import "fmt" // Never used - Go compiler catches this

// DEAD: Unused variable (use blank identifier or remove)
result, err := doSomething()
// result never used

// DEAD: Unreachable code
func process() error {
    return nil
    log.Println("never runs") // Unreachable
}

// DEAD: Unused exported function
// Check all callers before removing - exported functions may be used by other packages
func DeprecatedHelper() {} // No callers found
```

## Complexity

```go
// COMPLEX: Deep nesting
func process(data *Data) error {
    if data != nil {
        if data.Valid {
            if len(data.Items) > 0 {
                // logic buried here
            }
        }
    }
    return nil
}

// SIMPLIFIED: Early returns
func process(data *Data) error {
    if data == nil || !data.Valid || len(data.Items) == 0 {
        return nil
    }
    // logic at top level
}
```

```go
// COMPLEX: Repetitive error handling
func createUser(u *User) error {
    if err := validate(u); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }
    if err := save(u); err != nil {
        return fmt.Errorf("save failed: %w", err)
    }
    if err := notify(u); err != nil {
        return fmt.Errorf("notify failed: %w", err)
    }
    return nil
}

// SIMPLIFIED: Concise error wrapping
func createUser(u *User) error {
    if err := validate(u); err != nil {
        return fmt.Errorf("validation: %w", err)
    }
    if err := save(u); err != nil {
        return fmt.Errorf("save: %w", err)
    }
    if err := notify(u); err != nil {
        return fmt.Errorf("notify: %w", err)
    }
    return nil
}
```

## Go-Specific Checks

| Pattern | Issue | Fix |
|---------|-------|-----|
| `result, _ := fn()` | Unchecked error when err matters | Handle or explicitly document why ignored |
| `interface{}` | Empty interface abuse | Use concrete type or type constraint |
| `defer` in loops | Resource leak risk | Extract to function or close explicitly |
| Mutex not unlocked on all paths | Deadlock risk | Use `defer mu.Unlock()` immediately after Lock |
| Context not propagated | Cancellation doesn't cascade | Pass `ctx` through function chain |
| Goroutine without cancellation | Goroutine leak | Use context or done channel |
| `sync.WaitGroup` misuse | Race on Add/Done | Call `wg.Add()` before goroutine launch |
| Naked return in long functions | Readability issue | Use explicit returns when function > 10 lines |
| String concatenation in loops | Allocation overhead | Use `strings.Builder` |
| `init()` with side effects | Hidden initialization, test difficulty | Use explicit initialization functions |
