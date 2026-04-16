---
name: "autocommit"
description: "Analyze changes and generate conventional commit message with AI"
tools: ["executeCommand", "readFile", "searchFiles"]
---

# Auto-Commit with Conventional Commits

Analyze the current git changes and generate a commit message following the Conventional Commits specification.

## Process

1. **Load conventions**: If `docs/guidelines/commits-and-branching.md` exists, read it for project-specific commit types, scopes, and conventions. Otherwise, use standard Conventional Commits.
2. **Check git status**: Run `git status --porcelain` to see all changes
3. **Analyze changes**: Run `git diff` and `git diff --cached` to understand what changed
4. **Generate commit message** following this format:

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `build`, `ci`, `perf`, `style`, `chore`, `revert`

Use `feat` only for genuinely new capabilities. Enhancements to existing features are `refactor` or `fix`.

5. **Show the proposed message** to the user for approval
6. **Stage and commit** if approved:
   ```bash
   git add .
   git commit -m "<message>"
   ```

## Rules

- Keep the subject line under 72 characters
- Imperative mood, lowercase, no period: "add endpoint" not "Added endpoint."
- Use project-specific scopes from `docs/guidelines/commits-and-branching.md` if available
- Add a body for non-trivial changes explaining the "why"
- Add `BREAKING CHANGE:` footer if the change breaks an API contract
- Add `Refs: #N` or `ADO: #N` to reference issues/work items
- Always show the proposed message before committing
