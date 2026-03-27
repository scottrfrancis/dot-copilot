#!/usr/bin/env bash
# Symlink installer for dot-copilot base configuration.
# Creates symlinks from a target project's .github/ directory to the
# copilot/ directory in this repository.
#
# Usage:
#   ./install.sh <target-project-path>
#   ./install.sh /Volumes/workspace/my-project
#
# This enables the "base class" pattern: updates to dot-copilot
# propagate automatically to all linked projects. Projects can
# override any file by replacing the symlink with a real file.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_DIR="${SCRIPT_DIR}/copilot"

# --- Argument validation ---

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target-project-path>" >&2
  echo "" >&2
  echo "Creates symlinks from the target project's .github/ directory" >&2
  echo "to this repository's copilot/ configuration files." >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  $0 /Volumes/workspace/my-project" >&2
  echo "  $0 ." >&2
  exit 1
fi

TARGET_DIR="$(cd "$1" && pwd)"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: Target directory does not exist: $1" >&2
  exit 1
fi

if [[ "$TARGET_DIR" == "$SCRIPT_DIR" ]]; then
  echo "Error: Cannot install into the dot-copilot repository itself" >&2
  exit 1
fi

# --- Setup ---

GITHUB_DIR="${TARGET_DIR}/.github"

echo "Installing dot-copilot configuration"
echo "  Source: ${SOURCE_DIR}"
echo "  Target: ${GITHUB_DIR}"
echo ""

mkdir -p "${GITHUB_DIR}"

# --- Helper functions ---

link_file() {
  local src="$1"
  local dst="$2"

  if [[ -L "$dst" ]]; then
    local existing_target
    existing_target=$(readlink "$dst")
    if [[ "$existing_target" == "$src" ]]; then
      echo "  [skip] $(basename "$dst") — already linked"
      return 0
    fi
    echo "  [update] $(basename "$dst") — updating symlink"
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "  [skip] $(basename "$dst") — real file exists (project override)"
    return 0
  else
    echo "  [link] $(basename "$dst")"
  fi

  ln -s "$src" "$dst"
}

link_directory() {
  local src="$1"
  local dst="$2"
  local name
  name=$(basename "$dst")

  if [[ -L "$dst" ]]; then
    local existing_target
    existing_target=$(readlink "$dst")
    if [[ "$existing_target" == "$src" ]]; then
      echo "  [skip] ${name}/ — already linked"
      return 0
    fi
    echo "  [update] ${name}/ — updating symlink"
    rm "$dst"
  elif [[ -d "$dst" ]]; then
    echo "  [skip] ${name}/ — real directory exists (project override)"
    return 0
  else
    echo "  [link] ${name}/"
  fi

  ln -s "$src" "$dst"
}

# --- Create symlinks ---

echo "Linking configuration files:"

# copilot-instructions.md -> .github/copilot-instructions.md
link_file "${SOURCE_DIR}/copilot-instructions.md" "${GITHUB_DIR}/copilot-instructions.md"

# instructions/ -> .github/instructions/
link_directory "${SOURCE_DIR}/instructions" "${GITHUB_DIR}/instructions"

# agents/ -> .github/agents/
link_directory "${SOURCE_DIR}/agents" "${GITHUB_DIR}/agents"

# hooks/ -> .github/hooks/
link_directory "${SOURCE_DIR}/hooks" "${GITHUB_DIR}/hooks"

echo ""

# --- Session logs directories ---

# Shared cross-tool location (primary)
if [[ ! -d "${TARGET_DIR}/session-logs" ]]; then
  mkdir -p "${TARGET_DIR}/session-logs"
  touch "${TARGET_DIR}/session-logs/.gitkeep"
  echo "Created session logs directory: session-logs/ (shared cross-tool)"
fi

# Legacy location (for backwards compatibility with older handoffs)
if [[ ! -d "${TARGET_DIR}/.claude/session-logs" ]]; then
  mkdir -p "${TARGET_DIR}/.claude/session-logs"
  echo "Created legacy session logs directory: .claude/session-logs/"
fi

# --- Summary ---

echo ""
echo "Installation complete."
echo ""
echo "Linked components:"
echo "  .github/copilot-instructions.md  -> copilot/copilot-instructions.md"
echo "  .github/instructions/            -> copilot/instructions/"
echo "  .github/agents/                  -> copilot/agents/"
echo "  .github/hooks/                   -> copilot/hooks/"
echo ""
echo "To override any component for this project, replace the"
echo "symlink with a real file or directory."
