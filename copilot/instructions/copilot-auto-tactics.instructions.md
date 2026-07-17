---
description: "Auto-router tactics for model-locked Copilot: signal complexity instead of stripping it, plan before tools, never fragment a failing ask"
applyTo: "**"
---

# Copilot Auto-Router Tactics

On machines where Copilot's model selection is locked to **Auto**, the router reads the
prompt text and routes to a model *before anything runs*. Prompt wording is therefore a
routing input, not just an instruction. These rules keep the router pointed at strong
models and break the failure spiral. (Grounded in the routometer research: routers
score prompt text alone; keyword-level edits flip routing ~98% of the time.)

## Signal complexity — never strip it

- **Ground every non-trivial ask in repo specifics**: name the files, the framework, the
  test runner, the constraints, the invariants. GitHub's own guidance: this makes Auto
  "smarter in its routing."
- **State the genuine difficulty** ("cross-module refactor touching the retry semantics")
  rather than minimizing ("small fix"). A prompt that *looks* easy gets a model that
  handles easy.
- Magic incantations (`ultrathink`, "think harder") are **not** router signals for
  Copilot — honest difficulty signaling is. Don't chant; specify.

## Plan of action before tool calls

For any agent-mode task beyond a one-liner: **require a short written plan first**
("Before editing, list the steps and files you'll touch, then wait for my go").
This raises the prompt's assessed complexity, keeps long runs on rails, and is the
community-converged fix for trial-and-error loops.

## When output degrades, raise altitude — never fragment

The panic reaction — shorter prompts, simpler words, splitting one task into five timid
asks — hands the router a smaller-looking problem, and it answers with a smaller model.
That is the doom loop, and it is self-inflicted. Instead:

1. **Restate the whole task** at full altitude with complete context, in a fresh chat.
2. **Check which model answered** (hover the response) before blaming yourself — a tier
   drop is a routing event, not a prompting failure.
3. If degradation persists at the same model, it's context rot or capacity — see the
   context-hygiene instruction and the recover agent — not a wording problem.

## Session mechanics that steer routing

- **One topic per chat.** New topic → new chat. Auto re-routes at cache boundaries;
  a fresh chat is a clean routing decision with clean context.
- **A fresh chat does NOT reset rate limits** (account-level) — reset for context,
  not for quota.
- **Schedule heavy autonomous runs off-peak.** Field data: identical plan-driven runs
  succeed overnight and fail mid-afternoon. Capacity beats prompting; work with the
  clock, not against it.

## Instruction-file hygiene (this repo's own port)

- Every instructions file MUST carry an `applyTo` frontmatter glob — Copilot **silently
  skips** files without one (`AutomaticInstructionsCollector: No applyTo pattern …
  Skipping`).
- If referenced instructions aren't being applied, check the
  `github.copilot.chat.includeReferencedInstructions`-family settings — observed
  disabled on managed profiles.
