# dot-copilot

Portable GitHub Copilot configuration — the Copilot equivalent of `~/.claude/`. Provides consistent guidelines, runnable /commands, and hooks across all projects via symlinks.

## Quick Start

```bash
# Install into a target project
./install.sh /path/to/your/project

# This creates symlinks in .github/:
#   .github/copilot-instructions.md -> copilot/copilot-instructions.md
#   .github/instructions/           -> copilot/instructions/
#   .github/prompts/                -> copilot/prompts/
#   .github/hooks/                  -> copilot/hooks/
```

## How It Works

This repository is a **base class** for Copilot configuration. It contains reusable instructions, prompt-file commands, and hooks that get symlinked into each project's `.github/` directory. Updates here propagate automatically to all linked projects.

```
dot-copilot/copilot/          Target project/.github/
├── copilot-instructions.md  ←──  copilot-instructions.md (symlink)
├── instructions/            ←──  instructions/ (symlink)
├── prompts/                 ←──  prompts/ (symlink)
└── hooks/                   ←──  hooks/ (symlink)
```

### Overriding (The "super()" Pattern)

To customize any component for a specific project, replace the symlink with a real file:

```bash
# Replace the symlinked prompts directory with a project-specific one
rm .github/prompts
cp -r /Volumes/workspace/dot-copilot/copilot/prompts .github/prompts

# Now edit .github/prompts/lets-go.prompt.md for project-specific behavior
```

The base config knows nothing about any specific project — projects extend it.

## Components

### Instructions (Path-Scoped Guidelines)

Auto-applied by Copilot based on `applyTo` glob patterns in YAML frontmatter.

**Behavior rules** (always apply):

| Instruction | Purpose |
|---|---|
| [conventional-commits](copilot/instructions/conventional-commits.instructions.md) | Standardized `type(scope): description` commit format |
| [copilot-auto-tactics](copilot/instructions/copilot-auto-tactics.instructions.md) | Auto-router tactics: signal complexity, plan before tools, never fragment a failing ask |
| [context-hygiene](copilot/instructions/context-hygiene.instructions.md) | Handoff→clear→pickup at half context; small per-turn payloads; OOM-aware habits |
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

### Prompts (Runnable Commands)

Invoked by typing **`/name`** in the Copilot Chat box (arguments follow the name),
the same run-it-and-go gesture as a Claude Code slash-command. Ported from
`~/.claude/commands/`. These are prompt files, **not** chat modes — nothing here is
a dropdown persona you switch into; the kit ships no custom modes by design.

| Command | Purpose |
|---|---|
| [/lets-go](copilot/prompts/lets-go.prompt.md) | Session initialization with git sync protocol |
| [/session-logger](copilot/prompts/session-logger.prompt.md) | Session summary with effectiveness assessment |
| [/handoff](copilot/prompts/handoff.prompt.md) | Continuation prompt for next session |
| [/mine-sessions](copilot/prompts/mine-sessions.prompt.md) | Analyze session logs for patterns and metrics |
| [/arch-review](copilot/prompts/arch-review.prompt.md) | Principal Architect review against industry frameworks |
| [/autocommit](copilot/prompts/autocommit.prompt.md) | AI-powered conventional commit message generation |
| [/checkpoint-progress](copilot/prompts/checkpoint-progress.prompt.md) | WIP commit and session state preservation |
| [/review-pr](copilot/prompts/review-pr.prompt.md) | PR code review: bugs, security, missing tests, style |
| [/babysit-pr](copilot/prompts/babysit-pr.prompt.md) | Monitor a PR for checks, reviews, and merge readiness |
| [/recover](copilot/prompts/recover.prompt.md) | Diagnose a Copilot stall/error by mechanism, apply the matching fix, log it |
| [/observe](copilot/prompts/observe.prompt.md) | Record a manual quality/stall/continue observation (tokometer field kit) |
| [/report](copilot/prompts/report.prompt.md) | Run the Copilot daily/weekly strategy report and summarize what changed |
| [/explain-diff-md](copilot/prompts/explain-diff-md.prompt.md), [/explain-diff-html](copilot/prompts/explain-diff-html.prompt.md) | Rich explanation of a diff/branch/PR as a self-contained doc |

The `/recover`, `/observe`, `/report` commands pair with the **tokometer field kit** — the
Copilot-in-VS-Code collectors and reports in the [tokometer](https://github.com/scottrfrancis/coder)
repo — built for locked-down machines where Copilot (Auto-only) is the sole assistant.
They degrade gracefully when the kit isn't installed. See `plans/GOALS.md` / `plans/PLAN.md`
for the field-kit program.

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
│   ├── sync-from-dot-claude.sh  # Propagate ~/.claude/guidelines/ edits to copilot/instructions/
│   └── make-field-bundle.sh     # Assemble the email-transferable field kit (zip → b64 chunks)
├── field-kit/                   # Locked-down-laptop kit: probe, BOOTSTRAP/RUNBOOK, installer
├── plans/                       # Field-kit program: GOALS.md + PLAN.md (probe results inside)
├── session-logs/                # Cross-tool session logs (Cursor, Droid, Copilot, Claude Code)
├── .claude/                     # Claude Code project setup (Tier 1)
│   └── memory/MEMORY.md
├── copilot/                     # THE DELIVERABLE — portable Copilot config
│   ├── copilot-instructions.md  # Global behavioral rules
│   ├── instructions/            # Path-scoped guidelines (18 files)
│   ├── prompts/                 # Runnable /commands (14 files)
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

The commands and hooks implement a session lifecycle pattern:

```
[sessionStart hook] → auto-inject handoff context
  ↓
/lets-go → sync git, load docs, verify context
  ↓
[work]
  ↓
[sessionEnd hook] → remind about logging
  ↓
/session-logger → capture outcomes
/handoff → generate continuation prompt
```
