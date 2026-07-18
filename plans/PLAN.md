# Plan — Copilot Field Kit for the Locked-Down Client Laptop

> Companion to [GOALS.md](GOALS.md). Status: **draft for review — nothing implemented yet.**
> Approval of this plan starts Phase 1. Each phase lands as its own feature-branch PR
> (dot-copilot and coder/tokometer separately); TDD applies to all collector/report code.

## Shape of the work

Two repos change; one repo is consulted; one zip comes out.

```
routometer (research, read-only) ──feeds design──┐
                                                 ▼
coder/tokometer ── new VS Code collectors ──┐
                                            ├──> bin/make-field-bundle.sh ──> field-kit.zip ──> laptop
dot-copilot ── new agents + instructions ───┘
```

## Phase 0 — Probe & pin (on the laptop, ~30 min, read-only)

**Answered so far** (owner's screenshots, 2026-07-17):

- msinfo32: Win 11 Enterprise 26100, 16 GB / ~3 GB free, WDAC kernel-Enforced +
  user-mode-Audit, VBS/Credential Guard/HVCI running, Pacific time.
- **P1 ANSWERED — and then superseded: VS Code is now 1.129.0** (1.109.5 → 1.113.0 →
  1.129.0 across 2026-07-17 as Company Portal updates landed). **Above the ≥ 1.119 OTel
  threshold** — the native OTel exporter should exist on this box. P3 (does it actually
  emit under the managed profile, with per-turn `model`?) is now live and is the
  deciding probe for which collector leads v1.
- **P2 ANSWERED: self-update is locked out; updates install only via the Company
  Portal** as builds get approved. Portal approvals move fast (three builds in one day).
  RUNBOOK keeps a weekly portal check for VS Code / extension updates.
- **P4 ANSWERED: user `settings.json` is writable** — `chat.agent.maxRequests: 50`
  applied and survived restart. Settings-based configuration is available; benign
  iteration-cap pauses will drop accordingly (the events collector counts them anyway).
- Python venvs work (`Activate.ps1` observed running); PowerShell executes local scripts.
- **No package manager** (no choco; pandoc absent) → all bundle code is stdlib-only
  Python + Git Bash; nothing is pip-installed on the target.

Remaining unknowns:

| # | Question | How |
|---|---|---|
| ~~P3~~ | *(optional cross-check only — P7 made the trace log primary)* **Tested 2026-07-17 with an absolute path: env vars set, full restart, long chat turn → no files. Reading: OTel export is policy/admin-gated on the managed profile** (consistent with the SPEC's original suspicion re: enterprise-managed OTel, shipped 2026-07-08). **Confirmed:** folder pre-existed, path pasted absolute, and Settings has **no `otel` entries at all** — the exporter is not exposed in this build/profile. (The `telemetry` setting found at "all" is VS Code product telemetry to MS/GitHub — unrelated, org-managed, not a local source.) Ledger unaffected — trace log carries more than OTel would have. OTel collector stays a no-op stub unless a future build exposes the feature. | closed 2026-07-17 (confirmed: not exposed) |
| ~~P4~~ | **ANSWERED: settings.json writable; `chat.agent.maxRequests: 50` applied.** | done 2026-07-17 |
| ~~P5~~ | **ANSWERED: Python 3.11.1.** Owner pins collector code to **3.11 compatibility** to match their target Databricks deployment — stdlib-only, no 3.12+ syntax. | done 2026-07-17 |
| ~~P6~~ | **ANSWERED (root level): `%APPDATA%\Code\logs\<YYYYMMDDTHHMMSS>\`**, one dir per session; 10 sessions spanning ~5 weeks (retention easily covers weekly harvest); read access confirmed; **empty session dirs occur** (windowless launches) — collector must treat them as normal. Remaining sliver: `dir /s` one real session dir to map the inner layout — which also locates the Copilot Chat output-channel file for P7. | done 2026-07-17 (root); inner layout rides along with P7 |
| ~~P7~~ | **ANSWERED (photographed snippets, 2026-07-17; full capture cannot leave the box): the Trace-level Copilot Chat channel is a COMPLETE ledger source — better than the OTel exporter.** Per request: `ccreq:<id>.copilotmd \| success \| <alias> -> <exact-deployment> \| <ms> \| [origin]`; full Anthropic `usage` incl. `cache_creation/cache_read` tokens; `amazon-bedrock-invocationMetrics` (tokens + `invocationLatency`); `copilot_usage.token_details` billing units (`total_nano_aiu`); `[ChatQuota] processQuotaHeaders` (percentRemaining, resetDate); `[Agent] rendering with budget=…` (context budget/turn); `[Power] CPU speed limit changed: ~26% (throttled)`; `[ToolResult] … written to disk: …workspaceStorage…chat-session-resources\…`; WebSocket conversation/turn ids. Claude models served via Bedrock; GPT via OpenAI-style SSE. Auto pool observed live: claude-haiku-4.5 (subagent/Explore), gpt-5.3-codex (panel/editAgent), gpt-4o-mini (copilot-utility-small). **Fixtures will be synthesized from the photographed grammar (sanitized); an on-box `--dry-run` smoke test validates against real logs.** | done 2026-07-17 |
| ~~P8~~ | **ANSWERED: Copilot Chat 0.42.3** (moved with the 1.113.0 update). OTel still gated by the VS Code engine (needs ≥ 1.119), but log format/verbosity may differ from 0.37.9 — the P7 capture must come from this version (it will, being newest). | done 2026-07-17 |

**Deliverables (in the bundle):** `probe/probe.py` (read-only checks, prints a PASS/FAIL
table) + `probe/PROBE-RESULTS.md` template to fill and carry back.
**Gate:** P7 defines the v1 ledger's actual fields (model identity and events are certain;
token counts only if the logs expose them — otherwise tokens wait for the OTel upgrade
path via P2). The plan proceeds either way — both paths are built.

## Phase 1 — tokometer grows VS Code collectors (coder repo)

New collectors alongside the existing CLI one (`collectors/copilot.py` stays untouched).
P7 settled the design: **the Trace-level Copilot Chat log is the primary, EXACT source**
(model per request, full token usage incl. cache, latency, quota, context budget):

- **`collectors/copilot_chat_log.py`** *(primary)* — parse the Copilot Chat output
  channel (Trace level) → ledger rows keyed by `ccreq` id: `ts, model_alias,
  model_deployment, input_tokens, output_tokens, cache_creation_tokens,
  cache_read_tokens, invocation_latency_ms, origin(panel/editAgent, tool/runSubagent…),
  nano_aiu` — all **exact**; plus event rows from the same stream: quota headers
  (`percentRemaining`, `resetDate`), context-budget rendering lines, `[Power] CPU speed
  limit` throttle changes, large-tool-result writes, request failures.
- **`collectors/vscode_events.py`** *(companion)* — scan the session logs
  (`logs\<ts>\…`: main/renderer/exthost) for the crash-side strings the chat channel
  won't carry: worker OOM, ext-host terminated/restarting, listener LEAK → event rows.
  Tolerates empty session dirs (confirmed to occur).
- **`collectors/copilot_vscode.py`** *(optional, structured cross-check)* — the OTel
  file-exporter JSONL parser as originally designed; built if P3 shows emission, kept as
  insurance against chat-log format drift. No-ops cleanly when the OTel path doesn't
  exist.
- **`collectors/copilot_observe.py` + `observe` entry point** — 5-second manual logging,
  now for what NO log carries: the **quality rating** (`observe <quality 1-5> [note]` —
  model comes from the ledger, not the hover) and the benign iteration-cap "continue?"
  vs silent-stall distinction as `--continue-prompt` / `--stall` flags.
- **Fixtures:** synthesized from the photographed line grammar (sanitized — no client
  paths/usernames); the harvest gains `--dry-run` (parse + print counts, write nothing)
  as the on-box validation against real logs, since real captures cannot leave the box.
- **Schema:** new `events` table (`ts, kind, mechanism, detail, session_id, source`) plus a
  `manual_obs` table. Migration in `schema.sql`.
- **Classifier (v1 heuristic, from the routometer SPEC):** a post-harvest pass labels each
  degradation window: OOM string + RSS/restart evidence → *client-OOM*; model drop right
  after a crash → *crash-triggered re-route*; HTTP/rate-limit text, no local evidence →
  *quota/peak-load*; model drop on fresh chat with no errors → *down-route*; same model,
  deep context, quality drop (manual obs) → *context rot*.
- **Laptop profile:** `tokometer.env` preset — only the three new collectors enabled, all
  push/sync OFF (zero egress), Windows paths via env vars.
- **Tests first:** pytest fixtures = sanitized OTel JSONL + log excerpts captured in
  Phase 0; every collector and the classifier gets red-green-refactor treatment.

## Phase 2 — Reports for the strategy question (coder repo)

- **Daily (on-laptop):** model mix by hour, tokens by hour, failure events overlaid,
  flagged degradation windows, benign-continue vs stall counts. Plain HTML rendered
  locally by the existing report machinery; opened in a browser, never served.
- **Weekly:** best/worst working hours, model-mix drift, mechanism distribution,
  and the routometer experiment questions as standing queries — does high-altitude
  phrasing pull stronger models (Exp B), does reset beat re-prompting (Exp D), do
  keywords matter (Exp E).
- Both reports run from one command (`daily.sh` / `weekly.sh` equivalents in Git Bash or
  `python -m` — no PowerShell, no scheduled tasks in v1; running them is part of the
  session ritual).

## Phase 3 — dot-copilot: close the workflow gap (this repo)

New instructions (always-apply unless noted):

- **`copilot-auto-tactics.instructions.md`** — the anti-doom-loop doctrine: signal
  complexity, never strip it; ground prompts in repo specifics (files, frameworks, test
  runners); require a written plan-of-action before tool calls; never fragment a failing
  ask — restate whole at full altitude; fresh chat per topic; hover-check the model when
  quality shifts and log it.
- **`context-hygiene.instructions.md`** — handoff → clear → pickup at ~half context
  (formalizes the Harvey-ball habit); shrink per-turn context to keep the prompt worker
  under its ~2 GB heap cap; new chat ≠ rate-limit reset (folklore correction).

New agents:

- **`recover.md`** — the stall/error playbook: identify which of the four mechanisms
  (benign continue-prompt? OOM string in logs? rate-limit text? deep context?) → the
  matching fix (Continue / restart extension host / fresh chat + re-anchor from handoff /
  wait for off-peak) → log the event via `observe`. Never respond to failure by
  simplifying the prompt.
- **`observe.md`** — wraps the manual observation entry so it's one agent invocation.
- **`report.md`** — runs the tokometer daily/weekly report and summarizes what changed.

Updates: `lets-go.md` gains a "check yesterday's report before planning today" step;
README, `docs/concept-mapping.md`, `docs/limitations.md` updated for the new pieces.

## Phase 4 — Packaging: one zip (this repo)

- **`bin/make-field-bundle.sh`** — assembles `field-kit-<date>.zip` from both repos:
  `copilot/` payload + a Windows-aware `install.md` (junction/copy instead of symlink),
  the tokometer laptop subset (collectors, lib, schema, reports, laptop profile),
  `probe/`, `BOOTSTRAP.md` (lift-kit-style card: unzip → run probe → enable OTel → install →
  first harvest), and `RUNBOOK.md` (daily/weekly ritual).
- **Identity scrub gate:** the script greps the staged bundle against a local, untracked
  scrublist (`~/.config/field-kit.scrublist` — client domain, hostname, engagement terms)
  and refuses to zip on any hit. The scrublist itself is never committed.
- **Self-check:** unzip into a temp dir and run the bundle's own `probe.py --self-test`
  to prove it's complete and self-contained before it ships.
- **Email-safe delivery encoding** (the transfer channel is email, not file transfer):
  after the scrub gate and self-check, the script:
  1. records `SHA-256(field-kit-<date>.zip)` in a `MANIFEST.txt`;
  2. base64-encodes the zip to a single `.txt`;
  3. splits it into ordered chunks **< 5 MB** each — `field-kit-<date>.b64.NN-of-MM.txt`
     (numbered so missing/duplicate parts are obvious), `MANIFEST.txt` listing every
     chunk with its own SHA-256.
  These `.txt` files are what gets emailed. **Reassembly on the target** is step 0 of
  `BOOTSTRAP.md` (which therefore travels in the *first* chunk's email body as plain
  text, since it can't be inside the zip it reconstructs), with two equivalent recipes:
  - Git Bash: `cat field-kit-*.b64.*.txt | base64 -d > field-kit.zip && sha256sum field-kit.zip`
  - cmd (no admin, built-in): `copy /b` the chunks in order into one file, then
    `certutil -decode` and `certutil -hashfile ... SHA256`
  followed by verify-against-manifest → unzip → run probe. Round-trip (encode → split →
  reassemble → hash-match) is part of the packaging self-check on this side.

## Phase 5 — Bring-up and the strategy loop (on the laptop)

1. Unzip, run probe, fill PROBE-RESULTS.
2. Enable OTel (env vars), install the config into the working project, first harvest,
   first daily report — same day.
3. **One week of passive collection** while working normally.
4. First weekly review: name the dominant mechanism and the good/bad hours from data;
   set the initial strategy (schedule heavy autonomous runs off-peak; reset cadence;
   prompting altitude). Carry PROBE-RESULTS + first weekly report back to update the
   routometer SPEC via its `/update-spec`.

## Risks and fallbacks

| Risk | Likelihood | Fallback |
|---|---|---|
| OTel exporter present (1.129.0) but doesn't emit under the managed profile, or omits `model` | Open — it's P3 | Log-tailer + `observe` lead v1 (the original plan); OTel collector stays dormant |
| OTel emits fully (P3 passes) | Hoped-for | OTel collector leads as originally designed; log-tailer demotes to failure-event duty |
| `settings.json` managed/locked | Possible | OTel via user env vars; `maxRequests` stays default; note in PROBE-RESULTS |
| User-mode WDAC flips Audit → Enforced | Low, out of our control | Everything is plain `.py`/`.sh` text — nothing to sign; worst case Python itself is the only dependency to re-justify |
| ~3 GB free RAM | Certain | All collection is batch-on-demand (harvest at session end); nothing resident; reports on demand |
| OTel JSONL shape differs from docs | Possible | Phase 0 captures real output first; fixtures come from reality, not docs |
| Client identity leaks into bundle | Must-not | Scrub gate in Phase 4; screenshot identifiers never committed anywhere |

## Review gates

1. **Now:** you approve/amend GOALS.md + this plan.
2. Phase 1+2 land as PR(s) on coder/tokometer (feature branch off its default).
3. Phase 3+4 land as PR(s) on dot-copilot (feature branch — main stays the stable base).
4. Phase 0/5 artifacts travel in the bundle; results come back as edits to routometer's
   SPEC/DECISIONS and, if warranted, plan amendments here.
