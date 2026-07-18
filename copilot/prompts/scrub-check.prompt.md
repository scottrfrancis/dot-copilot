---
description: "Advisory review of about-to-push changes for proper nouns and identifiers (client/employer/person/host) that may need scrubbing"
mode: agent
---

# /scrub-check — identifier review before you push

**Arguments (optional):** a git range (`/scrub-check origin/main..HEAD`) or `--staged`.
Default: the commits about to be pushed (`origin/<default>..HEAD`).

A context-aware complement to `bin/entity-advisory.py` (the deterministic regex
scanner) and the scrublist (the exact-match blocker). Regex catches CamelCase brands,
domains, and hostnames; **you catch what it can't** — a plain-worded project name, a
person, an internal codename, a client reference buried in prose. This is **advisory**:
report and recommend, never edit or block.

## Steps

1. **Get the change.** `git diff <range>` for the range (default
   `git diff origin/HEAD..HEAD`), or `git diff --cached` for `--staged`. Read the
   **added** lines (and new files) — that's what will become public.

2. **Load what's already known** (so you only surface NEW things):
   - Scrublist patterns: `~/.config/field-kit.scrublist` (already-blocked identifiers).
   - Allowlist: `~/.config/field-kit.allowlist` (known-safe names).
   - Treat common tech vocabulary (GitHub, Python, Docker, the user's own public
     project names — dot-copilot, tokometer, routometer, field-kit — etc.) as safe.

3. **Scan for identifiers** in the added content. Look beyond CamelCase — flag:
   - **Organizations / clients / employers** — company names, consultancies, brands.
   - **Projects / products / codenames** — including plain-English multi-word names
     the regex would miss (e.g. "the Vantage rollout", "Launchpad Labs").
   - **People** — real first/last names, usernames, handles, email addresses.
   - **Machines / infra** — hostnames, AD domains (`DOMAIN\user`), IPs, internal URLs,
     `C:\Users\<name>` paths, S3 buckets, tenant IDs.
   - **Domain jargon** — internal system acronyms, approval-process names, product
     lines that fingerprint an engagement's problem space even without a company name.

4. **Triage each finding** into one of three, and say why:
   - **ALREADY COVERED** — matches a scrublist pattern (good; no action).
   - **SCRUB** — identifying and not yet blocked → recommend the exact line to add to
     `~/.config/field-kit.scrublist` (a specific regex; avoid over-broad bare words).
   - **SAFE** — a false positive → recommend adding to
     `~/.config/field-kit.allowlist` to silence it next time.

5. **Report** as a short table: `finding | type | verdict | suggested list entry`.
   Lead with the SCRUB recommendations. If nothing new is identifying, say so plainly:
   "No new identifiers to scrub — N common/known names seen, all safe."

## Rules

- **Advisory only.** Do not edit files, rewrite history, or block anything. The human
  decides and edits the lists.
- **Precision over recall on SAFE, recall over precision on SCRUB** — when unsure
  whether something identifies a client, recommend SCRUB and let the human downgrade.
- Never paste a suggested scrublist entry that is a bare common word (it will
  false-positive); qualify it (`\bEY\b`, `Catalyst[ -]?RCM`).
- Remember the lists live only at `~/.config/…`; never write real identifiers into a
  committed file.
