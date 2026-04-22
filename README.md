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

**Behavior rules** (always apply):

| Instruction | Purpose |
|---|---|
| [conventional-commits](copilot/instructions/conventional-commits.instructions.md) | Standardized `type(scope): description` commit format |
| [karpathy-principles](copilot/instructions/karpathy-principles.instructions.md) | Surface assumptions before implementing; match existing style |
| [prototype-hygiene](copilot/instructions/prototype-hygiene.instructions.md) | Config over code; docs describe current state; PRs over branches |
| [session-safety](copilot/instructions/session-safety.instructions.md) | Prevent session hangs on hardware/NPU/GPU systems |
| [security-hardening](copilot/instructions/security-hardening.instructions.md) | Breach-driven web security audit, auth hardening, tenant isolation |

**Language/file-scoped**:

| Instruction | Applies To | Purpose |
|---|---|---|
| [ai-patterns](copilot/instructions/ai-patterns.instructions.md) | `*.py`, `*.ts`, `*.js` | LLM integration patterns |
| [C4-diagramming](copilot/instructions/C4-diagramming.instructions.md) | `*.puml`, `*.plantuml` | C4 Model PlantUML organization |
| [golang](copilot/instructions/golang.instructions.md) | `*.go`, `go.mod`, `go.sum` | Go JSON safety, gosec patterns, G104 triage |
| [markdown-formatting](copilot/instructions/markdown-formatting.instructions.md) | `*.md`, `*.mdx` | Spacing and formatting standards |
| [prose-style](copilot/instructions/prose-style.instructions.md) | `*.md`, `*.mdx` | Anti-AI-smell rules for narrative prose |
| [readme-documentation](copilot/instructions/readme-documentation.instructions.md) | `*.md` | README as central documentation hub |
| [shell-escaping](copilot/instructions/shell-escaping.instructions.md) | `*.sh`, `*.bash`, `Dockerfile` | Shell quoting, TTY handling |
| [shell-scripts](copilot/instructions/shell-scripts.instructions.md) | `*.sh`, `*.bash`, `Makefile` | Directory management, error handling |
| [testing](copilot/instructions/testing.instructions.md) | `*.test.*`, `*.spec.*`, test dirs | Test pyramid, TDD, mocking |

**Workflow-scoped**:

| Instruction | Applies To | Purpose |
|---|---|---|
| [ci-local-parity](copilot/instructions/ci-local-parity.instructions.md) | `.github/workflows/**` | Run every CI command locally before pushing |
| [docx-conversion](copilot/instructions/docx-conversion.instructions.md) | `*.py`, `md-to-docx*` | python-docx over pandoc; color, typography, hyperlinks |
| [md2pdf](copilot/instructions/md2pdf.instructions.md) | md2pdf workflows | Markdown → PDF conversion workflow |
| [pr-token-tracking](copilot/instructions/pr-token-tracking.instructions.md) | PR creation | Include AI token usage in PR descriptions |
| [project-setup](copilot/instructions/project-setup.instructions.md) | config files | Tiered project bootstrapping checklist |

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
├── bin/
│   └── sync-from-dot-claude.sh  # Propagate ~/.claude/guidelines/ edits to copilot/instructions/
├── session-logs/                # Cross-tool session logs (Cursor, Droid, Copilot, Claude Code)
├── .claude/                     # Claude Code project setup (Tier 1)
│   └── memory/MEMORY.md
├── copilot/                     # THE DELIVERABLE — portable Copilot config
│   ├── copilot-instructions.md  # Global behavioral rules
│   ├── instructions/            # Path-scoped guidelines (18 files)
│   ├── agents/                  # Custom agents (9 files)
│   └── hooks/                   # Hook config + scripts
│       ├── session-lifecycle.json
│       └── scripts/
└── docs/
    ├── concept-mapping.md       # Claude Code ↔ Copilot mapping
    └── limitations.md           # What can't be ported
```

## Self-contained by design

`copilot/` contains all the content shipped by this repo. A Copilot-only user can clone dot-copilot and run `./install.sh /path/to/project` with no external dependencies — no `~/.claude/` checkout required. The installer uses symlinks by default, so updates in this repo propagate automatically to every linked project.

## Syncing edits from dot-claude

If you author rule content in [`~/.claude/guidelines/`](https://github.com/scottrfrancis/dot-claude) and want to propagate edits into this repo's instructions:

```bash
./bin/sync-from-dot-claude.sh --dry-run   # preview which instructions would change
./bin/sync-from-dot-claude.sh             # apply — writes bodies into copilot/instructions/
git diff copilot/instructions/            # review before committing
```

The sync script preserves each instruction's existing frontmatter (`description:` and `applyTo:`) and replaces only the body. New guidelines with no matching instruction are reported as warnings; create the instruction file manually first with an appropriate `applyTo:` glob before re-running.

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
