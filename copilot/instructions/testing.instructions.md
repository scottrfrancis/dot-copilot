---
description: "Testing strategies: test pyramid, mocking, CI integration, framework-specific notes"
applyTo: "**/*.test.*,**/*.spec.*,**/tests/**,**/test/**,**/__tests__/**"
---

# Testing Strategies

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
