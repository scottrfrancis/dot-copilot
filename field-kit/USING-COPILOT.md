# Using Copilot with a Claude Bias — operator guide for this kit

Written for one operator: fluent in Claude Code, ritual-driven, now working on a
locked-down box where **Copilot in VS Code (Auto-only) is the entire toolchain**.
This maps *your actual habits* — observed across ~180 of your session logs — to
their Copilot equivalents in this kit, and is honest about what doesn't port.

Keep open next to `RUNBOOK.md`. The mechanical reference is `docs/concept-mapping.md`
in the dot-copilot repo; this doc is about *operating*, not configuration.

## The one-paragraph mental shift

Claude Code is a CLI agent you steer with slash commands, global config, and hooks
that fire automatically. Copilot is a chat sidebar with per-repo config and **no
global anything**: agents live in a dropdown (not `/slash`), instructions auto-apply
by glob, and nothing runs at session start unless *you* invoke it. Your rituals all
still work — but every one of them becomes a deliberate first move instead of an
ambient default. The discipline you already have is the port; the kit supplies the
tooling.

## Your session lifecycle, ported

| Your Claude habit | On this box | What changed |
|---|---|---|
| `/lets-go` (or `/pickup`) opens every session | Select the **lets-go** agent in the Copilot dropdown, first thing | No SessionStart hook fires for you — the git-sync + handoff-load only happens if you invoke it. It also surfaces yesterday's tokometer report. |
| `/session-logger` closes substantive sessions | **session-logger** agent → writes to `session-logs/` | Same format, same YAML frontmatter (`tool: copilot`), cross-tool readable — a handoff written here picks up in Claude Code at home. |
| `/handoff` + next-day `/pickup` | **handoff** agent; next session, lets-go loads it | Identical file format. Your carry-forward-blockers habit works unchanged — but only if the handoff actually gets written, so keep the closing ritual sacred. |
| `b start` / `b stop` time tracking | **Not on this box** — `b` isn't installed | Your session-logger timestamps are the fallback time record. |
| `/autocommit` | **autocommit** agent | Same Conventional Commits behavior. PRs: same draft-and-you-merge gate you already keep. |

## What does NOT port — and what replaces it

- **Parallel subagent fan-out.** Your biggest capability loss. There is no Task/agent
  spawning; one chat, one thread of work. Replace breadth-in-parallel with
  breadth-in-sequence: separate chats per research thread (fresh chat per topic is
  also a routing win), and schedule long autonomous sweeps **off-peak** where the
  capacity data says they succeed.
- **Plan mode.** No enforced read-only exploration. Approximate it verbally — "plan
  only, list the files you'd touch, wait for my go" — which doubles as a
  complexity signal to the Auto router (see below). The approval gate is you.
- **Global `~/.claude` config.** Nothing follows you between repos automatically.
  This kit's `copilot/` payload must be copied into each project's `.github/`
  (BOOTSTRAP step 4). One copy per project, updates by re-copy.
- **MEMORY.md / auto-memory.** Nothing is auto-loaded across sessions except
  `.github/copilot-instructions.md`. Your reusable-insights habit ports as: put
  durable, always-true lessons into the project's `copilot-instructions.md`;
  put session-scoped state into the handoff. Nothing else survives.
- **Hooks as a safety net.** Claude's Stop-hook nagged you to log sessions. Here
  the end-of-session ritual (session-logger → handoff → harvest → report, per
  RUNBOOK) runs on your discipline alone. Put it somewhere you'll see it.

## Working WITH the Auto router (your model picker is gone)

At home you choose the model and effort; here the router reads your prompt and
chooses for you. Two of your existing habits are, unmodified, the optimal play:

- **Your TDD/red-first doctrine is a router win.** "Write the failing test for X
  covering these edge cases, then implement to green, then run the full suite"
  is exactly the file-naming, constraint-stating, plan-shaped prompt that scores
  as complex and pulls the strong tier. Keep working the way you work.
- **Your skeptical re-verification pass matters MORE here.** At home you audit
  agent output on principle; here the answer may have come from the cheap tier
  without warning. Hover-check the model on any answer you're about to trust,
  and downgrade your trust before you downgrade your prompt.

What NOT to do when output degrades: your instinct at home is `/compact` or a
sharper reprompt. Here, **never simplify or fragment the ask** — that reads as
an easier task and routes you further down. The full doctrine is in the
`copilot-auto-tactics` and `context-hygiene` instructions (they auto-apply);
the failure-triage table is the **recover** agent.

## The habits this box adds (not in your Claude repertoire)

1. **Hover the response** when quality shifts — model identity is data, and the
   harness logs it; your job is just to notice.
2. **`observe`** the moment something happens: `observe --stall`,
   `observe --continue-prompt`, `observe 4 "note"` — ten seconds, from Git Bash.
   These are the only signals the logs can't capture.
3. **Harvest + report at session end** (RUNBOOK): the data answers "was it me,
   the router, quota, or the laptop" so you stop guessing.
4. **Half-full context = handoff → clear → pickup.** You already run this cycle
   by instinct; here it's also OOM prevention, so run it *earlier* than feels
  necessary.

## Known frictions, translated from your Claude logs

- Your recurring "sandbox blocks git-over-SSH" annoyance doesn't exist here —
  there's no remote at all. Everything is local; the bundle IS the transfer.
- Your auto-mode-classifier frustration (repeated approval round-trips) maps to
  Copilot's tool-approval prompts in agent mode. Same mitigation you wanted at
  home: batch intent up front — state in the prompt what the agent may run
  ("you may run the test suite and edit files under src/") to reduce mid-run
  stops, and raise `chat.agent.maxRequests` if the benign continue-prompt nags.
- Every tool gotcha you'd normally save as a Reusable Insight: the durable ones
  go in the project's `copilot-instructions.md`, the box-specific ones in
  `PROBE-RESULTS.md` — both travel back to home base at re-bundle time.

## Ten-second card

```
open   : lets-go agent            close  : session-logger → handoff → harvest.sh → report
stall  : recover agent            felt it: observe 1-5 / --stall / --continue-prompt
degrade: fresh chat, FULL altitude — never fragment      hover: check the model
weekly : report --weekly Monday   after VS Code update: log level back to Trace
```
