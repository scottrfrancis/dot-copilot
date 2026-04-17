# Copilot Project Guidelines

These instructions provide consistent guidance across all projects. They are installed via symlink from the [dot-copilot](https://github.com/scottfrancis/dot-copilot) base configuration.

## Branch Policy and Strategy

The user works on multiple projects with different repositories, policies, and strategies. The user is also forgetful to update the local repository when starting sessions.

REMIND the user to consider the appropriate branching strategy when starting a session or a series of tasks. This reminder should include:
- current branch and status
- suggestions to pull, push, create or delete branches

## Session Safety (CRITICAL)

When working on hardware development systems with NPU/GPU devices, multiple sessions accessing devices simultaneously causes device contention, resource leakage, and complete context loss requiring system restart.

**Before every session on hardware systems**: Run session cleanup, verify device availability, and ensure exclusive hardware access.

## Available Instructions

Path-scoped instructions are auto-applied based on file context. These are installed in `.github/instructions/`:

| Instruction | Applies To | Purpose |
|---|---|---|
| `testing` | test files, source files under test | **Red-Green-Refactor TDD is REQUIRED for ALL code changes**; test pyramid, mocking, CI integration, framework-specific notes |
| `shell-scripts` | `*.sh`, `*.bash`, `Makefile` | Directory management, error handling, portability |
| `conventional-commits` | all files | Standardized commit message format |
| `readme-documentation` | `*.md` | README as central documentation hub |
| `session-safety` | all files | Prevent session hangs and context loss on hardware systems |
| `ai-patterns` | `*.py`, `*.ts`, `*.js`, AI-related files | LLM integration patterns: caching, routing, guardrails, RAG |
| `project-setup` | config/setup files | Tiered checklist for bootstrapping new projects |
| `shell-escaping` | `*.sh`, `*.bash`, `Dockerfile` | Shell quoting, TTY handling, VS Code terminal compatibility |
| `c4-diagramming` | `*.puml`, `*.plantuml` | PlantUML C4 Model organization |
| `markdown-formatting` | `*.md` | Spacing and formatting standards |

## Available Agents

Custom agents are installed in `.github/agents/`:

- **lets-go** — Session initialization with git sync protocol
- **session-logger** — Session summary with cross-linking and effectiveness assessment
- **handoff** — Generate continuation prompt for seamless session handoff
- **mine-sessions** — Analyze session logs for patterns, metrics, and improvements
- **arch-review** — Principal Architect review against industry frameworks
- **autocommit** — AI-powered conventional commit message generation
- **checkpoint-progress** — WIP commit and session state preservation

## Hooks

Registered in `.github/hooks/session-lifecycle.json`:

- **sessionStart** — Auto-injects the most recent `handoff-*.md` as context (skips files >7 days old)
- **sessionEnd** — Reminds about `session-logger` (3+ files changed) and `handoff` (5+ files changed) if not already run

## Global Behavioral Rules

- **Red-Green-Refactor TDD is REQUIRED for ALL code changes.** Always write a failing test first (RED), then the minimum production code to pass (GREEN), then refactor with tests green. No production code without a failing test. No retroactive tests. See the `testing` instruction for the full cycle, non-negotiable rules, and the (narrow) exceptions.
- Create temporary test scripts and programs in `/tmp`, not in the project directory
- When the user reports a PR has been merged, prompt them to update the local repository (pull, delete merged branch)
- When asked to push to a repo, suggest a new branch if the current branch is the default (main/master)

## Project-Specific Overrides

Projects can override any base configuration by replacing the symlink with a real file. For example, to customize the `lets-go` agent for a specific project, replace `.github/agents/lets-go.md` with a project-specific version.

## Version History

- 2026-02-17: Initial port from `~/.claude/CLAUDE.md`
