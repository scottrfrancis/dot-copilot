---
description: "Record a manual quality/stall/continue observation into the tokometer ledger"
mode: agent
tools: ["executeCommand"]
---
# Observe — one-line manual observation

Record the signal no log captures: the human quality judgment, and the
continue-vs-stall distinction. Keep it under ten seconds.

## What to run

The field kit installs the `observe` entry point (tokometer). Map the user's report
to one invocation:

- Quality rating (1–5, optional note):

  ```bash
  observe 4 "clean plan, correct edit, one retry"
  ```

- The benign "working for a while — continue?" prompt appeared:

  ```bash
  observe --continue-prompt
  ```

- A silent stall (agent dead, no prompt):

  ```bash
  observe --stall
  ```

- Rating plus the model seen on hover (or identified by style fingerprint —
  e.g. Haiku's colored-ball status emojis):

  ```bash
  observe 2 --model claude-haiku-4.5 "table-heavy filler answer"
  ```

## Rules

- One observation per event; don't batch or reconstruct hours later.
- Quality is the user's judgment, not yours — ask for the number if not given.
- If `observe` isn't on PATH, run it from the tokometer install:
  `python3 ~/.tokometer/collectors/copilot_observe.py <args>`.
