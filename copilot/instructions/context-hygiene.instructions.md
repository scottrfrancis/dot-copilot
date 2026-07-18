---
description: "Context-window hygiene for long Copilot sessions: handoff-clear-pickup at half full, small per-turn context, OOM-aware habits"
applyTo: "**"
---

# Context Hygiene

Two independent failure modes punish bloated context in Copilot agent sessions:
**context rot** (the model degrades as the window fills with history and tool noise)
and the **prompt-worker heap cap** (each turn re-serializes the whole conversation into
a worker with a fixed ~2 GB JS heap; when a render exceeds it, the worker dies — the
session hangs mid-task and can re-route to a weaker model on revival). Both are managed
with the same habits.

## The half-full rule

Watch the context-fill indicator. **At roughly half full, run the handoff → clear →
pickup cycle**: generate a handoff summary (the `handoff` agent), start a fresh chat,
re-anchor from the handoff. Don't ride the window to the top — the worker OOM strikes
*mid-*session, before the indicator looks alarming, because peak render heap runs ahead
of visible fill.

## Keep per-turn payloads small

- Attach the files the task needs — not the folder, not "the workspace".
- Prefer naming files and symbols over pasting their contents; the agent can read them.
- Big tool outputs (logs, query results) accumulate in every later render. After a
  noisy investigation, summarize the finding into the chat and start clean.

## Session-shape rules

- **One topic per chat**; new topic → new chat (also a routing win — see the
  auto-tactics instruction).
- Long autonomous runs: plan-driven, with the plan re-stated in the handoff so a
  restart re-anchors instantly.
- After any hang/crash/restart, assume the context was torn down: **re-anchor from the
  handoff file, not from memory** of what the session knew.

## What a fresh chat does and doesn't fix

| Symptom | Fresh chat helps? |
|---|---|
| Same model, dumber answers late in session | **Yes** — that's context rot |
| Hang mid-task, "continue" revives it | **Yes** (worker died; smaller context prevents recurrence) |
| Rate-limit / quota messaging | **No** — limits are account-level; wait or go off-peak |
| Weak model on hover from the first turn | **No** — that's routing; raise prompt altitude |
