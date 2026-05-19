---
name: nodejs-testing
description: Node.js testing patterns for vitest, jest, and node:test. Loaded when working on .test.ts/.test.js/.spec.ts files or when the project uses vitest/jest. Provides verified patterns for unit, integration, and snapshot tests, plus mocking and async patterns.
---

# Node.js Testing Skill

Activates when writing or modifying Node.js test files. Read **before** writing any test.

## The Three Laws

1. **Test the contract, not the implementation** — if you rename a private helper your test should not break
2. **Each test is independent** — no shared state, no order dependence; `beforeEach` reset
3. **Async test = `await`, not `.then()`** — chained promises in tests hide unhandled rejections

## Framework picker

| Framework | When | Test command |
|-----------|------|-------------|
| **vitest** | Vite/Vue/SvelteKit/modern TS-first projects | `npm test` (vitest by default) |
| **jest** | Legacy projects, React Native, anything with `jest.config.js` | `npm test` |
| **node:test** | Zero-dep CLIs, libraries that want no test runner dep | `node --test` |

If the project has none → recommend `vitest` (fastest, ESM-native, TS out of the box).

## Minimum viable test (vitest example)

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { calculateTotal } from './cart';

describe('calculateTotal', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('returns 0 for empty cart', () => {
        expect(calculateTotal([])).toBe(0);
    });

    it('sums prices with tax', () => {
        const items = [{ price: 100 }, { price: 50 }];
        expect(calculateTotal(items, 0.1)).toBe(165);
    });

    it('throws on negative prices', () => {
        expect(() => calculateTotal([{ price: -1 }])).toThrow('negative');
    });
});
```

## Async patterns

### Awaited assertion
```typescript
it('fetches user', async () => {
    const user = await fetchUser(42);
    expect(user.id).toBe(42);
});
```

### Promise rejection
```typescript
it('rejects on bad ID', async () => {
    await expect(fetchUser(-1)).rejects.toThrow('invalid id');
});
```

### Fake timers
```typescript
beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

it('debounces', () => {
    const fn = vi.fn();
    debounce(fn, 100)();
    vi.advanceTimersByTime(100);
    expect(fn).toHaveBeenCalledOnce();
});
```

## Mocking patterns

### Module mock (vitest)
```typescript
vi.mock('./db', () => ({
    query: vi.fn().mockResolvedValue([{ id: 1 }])
}));
```

### Partial mock
```typescript
vi.mock('./service', async (importOriginal) => {
    const actual = await importOriginal<typeof import('./service')>();
    return { ...actual, externalCall: vi.fn() };
});
```

### Spy without replacing
```typescript
const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
// ... code that may log
expect(spy).toHaveBeenCalled();
spy.mockRestore();
```

## Coverage requirements (non-negotiable for production)

For every public function:

| Test type | Required? | Why |
|-----------|-----------|-----|
| Happy path | Yes | Baseline |
| At least one failure path | **Yes** | Failure handling is half the code |
| Edge case (empty / null / boundary) | Yes | Bugs hide in edges |
| Type validation | If runtime validation exists | Test it actually rejects |

## Forbidden patterns

| Pattern | Why |
|---------|-----|
| `expect(...).toBeTruthy()` for specific values | Hides actual vs expected; use exact match |
| `setTimeout` to "wait for async" | Use `await` or fake timers |
| `try { ... } catch { /* swallow */ }` in tests | Failure becomes silent pass |
| Real network calls (fetch to api.example.com) | Use `msw` or `vi.mock('node:fetch')` |
| `it.skip` / `xit` left in committed code | Either fix or delete |
| `console.log` for debugging in committed tests | Use the debugger or remove |

## CI integration

```json
// package.json
{
    "scripts": {
        "test": "vitest run",
        "test:watch": "vitest",
        "test:coverage": "vitest run --coverage"
    }
}
```

For CI: `npm test` should exit non-zero on any failure (`vitest run` does this by default; `vitest` watch mode does not).

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `await` on async expect | Always `await expect(promise).rejects.toThrow()` |
| Tests that pass when reordered, fail in CI | Likely shared state — add `beforeEach` reset |
| Mocking too deep (mocking the system under test) | Test the real thing, mock only its dependencies |
| Snapshot tests with huge JSON snapshots | Brittle — use shape matchers instead |
