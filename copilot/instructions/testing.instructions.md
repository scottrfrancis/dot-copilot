---
description: "Testing strategies: TDD (required), test pyramid, mocking, CI integration, framework-specific notes"
applyTo: "**/*.test.*,**/*.spec.*,**/tests/**,**/test/**,**/__tests__/**"
---

# Testing Strategies

## Red-Green-Refactor TDD (REQUIRED — ALWAYS)

**Red-Green-Refactor TDD is mandatory for every code change.** No production code is written without a failing test first. This applies to bug fixes, new features, and refactors alike. There is no "I'll add tests later." Tests come first, always.

The cycle — repeat for every behavior:

1. **🔴 RED** — Write a failing test that expresses the desired behavior. Run it and confirm it fails for the right reason (the behavior is missing, not a typo/compile error). Do NOT write production code yet.
2. **🟢 GREEN** — Write the minimum production code needed to make the failing test pass. Resist adding logic the current test doesn't require.
3. **🔵 REFACTOR** — With all tests green, clean up the code: remove duplication, improve names, clarify structure. Tests must stay green throughout.

### Non-negotiable rules

- **Never** write production code without a corresponding failing test first.
- **Never** write more than one failing test at a time.
- **Never** add production logic beyond what the currently-failing test demands.
- **Always** run the test between RED and GREEN to verify it actually fails for the right reason.
- **Always** keep cycles short — minutes, not hours. If a cycle runs long, the increment is too big; split it.
- **No retroactive tests.** Tests added after the production code they exercise do not count as TDD and must be flagged in review.

### Narrow exceptions

The only acceptable reasons to write code before a test:

- **Spikes** — throwaway exploratory code in `/tmp` or a scratch branch. Production code derived from a spike must be re-built via TDD.
- **Pure config changes** — no behavior, no tests required.
- **Generated code** — protobuf stubs, ORM migrations, lockfiles.

If you think you have another exception, you do not. Write the test.

## Test Pyramid

1. **Unit tests** — Fast, isolated, no I/O. Cover pure logic and edge cases. Target >=85% on business logic.
2. **Integration tests** — Verify component boundaries: database queries, API endpoints, service interactions.
3. **E2E tests** — Critical user flows only. Keep count low.

## What to Test

### Always test
- Public API contracts (inputs, outputs, error responses)
- Business logic with branching (calculations, state machines, validation)
- Error handling paths
- Security boundaries (auth checks, tenant isolation, input sanitization)

### Skip testing
- Framework boilerplate (constructors, getter/setter pass-through)
- Third-party library behavior
- Private implementation details
- Generated code (protobuf stubs, ORM migrations)

## Assertion Patterns

- One logical assertion per test
- Assert on behavior, not implementation
- Use precise matchers: `toEqual` over `toBeTruthy`

## Mocking Guidelines

- Mock at boundaries: HTTP clients, databases, clocks, random generators
- Prefer fakes over mocks when the boundary is simple
- Never mock what you don't own without an integration test backing it up
- Reset mocks between tests

## Edge Cases to Cover

- Empty/zero/null values
- Boundary values (0, -1, MAX_INT, empty string)
- Invalid types (if the language allows it)
- Concurrent access (if applicable)

## CI Integration

- Tests must pass before merge — no exceptions
- Fail fast: unit first, integration second, E2E last
- Set a coverage floor (e.g., 85%) that blocks PRs
- Quarantine flaky tests immediately

## Framework Notes

- **JS/TS**: Prefer `vitest` or `jest`. Use `msw` for HTTP mocking. `playwright` for E2E.
- **Python**: Prefer `pytest` with `pytest-cov`. Use `conftest.py` fixtures.
- **Arduino/PlatformIO**: Use `unity` test framework. Test hardware logic behind fakeable interfaces.
