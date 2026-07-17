---
name: "report"
description: "Run the tokometer Copilot daily/weekly report and summarize what changed"
tools: ["executeCommand", "readFile"]
---

# Report — Copilot usage & health

Generate the strategy report from the local tokometer ledger and read it back with
judgment. Nothing here leaves the machine.

## Run

```bash
python3 ~/.tokometer/report_copilot.py            # today
python3 ~/.tokometer/report_copilot.py --weekly   # last 7 days
```

(Reports are also written to `~/.tokometer/reports/`.)

## Summarize — lead with what changed

Read the output and give the user five lines, most-decision-relevant first:

1. **Model mix shift** — which model dominated, and did the strong-model share move
   vs. the prior report?
2. **Failure picture** — stalls, OOMs, downgrades: count and the classifier's
   mechanism labels. Call out any `client-oom-reroute` (self-inflicted downgrades).
3. **Time-of-day** — which hours got strong models and clean runs; which got the
   cheap tier. This drives scheduling.
4. **Quality vs. the numbers** — do the manual ratings agree with the hard data?
5. **One action** — the single highest-leverage adjustment (e.g. "move the big
   refactors before 9am", "context is rotting by 2pm — handoff at half full",
   "yesterday's downgrades were all crash-triggered: shrink per-turn context").

## Weekly extras (Mondays or on request)

Run `--weekly` and additionally answer the standing experiment questions:
does high-altitude phrasing pull stronger models (Exp B)? does reset beat
re-prompting (Exp D)? Frame each answer as "the data says / the data can't say yet".

## Empty report?

If it says no activity was harvested, the chat log level probably reset from Trace
(a VS Code update does this). Fix: Command Palette → "Developer: Set Log Level" →
GitHub Copilot Chat → Trace, then confirm tomorrow's report has data.
