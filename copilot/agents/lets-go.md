---
name: "lets-go"
description: "Session initialization with git sync protocol, project overview, and context loading"
tools: ["executeCommand", "readFile", "searchFiles", "editFile", "listDirectory"]
---

# Session Initialization

Set initial context for a working session.

## Load Handoff Context

Check for recent handoff files across all tool locations (check all, take newest):

1. `session-logs/` (shared cross-tool location)
2. `.claude/session-logs/` (Copilot / Claude Code legacy location)
3. `.factory/logs/` (Droid location)

If a handoff from the last 7 days is found, read it and incorporate as session context. If the file has YAML frontmatter with a `tool:` field, note the source (e.g., "Continuing from a Droid session"). Report: "Loaded handoff from [filename] ([tool])" or "No recent handoff found".

## Review Project Documentation

Review the project documentation including:

- README
- ARCHITECTURE.md (if present)
- CONTRIBUTING.md (if present)
- docs/
- plans/
- TODO
- recent commits

## Git Sync Protocol

### Dot-Repo Sync Check (dot-copilot)

Run this first, before project-repo checks. Verify the dot-copilot config repo is in sync with its GitHub origin.

1. **Locate the dot-copilot clone** — resolve a known symlinked instruction file back to the source repo:

   ```bash
   DOT_COPILOT=""
   for marker in .github/copilot-instructions.md .github/instructions/conventional-commits.instructions.md; do
     [[ -L "$marker" ]] || continue
     REAL=$(readlink -f "$marker" 2>/dev/null) || continue
     DIR="$(dirname "$REAL")"
     while [[ "$DIR" != "/" && ! -d "$DIR/.git" ]]; do DIR="$(dirname "$DIR")"; done
     [[ -d "$DIR/.git" ]] && DOT_COPILOT="$DIR" && break
   done
   ```

2. **If located**, run the drift check:

   ```bash
   git -C "$DOT_COPILOT" fetch origin
   git -C "$DOT_COPILOT" rev-list --count HEAD..origin/main   # behind
   git -C "$DOT_COPILOT" rev-list --count origin/main..HEAD   # ahead
   git -C "$DOT_COPILOT" status --porcelain
   ```

3. **Alert the user prominently** if out of sync:

   - **Behind**: "⚠ dot-copilot is {N} commits behind origin — your global agents/instructions may be stale. Consider `git -C $DOT_COPILOT pull`."
   - **Ahead**: "dot-copilot has {N} unpushed commits — consider pushing to back up your config."
   - **Dirty**: "dot-copilot has uncommitted changes."

4. **If not located**, skip silently — the user may not have installed via symlinks, or the clone moved.

### Other Dot-Repos (Opportunistic)

The user may run sessions from other tools (Claude Code, Cursor, Droid) on this machine. If any of those dot-repos are discoverable, run the same `fetch / rev-list / status` pattern against them and report drift with the same behind/ahead/dirty wording. **Skip silently for any repo not installed on this machine** — do not emit errors.

- **dot-claude**: check only if `$HOME/.claude/.git` exists.
- **dot-droid**: check only if `$HOME/.factory` is a symlink to a git repo. Resolve `readlink -f $HOME/.factory` and take its parent; confirm `.git` exists there.
- **dot-cursor**: check only if `$DOT_CURSOR_DIR` is set, or if any of `$HOME/workspace/dot-cursor`, `$HOME/dot-cursor`, `/Volumes/workspace/dot-cursor` has a `.git` directory.

### Project repo

Run these checks in order:

1. `git fetch origin` — update remote tracking refs
2. Determine current branch and its upstream tracking branch
3. If no upstream: report "Branch {name} has no upstream tracking — local only"
4. If upstream exists, compute:
   - Behind count: `git rev-list --count HEAD..origin/{branch}`
   - Ahead count: `git rev-list --count origin/{branch}..HEAD`
5. Report state clearly:
   - **In sync**: "Branch {name} is up to date with origin"
   - **Behind only**: "Branch {name} is {N} commits behind origin — recommend `git pull`"
   - **Ahead only**: "Branch {name} is {N} commits ahead — {N} unpushed commits"
   - **Diverged**: "Branch {name} has diverged — {N} ahead, {M} behind — recommend pull + rebase or merge"
6. Check for uncommitted changes (`git status --porcelain`)
   - If dirty + behind: warn "Uncommitted changes AND behind origin — stash first, then pull"
   - If clean + behind: offer to pull automatically
7. If on default branch (main/master) with uncommitted changes: suggest creating a feature branch

## Ready Output

Confirm when ready with a brief, high-level plan.

Structure the "ready" response with clear sections:

- Current Status (git, branch, sync state with origin)
- Session Context (role, recent work)
- Project Context (from README, ARCHITECTURE.md, recent session logs)
- Suggested Next Steps (based on TODOs, open issues, uncommitted changes)
