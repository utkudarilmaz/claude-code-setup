# Python Simplification Patterns

## Dead Code

```python
# DEAD: Unused import
import os  # Never used

# DEAD: Unused variable
config = load_config()  # Never referenced

# DEAD: Unreachable code
def process():
    return early
    print("never runs")

# DEAD: Unused function
def _old_helper():  # No callers found
    pass

# DEAD: Redundant pass
class MyError(Exception):
    pass  # Only needed if class body is truly empty and has no docstring
```

## Complexity

```python
# COMPLEX: Deep nesting
def process(data):
    if data:
        if data.valid:
            if data.items:
                # logic buried

# SIMPLIFIED: Early returns
def process(data):
    if not data or not data.valid or not data.items:
        return
    # logic at top level
```

```python
# COMPLEX: Manual dict building
result = {}
for item in items:
    result[item.key] = item.value

# SIMPLIFIED: Dict comprehension
result = {item.key: item.value for item in items}
```

```python
# COMPLEX: Nested try/except
def fetch_data():
    try:
        response = requests.get(url)
        try:
            data = response.json()
            try:
                return process(data)
            except ProcessError:
                return default
        except json.JSONDecodeError:
            return default
    except requests.RequestException:
        return default

# SIMPLIFIED: Combined exception handling
def fetch_data():
    try:
        response = requests.get(url)
        data = response.json()
        return process(data)
    except (requests.RequestException, json.JSONDecodeError, ProcessError):
        return default
```

## Python-Specific Checks

| Pattern | Issue | Fix |
|---------|-------|-----|
| `def fn(items=[])` | Mutable default argument shared across calls | Use `None` default, assign inside |
| `except Exception:` / `except:` | Broad exception catches everything | Catch specific exceptions |
| `type(x) == str` | Doesn't handle subclasses | Use `isinstance(x, str)` |
| Unused `*args, **kwargs` | Unnecessary parameter forwarding | Remove if not needed |
| `len(x) == 0` / `len(x) > 0` | Non-Pythonic truth testing | Use `if not x:` / `if x:` |
| Manual context management | Missing `with` statement | Use `with open()` instead of manual close |
| Shadowing builtins | `list = [1,2]`, `id = 5` | Use descriptive names |
| `global` keyword | Hidden state mutation | Pass as parameter or use class |
| String concatenation in loops | O(n^2) allocation | Use `"".join()` or f-strings |
| Bare `assert` in production | Disabled with `-O` flag | Use explicit `if`/`raise` |
| Shell commands with `shell=True` | Command injection risk, complexity | Use `subprocess.run()` with list args |
| Nested list comprehensions | Readability issue when > 2 levels | Extract to loops or helper functions |
