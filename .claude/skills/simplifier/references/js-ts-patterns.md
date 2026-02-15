# JavaScript/TypeScript Simplification Patterns

## Dead Code

```typescript
// DEAD: Unused import
import { unusedHelper } from './utils'

// DEAD: Unused variable
const config = loadConfig() // Never referenced

// DEAD: Unreachable code
function process() {
  return early
  console.log('never runs')
}

// DEAD: Unused exports
export const LEGACY_FLAG = true // Check if imported anywhere

// DEAD: Unused type/interface
interface OldResponse { // No references in codebase
  data: string
}
```

## Complexity

```typescript
// COMPLEX: Deep nesting
function process(data: Data | null) {
  if (data) {
    if (data.valid) {
      if (data.items) {
        // logic buried here
      }
    }
  }
}

// SIMPLIFIED: Early returns with optional chaining
function process(data: Data | null) {
  if (!data?.valid || !data.items?.length) return
  // logic at top level
}
```

```typescript
// COMPLEX: Long boolean expression
if (user && user.active && !user.banned && user.role === 'admin' && user.verified) {}

// SIMPLIFIED: Extract to descriptive variable
const isActiveAdmin = user?.active && !user.banned &&
                      user.role === 'admin' && user.verified
if (isActiveAdmin) {}
```

```typescript
// COMPLEX: Callback hell
getData(id, (data) => {
  processData(data, (result) => {
    saveResult(result, (saved) => {
      notify(saved, () => {})
    })
  })
})

// SIMPLIFIED: async/await
const data = await getData(id)
const result = await processData(data)
const saved = await saveResult(result)
await notify(saved)
```

```typescript
// COMPLEX: Nested ternaries
const label = isAdmin ? 'Admin' : isMod ? 'Moderator' : isUser ? 'User' : 'Guest'

// SIMPLIFIED: Map lookup or function
const roleLabels: Record<string, string> = { admin: 'Admin', mod: 'Moderator', user: 'User' }
const label = roleLabels[role] ?? 'Guest'
```

## JS/TS-Specific Checks

| Pattern | Issue | Fix |
|---------|-------|-----|
| `any` type | Type safety bypass | Use proper types or `unknown` |
| Async function without `await` | Likely missing await or unnecessary async | Add await or remove async |
| Unused React hook dependencies | Stale closures, subtle bugs | Add missing deps or restructure |
| Promise without `.catch()` or try/catch | Unhandled rejection | Add error handling |
| `== null` vs `=== null` inconsistency | Inconsistent nullish checks | Use `== null` (covers undefined) or strict consistently |
| Mixed async patterns | Callbacks + promises + async/await | Standardize on async/await |
| `useEffect` without cleanup | Memory leak with subscriptions/timers | Return cleanup function |
| Re-renders from inline objects/functions | Performance issue | Use `useMemo`/`useCallback` or extract |
| `JSON.parse()` without try/catch | Runtime crash on invalid input | Wrap in try/catch |
| Barrel exports re-exporting everything | Tree-shaking issues, slow builds | Export only what's needed |
| Optional chaining opportunities | Verbose null checks | Replace `a && a.b && a.b.c` with `a?.b?.c` |
| `Object.keys().forEach` | Verbose iteration | Use `Object.entries()` or `for...of` |
