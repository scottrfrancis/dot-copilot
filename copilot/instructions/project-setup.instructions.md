---
description: "Tiered project setup checklist for bootstrapping new projects"
applyTo: "**/CLAUDE.md,**/AGENTS.md,**/.github/**,**/.claude/**"
---

# Project Setup Guideline

When starting a new project, use this tiered checklist to bootstrap the right level of infrastructure. Match the investment to the project's complexity and duration.

## How to Choose a Tier

- **Tier 1** — Any project lasting more than one session. Takes 5 minutes.
- **Tier 2** — Projects with ongoing work: multiple sessions, collaboration, or evolving requirements. Takes 15 minutes.
- **Tier 3** — Projects with repeatable domain workflows, measurable outcomes, or multi-step processes. Build incrementally.

## Tier 1: Foundation (All Projects)

- [ ] Create project instructions file (CLAUDE.md or `.github/copilot-instructions.md`) with role definition, tone guidance, repository structure overview, key commands
- [ ] Create memory/context index (`.claude/memory/MEMORY.md` or `.github/context/memory.md`)
- [ ] Create session logs directory for handoff context auto-loading
- [ ] Verify session lifecycle agents work (lets-go, session-logger)
- [ ] Document branch policy if different from default

## Tier 2: Tracked Projects

Everything from Tier 1, plus:

- [ ] Create project-specific settings/permissions
- [ ] Create session logs directory for session history
- [ ] Add project-specific hooks if needed
- [ ] Run session initialization to verify context loading
- [ ] Register any project-specific hooks

## Tier 3: Domain-Specific Lifecycle

Everything from Tier 2, plus (add incrementally):

- [ ] Custom agents for repeating workflows (when same workflow repeats 3+ times)
- [ ] Outcome tracking file for measurable cycles
- [ ] Pattern memory file for learned heuristics
- [ ] Validation hooks for data quality on critical files
- [ ] Domain-specific memory files

## Common Patterns to Reuse

### Memory Index Template

```markdown
# Project Memory Index

## Key Context
[2-3 sentences about what this project is and current priorities]

## Linked Files
- [topic.md](topic.md) — description
```
