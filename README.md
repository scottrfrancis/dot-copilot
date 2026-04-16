# dot-copilot

Portable GitHub Copilot configuration — the Copilot equivalent of `~/.claude/`. Provides consistent guidelines, agents, and hooks across all projects via symlinks.

## Quick Start

```bash
# Install into a target project
./install.sh /path/to/your/project

# This creates symlinks in .github/:
#   .github/copilot-instructions.md -> copilot/copilot-instructions.md
#   .github/instructions/           -> copilot/instructions/
#   .github/agents/                 -> copilot/agents/
#   .github/hooks/                  -> copilot/hooks/
```

## How It Works

This repository is a **base class** for Copilot configuration. It contains reusable instructions, agents, and hooks that get symlinked into each project's `.github/` directory. Updates here propagate automatically to all linked projects.

```
dot-copilot/copilot/          Target project/.github/
├── copilot-instructions.md  ←──  copilot-instructions.md (symlink)
├── instructions/            ←──  instructions/ (symlink)
├── agents/                  ←──  agents/ (symlink)
└── hooks/                   ←──  hooks/ (symlink)
```

### Overriding (The "super()" Pattern)

To customize any component for a specific project, replace the symlink with a real file:

```bash
# Replace the symlinked agents directory with a project-specific one
rm .github/agents
cp -r /Volumes/workspace/dot-copilot/copilot/agents .github/agents

# Now edit .github/agents/lets-go.md for project-specific behavior
```

The base config knows nothing about any specific project — projects extend it.

## Components

### Instructions (Path-Scoped Guidelines)

Auto-applied by Copilot based on `applyTo` glob patterns in YAML frontmatter.

| Instruction | Applies To | Purpose |
|---|---|---|
| [shell-scripts](copilot/instructions/shell-scripts.instructions.md) | `*.sh`, `*.bash`, `Makefile` | Directory management, error handling, portability |
| [conventional-commits](copilot/instructions/conventional-commits.instructions.md) | all files | Standardized commit message format |
| [readme-documentation](copilot/instructions/readme-documentation.instructions.md) | `*.md` | README as central documentation hub |
| [session-safety](copilot/instructions/session-safety.instructions.md) | all files | Prevent session hangs on hardware systems |
| [ai-patterns](copilot/instructions/ai-patterns.instructions.md) | `*.py`, `*.ts`, `*.js`, AI files | LLM integration patterns |
| [project-setup](copilot/instructions/project-setup.instructions.md) | config files | Tiered project bootstrapping checklist |
| [shell-escaping](copilot/instructions/shell-escaping.instructions.md) | `*.sh`, `*.bash`, `Dockerfile` | Shell quoting, TTY handling |
| [c4-diagramming](copilot/instructions/c4-diagramming.instructions.md) | `*.puml`, `*.plantuml` | C4 Model PlantUML organization |
| [markdown-formatting](copilot/instructions/markdown-formatting.instructions.md) | `*.md` | Spacing and formatting standards |
| [testing](copilot/instructions/testing.instructions.md) | `*.test.*`, `*.spec.*`, test dirs | Test pyramid, mocking, CI integration |

### Agents (Custom Agents)

Invoked from the Copilot agent dropdown. Ported from Claude Code commands.

| Agent | Purpose |
|---|---|
| [lets-go](copilot/agents/lets-go.md) | Session initialization with git sync protocol |
| [session-logger](copilot/agents/session-logger.md) | Session summary with effectiveness assessment |
| [handoff](copilot/agents/handoff.md) | Continuation prompt for next session |
| [mine-sessions](copilot/agents/mine-sessions.md) | Analyze session logs for patterns and metrics |
| [arch-review](copilot/agents/arch-review.md) | Principal Architect review against industry frameworks |
| [autocommit](copilot/agents/autocommit.md) | AI-powered conventional commit message generation |
| [checkpoint-progress](copilot/agents/checkpoint-progress.md) | WIP commit and session state preservation |
| [review-pr](copilot/agents/review-pr.md) | PR code review: bugs, security, missing tests, style |
| [babysit-pr](copilot/agents/babysit-pr.md) | Monitor a PR for checks, reviews, and merge readiness |

### Hooks

Defined in [session-lifecycle.json](copilot/hooks/session-lifecycle.json):

| Event | Script | Purpose |
|---|---|---|
| `sessionStart` | [load-handoff-context.sh](copilot/hooks/scripts/load-handoff-context.sh) | Auto-inject most recent handoff file (<7 days old) |
| `sessionEnd` | [session-end-reminder.sh](copilot/hooks/scripts/session-end-reminder.sh) | Remind about session-logger (3+ files) and handoff (5+ files) |

## Repository Structure

```
dot-copilot/
├── README.md                    # This file
├── CLAUDE.md                    # For developing this project with Claude Code
├── install.sh                   # Symlink installer
├── session-logs/                # Cross-tool session logs (Cursor, Droid, Copilot, Claude Code)
├── .claude/                     # Claude Code project setup (Tier 1)
│   ├── memory/MEMORY.md
│   └── session-logs/            # LEGACY — use session-logs/ at project root instead
├── copilot/                     # THE DELIVERABLE — portable Copilot config
│   ├── copilot-instructions.md  # Global behavioral rules
│   ├── instructions/            # Path-scoped guidelines (9 files)
│   ├── agents/                  # Custom agents (7 files)
│   └── hooks/                   # Hook config + scripts
│       ├── session-lifecycle.json
│       └── scripts/
└── docs/
    ├── concept-mapping.md       # Claude Code ↔ Copilot mapping
    └── limitations.md           # What can't be ported
```

## Origin

This configuration is ported from a `~/.claude/` setup for Claude Code. See [docs/concept-mapping.md](docs/concept-mapping.md) for the full mapping between the two systems and [docs/limitations.md](docs/limitations.md) for what couldn't be ported.

## Session Lifecycle

The agents and hooks implement a session lifecycle pattern:

```
[sessionStart hook] → auto-inject handoff context
  ↓
lets-go agent → sync git, load docs, verify context
  ↓
[work]
  ↓
[sessionEnd hook] → remind about logging
  ↓
session-logger agent → capture outcomes
handoff agent → generate continuation prompt
```
