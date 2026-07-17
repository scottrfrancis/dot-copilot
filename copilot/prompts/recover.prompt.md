---
description: "Diagnose a Copilot stall/error/degradation by mechanism, apply the matching fix, and log the event"
mode: agent
tools: ["executeCommand", "readFile", "listDirectory"]
---
# Recover — Copilot failure triage

Something went wrong: a stall, an error, or output that suddenly got worse. Do NOT
respond by simplifying the prompt — that's the doom-loop trigger. Diagnose which
mechanism fired, apply its fix, and record the event so the data accumulates.

## 1. Identify the event

Ask the user (or determine from what they report) which shape this is:

| Shape | Signature | Mechanism |
|---|---|---|
| **Benign pause** | Explicit "Copilot has been working for a while. Continue?" prompt with a button | Iteration cap (`chat.agent.maxRequests`) — not a failure |
| **Silent stall** | Agent goes quiet, no prompt, spinner or nothing | Worker death (OOM family) or a stalled request |
| **Crash evidence** | "JS heap out of memory" / extension-host restart notification | Client worker OOM |
| **Refusal/error text** | Rate-limit or fetch-failure messaging | Quota / peak-load |
| **Quality cliff, same session** | Hover shows the SAME model, answers got worse | Context rot |
| **Weak model** | Hover shows a bottom-tier model | Down-routing |

To check recent crash/stall evidence on disk (Git Bash):

```bash
grep -l "JS heap out of memory\|terminated unexpectedly" \
  "$APPDATA/Code/logs"/*/window*/exthost/*.log 2>/dev/null | tail -3
```

## 2. Apply the matching fix

- **Benign pause** → click Continue. If it recurs constantly, raise
  `chat.agent.maxRequests` in settings. Log it: `observe --continue-prompt`.
- **Silent stall** → log it first: `observe --stall`. Then Stop, and type `continue`
  in the same chat. If it revives: worker died; finish the task, then start a fresh
  chat with smaller context. If it doesn't: Command Palette →
  "Developer: Restart Extension Host", fresh chat, re-anchor from the handoff.
- **Client worker OOM** → restart the extension host, fresh chat, re-anchor from
  handoff, and shrink per-turn context (see context-hygiene). RAM is not the fix —
  the heap cap is fixed per worker.
- **Quota / peak-load** → do not re-prompt into the wall. Wait 10–20 minutes or move
  heavy work off-peak. A fresh chat does NOT reset limits.
- **Context rot** → handoff → clear → pickup. Same ask, fresh window.
- **Down-routing** → restate the task at full altitude in a fresh chat: name files,
  framework, constraints; require a plan-of-action first (see auto-tactics). Never
  fragment the ask.

## 3. Log the outcome

If the tokometer field kit is installed, record what happened while it's fresh:

```bash
observe 2 "stalled mid-refactor, continue revived it"   # quality + note
```

The harvest picks up the hard evidence (crash strings, slow requests, downgrades)
automatically — the manual entry adds the human-observed outcome the logs can't see.
