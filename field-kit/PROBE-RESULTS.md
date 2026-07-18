# Probe Results — target laptop

Phase-0 findings, verified on the box. Update this file when anything changes
(especially after Company Portal pushes a VS Code update).

| # | Question | Answer | Date |
|---|---|---|---|
| P1 | VS Code version | **1.129.0** (1.109.5 → 1.113.0 → 1.129.0 in one day) | 2026-07-17 |
| P2 | Update path | **Company Portal approvals only**; self-update locked | 2026-07-17 |
| P3 | OTel file exporter | **Not exposed** — env vars produce nothing; no otel settings | 2026-07-17 |
| P4 | settings.json writable | **Yes** — `chat.agent.maxRequests: 50` applied | 2026-07-17 |
| P5 | Python | **3.11.1** (kit pinned 3.11, Databricks parity); venvs work | 2026-07-17 |
| P6 | VS Code logs | `%APPDATA%\Code\logs\<YYYYMMDDTHHMMSS>\`; ~5-week retention; empty session dirs occur | 2026-07-17 |
| P7 | Trace-level chat log | **Complete ledger source**: ccreq lines (model deployment + latency), full SSE usage (tokens incl. cache), quota headers, context budgets, power-throttle events | 2026-07-17 |
| P8 | Copilot Chat extension | **0.42.3** | 2026-07-17 |

Environment: Win 11 Enterprise 26100 · 16 GB (~3 GB free) · WDAC kernel-Enforced /
user-mode-Audit · VBS/Credential Guard/HVCI · no admin · CPU power-throttled to ~26%
at times (logged by the harness) · Pacific time.

Standing items:
- **Weekly**: check Company Portal for VS Code / extension approvals; after any
  update, re-verify the chat log level is still **Trace** and rerun
  `python probe.py`.
- OTel stays dormant unless a future build exposes it (collector no-ops until then).
