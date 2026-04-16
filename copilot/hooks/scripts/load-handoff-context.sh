#!/usr/bin/env bash
# sessionStart hook: Auto-inject most recent handoff context into new sessions.
# Advisory only — never blocks session start.
# Looks for handoff files in shared session-logs/ first, then legacy locations
# (.claude/session-logs/, .factory/logs/), then global ~/.claude/session-logs/.
#
# Copilot adaptation notes:
# - Copilot hooks receive JSON on stdin with session context
# - Output is treated as additional context for the session
# - Uses "message" output field instead of Claude's "additionalContext"

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract current working directory from hook input
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [[ -z "$CWD" ]]; then
  CWD="$(pwd)"
fi

# Find most recent handoff file, checking shared cross-tool location first, then legacy paths
HANDOFF_FILE=""
for search_dir in "${CWD}/session-logs" "${CWD}/.claude/session-logs" "${CWD}/.factory/logs" "${HOME}/.claude/session-logs"; do
  if [[ ! -d "$search_dir" ]]; then
    continue
  fi

  # Find handoff files, most recent first (less than 7 days old)
  CANDIDATE=$(find "$search_dir" -maxdepth 1 -name "handoff-*.md" -type f -mtime -7 2>/dev/null \
    | sort -r \
    | head -1)

  if [[ -n "$CANDIDATE" ]]; then
    HANDOFF_FILE="$CANDIDATE"
    break
  fi
done

if [[ -z "$HANDOFF_FILE" ]]; then
  exit 0
fi

# Read the handoff content and emit as session context
CONTEXT=$(cat "$HANDOFF_FILE")
FILENAME=$(basename "$HANDOFF_FILE")

# Output format for Copilot hooks
jq -n \
  --arg msg "Previous session handoff (from ${FILENAME}):"$'\n\n'"${CONTEXT}" \
  '{ message: $msg }'

exit 0
