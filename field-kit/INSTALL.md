# Install the field kit into this project — paste into Copilot Chat

> **To the Copilot agent reading this:** this is an install script for you to execute
> in the currently-open project, not a document for the human to read. Work in **Manual
> mode**: propose each change, show a diff, wait for approval before writing. Never wipe
> or overwrite blindly — this project's `.github/` may already have real content that
> matters. Plain language; explain each step before doing it.

## What you are installing

The extracted field kit sits in this workspace at **`field-kit/`** (if it's somewhere
else, ask the human for the path). Its payload is `field-kit/copilot/`:

```
field-kit/copilot/
  copilot-instructions.md      -> .github/copilot-instructions.md
  instructions/*.instructions.md -> .github/instructions/
  prompts/*.prompt.md          -> .github/prompts/     (the runnable /commands)
  hooks/                       -> .github/hooks/
```

Goal: merge that payload into this project's `.github/` **without destroying anything
already there.**

## Do this, one step at a time

1. **Survey.** List what already exists under `.github/` (instructions, prompts, hooks,
   and especially an existing `copilot-instructions.md`). Report it before touching
   anything. Create `.github/` if it's absent.

2. **`copilot-instructions.md` — never clobber.** This file is the project's global
   Copilot brief and may be project-specific.
   - If the project has **none**, copy the kit's in.
   - If it **already has one**, do NOT overwrite it. Show me both, then propose a
     *merged* version that keeps the project's specifics and folds in the kit's global
     rules (TDD, conventional commits, the Copilot-Auto tactics pointer). I approve the
     merge before you write it.

3. **`instructions/`, `prompts/`, `hooks/` — merge file-by-file.** For each kit file:
   - If the destination doesn't exist → copy it in.
   - If it exists and is **identical** → skip, say so.
   - If it exists and **differs** → show the diff and ask. Default to backing up the
     project's version as `<name>.bak` and installing the kit's, but let me choose
     keep-mine / take-kit / merge per file.
   These directories hold many coexisting files, so adding the kit's alongside the
   project's is normal — collisions are the only thing to stop on.

4. **Verify.** Confirm the runnable commands landed: `.github/prompts/` should contain
   `lets-go.prompt.md`, `handoff.prompt.md`, `recover.prompt.md`, etc. Tell me how to
   invoke them (type `/lets-go` in Chat) and that a VS Code reload may be needed for
   them to appear.

5. **Clean up.** Offer to delete the transient `field-kit/copilot/` from the workspace
   now that it's installed (keep `field-kit/USING-COPILOT.md` and `field-kit/RUNBOOK.md`
   if I want the operator docs in-repo; otherwise remove the whole `field-kit/` folder).
   Ask before deleting.

## Report at the end

- What was installed, what was skipped (identical), what was backed up (needs my review).
- Whether `copilot-instructions.md` was merged or created.
- The one thing I should do next: reload VS Code, then try `/lets-go`.

If anything is ambiguous — an unexpected existing file, a merge you're unsure about —
**stop and ask.** A wrong overwrite here loses the project's own config.
