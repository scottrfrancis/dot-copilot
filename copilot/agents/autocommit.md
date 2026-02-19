---
name: "autocommit"
description: "Analyze changes and generate conventional commit message with AI"
tools: ["executeCommand", "readFile", "searchFiles"]
---

# Auto-Commit with Conventional Commits

Analyze the current git changes and generate a commit message following the Conventional Commits specification.

## Process

1. **Check git status**: Run `git status --porcelain` to see all changes
2. **Analyze changes**: Run `git diff` and `git diff --cached` to understand what changed
3. **Generate commit message** following this format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Common types:
- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files

4. **Show the proposed message** to the user for approval
5. **Stage and commit** if approved:
   ```bash
   git add .
   git commit -m "<message>"
   ```

## Rules

- Keep the subject line under 72 characters
- Use present tense and imperative mood
- Don't capitalize the first letter after the colon
- No period at the end of the subject line
- Add a body for non-trivial changes explaining the "why"
- Always show the proposed message before committing
