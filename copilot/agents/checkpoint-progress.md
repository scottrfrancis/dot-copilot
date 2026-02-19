---
name: "checkpoint-progress"
description: "Create WIP commit and log session state for context preservation"
tools: ["executeCommand", "readFile", "editFile", "listDirectory"]
---

# Progress Checkpointing

Automatically save work state to prevent context loss. Creates a WIP commit and logs session state.

## Process

1. **Verify git repository**: Confirm we're in a git repo
2. **Check for changes**: If no changes exist, report "No changes to checkpoint" and exit
3. **Show changes**: Display modified and untracked files
4. **Stage all changes**: `git add .`
5. **Create checkpoint commit**:
   ```bash
   git commit -m "WIP: checkpoint YYYY-MM-DD HH:MM:SS"
   ```
6. **Log the checkpoint**: Append to session state record
7. **Optionally push**: If a remote is configured, attempt to push

## Session State Log

After checkpointing, create/update a session state file with:

```markdown
# Session State: [project-name]
Updated: [timestamp]
Commit: [short-hash]

## Git Status
[current status]

## Recent Commits
[last 5 commits]

## Last Checkpoint
[checkpoint message]
```

## Rules

- Never checkpoint if there are no changes
- Always show what will be committed before committing
- Use WIP prefix to clearly mark checkpoint commits
- Log checkpoint to enable recovery
- Push to remote only if remote is already configured
