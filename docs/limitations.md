# Limitations: What Can't Be Ported

This document describes Claude Code features that have no direct GitHub Copilot equivalent, along with workarounds where possible.

## No Global User-Level Configuration

**Claude Code**: `~/.claude/` is loaded automatically for every project. Global guidelines, commands, and hooks are inherited everywhere.

**Copilot**: No equivalent to a global config directory. Each project must include its own `.github/` configuration.

**Workaround**: The `install.sh` symlink approach. Run `./install.sh /path/to/project` to link the base configuration. Updates to dot-copilot propagate automatically through symlinks.

**Trade-off**: Requires explicit installation per project. New projects don't automatically inherit the configuration.

## No Permissions Model

**Claude Code**: `settings.json` has fine-grained `allow`/`deny` lists controlling which tools and commands can be executed. Example: `Bash(git *:*)` allows all git commands.

**Copilot**: No equivalent permission model. Tool access is controlled through VS Code settings, enterprise policies, and agent `tools` arrays.

**Workaround**: Use the `tools` array in agent YAML frontmatter to restrict which tools an agent can use. For broader restrictions, configure VS Code settings or organizational policies.

## No Global Hooks

**Claude Code**: Hooks in `~/.claude/settings.json` fire for every project automatically. The `SessionStart` and `Stop` hooks provide universal session lifecycle management.

**Copilot**: Hooks are per-repository only, defined in `.github/hooks/*.json`. No global hook registration.

**Workaround**: Symlink the hooks directory via `install.sh`. Each linked project gets the same hooks. But new/unlinked projects won't have them.

## Hook Matchers Not Supported

**Claude Code**: `PostToolUse` hooks support matchers like `Write|Edit|MultiEdit` to fire only for specific tool types.

**Copilot**: The `postToolUse` event exists but matchers are not yet supported in VS Code's implementation. Hooks fire for all tool uses regardless.

**Workaround**: Check the tool type inside the hook script by parsing the JSON input, and exit early if it's not a relevant tool.

## No $ARGUMENTS Variable

**Claude Code**: Commands receive arguments via the `$ARGUMENTS` variable. Example: `/session-logger performance` passes "performance" as $ARGUMENTS.

**Copilot**: Agents receive instructions through natural language in the chat. There's no structured argument passing.

**Workaround**: Agent instructions should describe expected inputs in their description. Users provide arguments naturally in chat: "Use the session-logger agent with topic: performance."

## Different Context Injection

**Claude Code**: `SessionStart` hooks output `hookSpecificOutput.additionalContext` which gets injected into the session context as a system message.

**Copilot**: Hooks output a `message` field. The exact injection mechanism differs — context may be treated as a user message rather than system-level context.

**Workaround**: The `load-handoff-context.sh` hook has been adapted to use the `message` output format. The content is the same; only the framing differs slightly.

## No Auto-Memory

**Claude Code**: Has a persistent auto-memory directory (`~/.claude/projects/*/memory/`) where Claude automatically records patterns and insights across sessions.

**Copilot**: No equivalent auto-memory system. Memory must be managed manually through documentation files.

**Workaround**: Use session logs and handoff files for continuity. Consider maintaining a `MEMORY.md` in the project that gets manually updated with insights.

## YAML Command Format Not Supported

**Claude Code**: Some commands use a YAML step-runner format (e.g., `autocommit`) with `steps`, `ask_claude`, and `save_to_var` directives.

**Copilot**: No YAML step-runner equivalent. Agents use markdown instructions that describe the workflow.

**Workaround**: Ported as agent markdown instructions. The agent follows the steps described in prose rather than executing a structured YAML pipeline. This actually works well since AI agents are good at following natural language instructions.

## Invocation Model Differs

**Claude Code**: Commands are invoked with `/slash-command` syntax. Feels like a CLI.

**Copilot**: Agents are selected from a dropdown in the chat interface. Less discoverable but more visual.

**Impact**: Users familiar with `/lets-go` need to learn to select the "lets-go" agent from the dropdown instead. The functionality is identical — only the invocation differs.

## No Plan Mode

**Claude Code**: Has a dedicated plan mode (`EnterPlanMode`) where the agent explores the codebase and designs an approach before writing code. Read-only exploration with user approval gates.

**Copilot**: No equivalent structured planning mode. Can be approximated by asking the agent to "plan before implementing" but lacks the enforced read-only constraint.

**Workaround**: Include planning instructions in agent prompts or ask Copilot explicitly to "analyze and plan before making changes."
