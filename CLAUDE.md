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

This repository is standalone and **does not require Claude Code or `~/.claude/` to be installed**. All dev-workflow rules below have local copies in `copilot/instructions/`. The `~/.claude/` paths are listed as optional fallbacks when Claude Code is available on the same machine.

- Follow `copilot/instructions/conventional-commits.instructions.md` (fallback: `~/.claude/guidelines/conventional-commits.md`) for commit messages
- Follow `copilot/instructions/shell-scripts.instructions.md` (fallback: `~/.claude/guidelines/shell-scripts.md`) for any bash scripts
- Follow `copilot/instructions/readme-documentation.instructions.md` (fallback: `~/.claude/guidelines/readme-documentation.md`) for documentation
- When porting content from `~/.claude/` (only if installed), preserve the intent and structure while adapting syntax to Copilot's format
- Instructions files use YAML frontmatter with `applyTo` glob patterns
- Agent files use YAML frontmatter with `name`, `description`, and `tools` arrays

## Branch Policy

Work on feature branches. Main is the stable configuration that gets symlinked into other projects.
<\!-- central-ops-knowledge: begin -->
## Central Ops Knowledge (shared doctrine — all my AI tools)

I maintain ONE central, authoritative **ops-knowledge state** for my homelab/home: **dynamic**
(live, current, queryable by every human and AI on the LAN) and **archival** (durable,
portable, hand-off-able to anyone taking over anything). It lives in the **HomeAssistant repo**
(`/Volumes/workspace/HomeAssistant/` → `home-ops/` OKF bundle + `wiki/`), is surfaced
live to agents via the read-only **`kb-mcp` filesystem MCP** (`mini.local:8092`, tools
`search`/`read_file`/`list_dir`; registered in **Hazel**/OpenWebUI and reusable by any MCP
client) and to humans via **`kb-static`** browse (`mini.local:8090`), and kept current by the
`tools/*-scan.sh` self-tracking probes. (Ingesting the bundle into the **Librarian RAG** is on
indefinite hold — the MCP reads markdown live, no re-index.) Full doctrine:
`~/.claude/guidelines/central-ops-knowledge.md`.

Operating rules for every agent (Claude, OpenCode, Codex, Cursor, Droid, Copilot…):
1. **Consult before acting on infrastructure** — before stopping/changing a service, host, or
   config, check the knowledge base for "what is this and *why*." Stale assumptions cause outages.
2. **Write back** — when you learn or change something about the ops state, record or flag it so
   it stays current. Session-only knowledge is lost.
3. **OKF form** — plain markdown + YAML, **no secrets** (pointers only), conformant for any tool.
4. **Local-first / WAN-tolerant** — prefer local LLM/files/Kiwix; must work with the internet down.
5. **Respect boundaries** — household surfaces LAN-only; don't touch non-Scott tailnet hosts.
<\!-- central-ops-knowledge: end -->
