# Goals — Copilot Field Kit for the Locked-Down Client Laptop

> Companion to [PLAN.md](PLAN.md). Status: **draft for review — nothing implemented yet.**

## Mission

A highly effective GitHub Copilot setup for the client laptop: instrumented so daily and
weekly data drives the usage/prompting strategy, and equipped with a command + instruction
set that mirrors the Claude Code workflow as closely as Copilot allows.

## The target environment (what we know)

- Dell Latitude 5450, Windows 11 Enterprise build 26100, 16 GB installed / **~3 GB
  physical free** (VBS, Credential Guard, HVCI, Secure Launch all running; 20 GB pagefile).
  App Control for Business: **kernel policy Enforced, user-mode policy Audit** — unsigned
  user-mode scripts run (audit-logged), which is why Python/Git Bash work. No admin.
  Pacific time. (Pinned from the owner's msinfo32 screenshot, 2026-07-17. Machine/domain
  identifiers from that screenshot stay out of all committed and bundled files.)
- **Copilot in VS Code only — Auto model selection only.** No model picker, no CLI.
- **Available runtimes (confirmed by owner):** Python **3.11.1** (venvs work; all kit
  code pinned to 3.11-compatible stdlib-only — matches the owner's target Databricks
  deployment), VS Code **1.129.0**
  (three Company Portal updates on 2026-07-17; self-update locked; **now above the
  ≥ 1.119 OTel threshold** — emission test P3 pending) + Copilot Chat **0.42.3**,
  PowerShell/cmd (local scripts execute), Git Bash; user `settings.json` writable
  (`chat.agent.maxRequests: 50` set). **No package manager** — bundle code is
  stdlib-only Python.
- **Transfer channel: email only.** No git remote from the laptop. The kit ships as one
  self-contained zip, base64-encoded and split into `.txt` chunks < 5 MB that are emailed
  to the target and reassembled there (Git Bash or built-in `certutil` — no admin, no
  extra tools). Updates are re-encoded re-zips.
- Observed failure modes (the four mechanisms, per `routometer` research): task-complexity
  down-routing, context/session rot, quota/peak-load fallback, client worker OOM
  ("JS heap out of memory" → stall → "continue" revives). Experience is uneven;
  overnight-succeeds / daytime-fails is the strongest field signal. **Fifth candidate
  found in the P7 trace (2026-07-17): the laptop is power-throttled — `[Power] CPU speed
  limit changed: ~26%` recurs in the Copilot log — so client-side slowness has a
  measurable, logged cause independent of the four; the ledger records these events.**
- Auto pool observed live in the P7 trace: claude-haiku-4.5 (via Bedrock) on
  subagent/Explore work, gpt-5.3-codex on panel/editAgent, gpt-4o-mini as the utility
  alias. Instructions finding: files without `applyTo` frontmatter are **silently
  skipped** (`AutomaticInstructionsCollector`), and `includeReferencedInstructions` is
  disabled — both feed the G2 instruction set.

## Goals and success criteria

### G1 — Instrumentation: ledger + failure events

Capture per-turn **model + token usage** AND **failure events**, locally, for daily/weekly
analysis.

- Every Copilot turn lands in the tokometer ledger. **Primary source (settled by probe
  P7, 2026-07-17): the Trace-level Copilot Chat output channel**, which carries per
  request the exact model deployment, full token usage including cache creation/read,
  invocation latency, billing units, quota headers, and per-turn context budget — more
  than the OTel exporter promised. The OTel collector remains an optional structured
  cross-check (P3). Requirement: log level stays at Trace; the RUNBOOK verifies it
  persists across restarts.
- Failure events are captured and **labeled with a mechanism**: down-route, context rot,
  quota/peak-load, worker OOM. Benign iteration-cap "continue?" prompts are counted
  separately from silent stalls.
- **Daily report** (on-laptop): model mix by hour, tokens by hour, stall/OOM/downgrade
  counts, flagged degradation windows.
- **Weekly report**: trends across days — best/worst hours, model-mix drift, failure-type
  distribution — sufficient to answer: *when should heavy work run, when should I reset,
  and does prompt altitude measurably steer Auto?* (Experiments A–E from the routometer
  protocol become queries over this data instead of hand-logging.)
- Success = after one week of passive collection, the reports name the top degradation
  mechanism and the best working hours with data, not vibes.

### G2 — Command & instruction parity with the Claude workflow

dot-copilot already ports the session lifecycle (lets-go / session-logger / handoff /
mine-sessions, hooks, 18 instruction files). Close the remaining gap with
**Copilot-Auto-specific** additions:

- **Auto-router tactics instruction** — signal complexity instead of stripping it; ground
  prompts in repo specifics; require a written plan-of-action before tool calls; never
  fragment a failing ask (the doom-loop trigger); fresh chat per topic.
- **Context-hygiene instruction** — the handoff → clear → pickup cycle at ~half context
  (Harvey ball), formalizing what the owner already does by instinct.
- **Recovery agent** — when Copilot stalls or errors: diagnose which mechanism (check for
  the OOM string, the benign continue-prompt, rate-limit messaging), then the right fix —
  restart extension host / fresh chat / wait for off-peak — instead of prompt-fiddling.
- **Observation agent** — one-keystroke logging of hover-model + quality rating into the
  ledger's manual table, for turns OTel can't see.
- Success = the laptop workflow feels like the Claude workflow: same session rhythm, same
  memory discipline, plus reflexes tuned to Auto's failure modes.

### G3 — Transferability

- **One zip** carries everything: dot-copilot install, the tokometer subset that runs on
  the laptop, the probe, and a bootstrap card (lift-kit style — unzip, open VS Code, go).
- Self-contained: no network fetches, no installs beyond what's confirmed present, no
  unsigned binaries. Python + Git Bash are the only runtimes assumed.
- Re-zip is the update path: `make-field-bundle.sh` reproduces the archive from both repos
  at any time.

## Non-goals / hard rails

- **Nothing collected ever leaves the laptop.** Reports render and are read on-box.
  `captureContent` stays OFF.
- **No client identity** in any committed or bundled file — technical posture only.
- **No auto-mitigation, no live dashboard** in v1 (deferred, per routometer SPEC).
- No changes to Copilot/VS Code behavior beyond documented, user-level settings.
- PowerShell is available but **not** the collection mechanism (WDAC + signing risk);
  Python and Git Bash do the work.

## Division of labor across repos

| Repo | Role |
|---|---|
| `dot-copilot` (this repo) | Commands, instructions, hooks, bundle packaging — the portable kit |
| `coder` (tokometer) | Grows a VS Code/OTel collector + failure-event collector + laptop profile |
| `routometer` | Research/design home (SPEC, mechanism model, experiment protocol) — referenced, not shipped |
