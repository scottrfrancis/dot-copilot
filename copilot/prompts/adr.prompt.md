---
description: "Create an Architecture Decision Record in the canonical format — from a described decision or extracted from a session log"
mode: agent
---

# /adr — write an Architecture Decision Record

**Arguments:** describe the decision after `/adr` (e.g. `/adr use Postgres instead of
DynamoDB for the ledger`). With no argument, extract ADR-worthy decisions from the most
recent session log.

Follow the canonical ADR format defined in the `adr` instruction
(`.github/instructions/adr.instructions.md`) — location, numbering, status lifecycle,
and template. Do not invent a different shape.

## Steps

1. **Find the decisions directory.** Prefer `docs/decisions/`; if the project already
   uses `docs/adr/`, write there instead (don't split). Create `docs/decisions/` if
   neither exists.

2. **Get the decision.**
   - If arguments were given, use them as the decision to record.
   - If not, find the most recent session log with ADR markers:
     `grep -l "ADR-worthy\|ADR candidate" session-logs/*.md .claude/session-logs/*.md 2>/dev/null | tail -1`
     and extract each significant architectural decision from it.

3. **Assign the next number.** `grep -rho 'ADR-[0-9]\{4\}' docs 2>/dev/null | sort -u | tail -1`
   → next zero-padded 4-digit number (start at `0001`).

4. **Draft** each ADR from the canonical template: Status (`Proposed` unless I say
   `Accepted`), Date (ask me for today's date — you can't read the clock reliably),
   Context, Decision, Consequences (positive **and** negative — both required),
   Alternatives considered. If the decision traces to an `FR-###` requirement or an
   assumption (`A##`), fill **Related requirements** so `trace-check` sees the link.

5. **Write** to `docs/decisions/ADR-NNNN-kebab-slug.md`. Show me the diff before saving
   (Manual mode). One decision per file — if the log yielded several, create several.

6. **Report** the ADR number(s), path(s), and status. If any decision superseded an
   existing ADR, remind me to set that older ADR's Status to `Superseded by ADR-NNNN`
   (never edit its body).

## Guardrails

- Never overwrite an existing ADR number. Never renumber.
- Never edit an `Accepted` ADR's body — supersede it with a new one.
- Keep it a decision record, not a design doc; link out for detail.
