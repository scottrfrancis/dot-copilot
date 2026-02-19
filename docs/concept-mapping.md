# Concept Mapping: Claude Code → GitHub Copilot

This document maps every component of the `~/.claude/` configuration to its GitHub Copilot equivalent.

## Configuration Files

| Claude Code | Copilot | Notes |
|---|---|---|
| `~/.claude/CLAUDE.md` | `.github/copilot-instructions.md` | Copilot auto-detects per repo. No global user-level equivalent exists. |
| `.claude/CLAUDE.md` (project) | `.github/copilot-instructions.md` | Same mechanism, per-repo |
| `~/.claude/settings.json` | VS Code settings + enterprise policies | No direct equivalent for permissions |
| `.claude/settings.local.json` | No equivalent | Copilot has no per-project settings file |

## Guidelines → Instructions

| Claude Code | Copilot | Key Difference |
|---|---|---|
| `~/.claude/guidelines/*.md` | `.github/instructions/*.instructions.md` | Copilot uses `applyTo` YAML frontmatter for path-scoping. Claude uses manual `Read and follow` references. Copilot's approach is better — auto-applies based on context. |
| Referenced in CLAUDE.md | Auto-applied by glob pattern | No need to tell Copilot "read file X" |

### Path Scope Mapping

| Guideline | Claude Code Reference | Copilot `applyTo` |
|---|---|---|
| shell-scripts | Manual reference | `**/*.sh,**/*.bash,**/Makefile` |
| conventional-commits | Manual reference | `**` (all files) |
| readme-documentation | Manual reference | `**/README.md,**/*.md` |
| session-safety | Manual reference | `**` (all files — critical) |
| ai-patterns | Manual reference | `**/*.py,**/*.ts,**/*.js,**/prompt*,**/llm*,**/ai*` |
| project-setup | Manual reference | `**/CLAUDE.md,**/AGENTS.md,**/.github/**` |
| shell-escaping | Manual reference | `**/*.sh,**/*.bash,**/Dockerfile` |
| c4-diagramming | Manual reference | `**/*.puml,**/*.plantuml,**/diagrams/**` |
| markdown-formatting | Manual reference | `**/*.md` |

## Commands → Agents

| Claude Code Command | Copilot Agent | Key Differences |
|---|---|---|
| `/lets-go [role]` | `lets-go` agent | Invoked from dropdown, not `/slash`. No `$ARGUMENTS` — user provides context in chat. |
| `/session-logger [topic]` | `session-logger` agent | Same behavior, different invocation |
| `/handoff [notes]` | `handoff` agent | Same behavior, different invocation |
| `/mine-sessions [days:N]` | `mine-sessions` agent | Same behavior, different invocation |
| `/arch-review` | `arch-review` agent | Same behavior, different invocation |
| `/autocommit [-y] [-t type]` | `autocommit` agent | Claude's YAML step format → agent instructions |
| `/checkpoint-progress` | `checkpoint-progress` agent | Claude's bash script → agent instructions |

### Command Features Not Ported

| Claude Code | Why Not Ported |
|---|---|
| `commit-manual` (bash) | Conventional commits instruction covers this |
| `session-cleanup` (bash) | Hardware-specific, not portable |
| `validate-hw-env` (bash) | Hardware-specific, not portable |
| `extract-adr` (YAML) | Low usage, can be added later |

### Invocation Differences

- **Claude Code**: `/command-name` slash syntax, `$ARGUMENTS` variable
- **Copilot**: Selected from agent dropdown or referenced in chat. Arguments are provided naturally in conversation.
- **Claude Code**: `allowed-tools` restricts which tools a command can use
- **Copilot**: `tools` array in YAML frontmatter serves similar purpose

## Hooks

| Claude Code | Copilot | Key Differences |
|---|---|---|
| `settings.json` hooks config | `.github/hooks/*.json` | Claude embeds in settings.json; Copilot uses standalone JSON files |
| `SessionStart` event | `sessionStart` event | Same concept, different casing |
| `Stop` event | `sessionEnd` event | Different name |
| `PostToolUse` with matcher | `postToolUse` | Copilot matchers not yet supported in VS Code |
| `PreToolUse` | `preToolUse` | Copilot's can actually deny/allow tool execution (more powerful) |
| `timeout: 5000` (ms) | `timeout: 10` (seconds) | Different units |
| `additionalContext` output | `message` output | Different output field name |

### Hook Registration

**Claude Code** (in `settings.json`):
```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/script.sh",
        "timeout": 5000
      }]
    }]
  }
}
```

**Copilot** (in `.github/hooks/session-lifecycle.json`):
```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{
      "command": ".github/hooks/scripts/script.sh",
      "timeout": 10
    }]
  }
}
```

## Global vs Per-Project

| Aspect | Claude Code | Copilot |
|---|---|---|
| Global config | `~/.claude/` — loaded for all projects automatically | No equivalent. Must symlink per-project. |
| Global hooks | `~/.claude/settings.json` — fire for every project | No global hooks. Per-project only. |
| Global commands | `~/.claude/commands/` — available everywhere | No global agents. Per-project only. |
| Override pattern | Project `.claude/` shadows `~/.claude/` | Replace symlink with real file |

## Session Management

| Claude Code | Copilot | Notes |
|---|---|---|
| `.claude/session-logs/` | `.claude/session-logs/` | Same directory — shared between both tools |
| `handoff-*.md` format | Same format | Hooks look for same file pattern |
| `MEMORY.md` | No built-in equivalent | Can use `.github/context/` directory |
| Auto-memory directory | No equivalent | Must be managed manually |

## Permissions

| Claude Code | Copilot | Notes |
|---|---|---|
| `Bash(git *:*)` allowlist | No equivalent | Copilot uses VS Code settings for tool access |
| `Read(path)` permissions | No equivalent | All files readable by default |
| `Skill(name)` permissions | No equivalent | All agents accessible |
| `deny` list | No equivalent | Use enterprise policies for restrictions |
