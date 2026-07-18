# Field Kit RUNBOOK — the daily/weekly ritual

Everything is local. Nothing leaves the machine. The whole ritual is ~2 minutes a day.

## During the day (reflexes, not chores)

- **Something felt off?** Use the **recover** agent (or eyeball its table): benign
  "continue?" ≠ silent stall ≠ crash ≠ weak model. Apply the matching fix — never
  respond to failure by simplifying the prompt.
- **Log what only you can see** (10 seconds, Git Bash):
  - `observe 4 "note"` — quality rating after a meaningful task
  - `observe --stall` / `observe --continue-prompt` — the moment it happens
- **Half-full context?** handoff → clear → pickup. Don't ride the window.

## End of session (2 minutes)

```bash
bash ~/.tokometer/harvest.sh          # parse logs -> ledger (idempotent)
python ~/.tokometer/report_copilot.py # today's model mix, failures, hours
```

Glance at the report: which models, which hours, any downgrades and their labels.

## Monday (10 minutes)

```bash
python ~/.tokometer/report_copilot.py --weekly
```

Ask the report the standing questions, and adjust the week's strategy:
1. Which hours got strong models and clean runs? → schedule heavy work there.
2. Downgrade mechanisms: mostly `client-oom-reroute`? → shrink per-turn context.
   Mostly `quota`? → move work off-peak. Mostly `downroute`? → raise prompt altitude.
3. Do your quality ratings agree with the hard numbers?

Also on Mondays: check **Company Portal** for VS Code / extension updates.

## After ANY VS Code or Copilot Chat update

1. Re-verify the chat log level is still **Trace** (updates can reset it):
   `Ctrl+Shift+P` → Developer: Set Log Level → GitHub Copilot Chat → Trace.
2. `python ~/field-kit/probe.py` — confirm everything still passes.
3. `python ~/.tokometer/collectors/copilot_chat_log.py --dry-run` — confirm the log
   format still parses (nonzero requests). If it parses zero from fresh logs, the
   format drifted: note the VS Code/extension version in PROBE-RESULTS.md and send
   a few photographed log lines back to the home session for a parser update.
4. If a build ever exposes OTel settings (search "otel" in Settings), enable the file
   exporter — the dormant collector picks it up automatically as a cross-check.

## Updating the kit

Updates arrive the same way they came: a new `field-kit-<date>.ps1.txt` by email →
rename to `.ps1` and run it (re-extracts to `%USERPROFILE%\field-kit`) → re-run
`install-laptop.sh` (it overwrites kit files; your ledger and config survive).
