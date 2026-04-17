# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository contains portable GitHub Copilot configuration files — the Copilot equivalent of `~/.claude/`. It serves as a "base class" that gets symlinked into target projects' `.github/` directories.

## Repository Structure

- `copilot/` — The deliverable: portable Copilot config files
  - `copilot-instructions.md` — Global instructions (symlinked to `.github/copilot-instructions.md`)
  - `instructions/` — Path-scoped guidelines (symlinked to `.github/instructions/`)
  - `agents/` — Custom agents (symlinked to `.github/agents/`)
  - `hooks/` — Hook definitions and scripts (symlinked to `.github/hooks/`)
- `install.sh` — Symlink installer for target projects
- `docs/` — Mapping documentation and known limitations

## Key Concepts

Each file in `copilot/` has a 1:1 mapping to a Claude Code equivalent:

| This Repo | Claude Code Equivalent |
|---|---|
| `copilot/copilot-instructions.md` | `~/.claude/CLAUDE.md` |
| `copilot/instructions/*.instructions.md` | `~/.claude/guidelines/*.md` |
| `copilot/agents/*.md` | `~/.claude/commands/*.md` |
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
