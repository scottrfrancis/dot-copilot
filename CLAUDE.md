# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository contains portable GitHub Copilot configuration files — the Copilot equivalent of `~/.claude/`. It serves as a "base class" that gets symlinked into target projects' `.github/` directories.

## Repository Structure

- `copilot/` — The deliverable: portable Copilot config files
  - `copilot-instructions.md` — Global instructions (symlinked to `.github/copilot-instructions.md`)
  - `instructions/` — Path-scoped guidelines (symlinked to `.github/instructions/`)
  - `prompts/` — Runnable `/name` commands (symlinked to `.github/prompts/`)
  - `hooks/` — Hook definitions and scripts (symlinked to `.github/hooks/`)
- `install.sh` — Symlink installer for target projects
- `docs/` — Mapping documentation and known limitations

## Key Concepts

Each file in `copilot/` has a 1:1 mapping to a Claude Code equivalent:

| This Repo | Claude Code Equivalent |
|---|---|
| `copilot/copilot-instructions.md` | `~/.claude/CLAUDE.md` |
| `copilot/instructions/*.instructions.md` | `~/.claude/guidelines/*.md` |
| `copilot/prompts/*.prompt.md` | `~/.claude/commands/*.md` |
| `copilot/hooks/` | `~/.claude/hooks/` + `settings.json` |

## Development Guidelines

This repository is **self-contained at runtime**. The installed configuration **does not require Claude Code, a local `dot-claude` checkout, or `~/.claude/` to be present**. `copilot/` holds the complete, authoritative content; nothing is fetched from or synced out of `~/.claude/`. The `~/.claude/` names in the mapping table above are a *conceptual* Claude-Code equivalence for readers familiar with that setup, not a dependency.

**Doctrine is the exception.** Blocks delimited by `<!-- <block>: begin -->` … `<!-- <block>: end -->` are authored in `dot-claude` and propagated here by `dot-claude/bin/doctrine.sh`. Edit them there, not here — a local edit is overwritten on the next sync. Everything else in this repo is authored locally, and nothing about this affects **runtime**: the installed artifacts still require no `~/.claude/` present.


- Follow `copilot/instructions/conventional-commits.instructions.md` for commit messages
- Follow `copilot/instructions/shell-scripts.instructions.md` for any bash scripts
- Follow `copilot/instructions/readme-documentation.instructions.md` for documentation
- `copilot/` is the source of truth for this repo's own content. Edit it here directly. The one exception is marker-delimited doctrine blocks, which come from `dot-claude` (see **Doctrine** above).
- Instructions files use YAML frontmatter with `applyTo` glob patterns
- Agent files use YAML frontmatter with `name`, `description`, and `tools` arrays

## Branch Policy

Work on feature branches. Main is the stable configuration that gets symlinked into other projects.
<!-- central-ops-knowledge: begin -->
## Central Ops Knowledge (shared doctrine — all my AI tools)

I maintain ONE central, authoritative **ops-knowledge state** for my homelab/home: **dynamic**
(live, current, queryable by every human and AI on the LAN) and **archival** (durable,
portable, hand-off-able to anyone taking over anything). It lives in the **`okf-knowledge` bundle**
(vault-authoritative `vault:/volume1/gitrepos/okf-knowledge.git`; clones: hasami `~/okf-knowledge`,
Studio `/Volumes/workspace/okf-knowledge`; `wiki/` alongside — infra content promoted from the older
`HomeAssistant/home-ops/` on 2026-07-01), is surfaced
live to agents via the read-only **`kb-mcp` filesystem MCP** (`mini.local:8092`, tools
`search`/`read_file`/`list_dir`; registered in **Hazel**/OpenWebUI and reusable by any MCP
client) and to humans via **`kb-static`** browse (`mini.local:8090`), and kept current by the
`tools/*-scan.sh` self-tracking probes. (Ingesting the bundle into the **Librarian RAG** is on
indefinite hold — the MCP reads markdown live, no re-index.) Full doctrine:
`~/.claude/guidelines/central-ops-knowledge.md`.

Operating rules for every agent (Claude, OpenCode, Codex, Cursor, Droid, Copilot…):
1. **Consult before acting on infrastructure** — before stopping/changing a service, host, or
   config, check the knowledge base for "what is this and *why*." Stale assumptions cause outages.
   On the LAN, query it live via the `kb-mcp` MCP (or read the `okf-knowledge` bundle markdown
   directly — on hasami: `~/okf-knowledge/`, e.g. `infra/`); off-LAN, read the repo checkout.
2. **Write back** — when you learn or change something about the ops state, record or flag it so
   it stays current. Session-only knowledge is lost.
3. **OKF form** — plain markdown + YAML, **no secrets** (pointers only), conformant for any tool.
4. **Local-first / WAN-tolerant** — prefer local LLM/files/Kiwix; must work with the internet down.
5. **Respect boundaries** — household surfaces LAN-only; don't touch non-Scott tailnet hosts.
<!-- central-ops-knowledge: end -->

<!-- design-patterns: begin -->
## Design-pattern discipline

Before designing a non-trivial component, or coining a new mechanism/abstraction:

- **Consult the pattern library first** — the `dot-patterns` corpus (GoF index with house
  stances, personal patterns, vetted mixins). On the LAN: the **patterns MCP** at `mini.local:8093` (search/read_file), or read the
  vault checkout `/Volumes/workspace/dot-patterns` directly. Off-LAN: the installed skills
  / your local `dot-patterns` checkout.
- **Name the pattern you apply** ("this is Strategy" / "the data-diode black/white/gray") in
  your plan and PR so reviewers share the vocabulary.
- **Don't reinvent what the library names.** Reuse an applicable pattern; if you deviate, say why.
- **If you coin something reusable, flag it for capture** rather than letting it evaporate.
- Prefer the GoF house stances (composition over inheritance; Strategy over if-ladders;
  avoid Singleton/Visitor) unless there's a stated reason.
<!-- design-patterns: end -->
