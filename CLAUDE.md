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

- Follow `~/.claude/guidelines/conventional-commits.md` for commit messages
- Follow `~/.claude/guidelines/shell-scripts.md` for any bash scripts
- Follow `~/.claude/guidelines/readme-documentation.md` for documentation
- When porting content from `~/.claude/`, preserve the intent and structure while adapting syntax to Copilot's format
- Instructions files use YAML frontmatter with `applyTo` glob patterns
- Agent files use YAML frontmatter with `name`, `description`, and `tools` arrays

## Branch Policy

Work on feature branches. Main is the stable configuration that gets symlinked into other projects.
