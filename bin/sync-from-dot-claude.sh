#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# sync-from-dot-claude.sh
#
# Propagates edits from ~/.claude/guidelines/*.md into
# dot-copilot/copilot/instructions/*.instructions.md.
#
# Why: ~/.claude/guidelines/ is the authoring surface for dot-claude users.
# copilot/instructions/ is the canonical Copilot-ready form. The frontmatter
# (description, applyTo glob) in each .instructions.md is authoritative and
# must not be overwritten by the sync — only the body is replaced.
#
# Usage:
#   ./sync-from-dot-claude.sh [--dry-run] [--dot-claude PATH]
#
# Flags:
#   --dry-run         Report what would change without writing
#   --dot-claude PATH Path to dot-claude root (default: ~/.claude)
#
# Behavior:
#   - guideline foo.md matches instruction foo.instructions.md → merge
#   - guideline with no matching instruction → warn, skip (new rules need
#     a human to choose the applyTo glob before landing in dot-copilot)
#   - instruction with no matching guideline → leave alone (cursor-style
#     generic templates like md2pdf.instructions.md have no dot-claude source)
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_COPILOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTRUCTIONS_DIR="${DOT_COPILOT_DIR}/copilot/instructions"

DRY_RUN=false
DOT_CLAUDE_DIR="${HOME}/.claude"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_skip()  { echo -e "${CYAN}[SKIP]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    cat <<EOF
sync-from-dot-claude.sh

Propagate edits from ~/.claude/guidelines/*.md into copilot/instructions/*.instructions.md.
Instruction frontmatter (description, applyTo) is preserved; only the body is replaced.

Usage: $(basename "$0") [--dry-run] [--dot-claude PATH]

Options:
  --dry-run             Report what would change without writing
  --dot-claude PATH     Path to dot-claude root (default: ${DOT_CLAUDE_DIR})
  --help                Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)    DRY_RUN=true; shift ;;
        --dot-claude) DOT_CLAUDE_DIR="$2"; shift 2 ;;
        --help|-h)    usage; exit 0 ;;
        *)            log_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
done

GUIDELINES_DIR="${DOT_CLAUDE_DIR}/guidelines"

if [[ ! -d "$GUIDELINES_DIR" ]]; then
    log_error "Guidelines directory not found: ${GUIDELINES_DIR}"
    exit 1
fi

if [[ ! -d "$INSTRUCTIONS_DIR" ]]; then
    log_error "Instructions directory not found: ${INSTRUCTIONS_DIR}"
    exit 1
fi

log_info "Syncing from ${GUIDELINES_DIR} → ${INSTRUCTIONS_DIR}"
log_info "Dry run: ${DRY_RUN}"
echo ""

updated=0
unchanged=0
orphaned_guidelines=()

# Write a file if content differs; respect dry-run. Return 0 if (would be)
# updated, 1 if unchanged.
write_if_changed() {
    local dest="$1"
    local new_content="$2"

    if [[ -f "$dest" ]] && [[ "$(cat "$dest")" == "$new_content" ]]; then
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    printf '%s' "$new_content" > "$dest"
    return 0
}

for guideline in "${GUIDELINES_DIR}"/*.md; do
    [[ -f "$guideline" ]] || continue
    basename=$(basename "$guideline" .md)
    instruction="${INSTRUCTIONS_DIR}/${basename}.instructions.md"

    if [[ ! -f "$instruction" ]]; then
        orphaned_guidelines+=("$basename")
        continue
    fi

    # Extract frontmatter from instruction (first --- through second --- inclusive)
    frontmatter=$(awk '
        /^---$/ { print; count++; if (count == 2) exit; next }
        count >= 1 { print }
    ' "$instruction")

    # Extract body from guideline (skip any frontmatter it may have)
    if [[ "$(head -1 "$guideline")" == "---" ]]; then
        body=$(awk '
            /^---$/ { count++; next }
            count >= 2 { print }
        ' "$guideline")
    else
        body=$(cat "$guideline")
    fi

    new_content="${frontmatter}

${body}"

    if write_if_changed "$instruction" "$new_content"; then
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would update: ${basename}.instructions.md"
        else
            log_ok "Updated: ${basename}.instructions.md"
        fi
        updated=$((updated + 1))
    else
        log_skip "Unchanged: ${basename}.instructions.md"
        unchanged=$((unchanged + 1))
    fi
done

echo ""
log_info "Summary: ${updated} updated, ${unchanged} unchanged"

if [[ ${#orphaned_guidelines[@]} -gt 0 ]]; then
    echo ""
    log_warn "Guidelines with no matching instruction (skipped):"
    for g in "${orphaned_guidelines[@]}"; do
        log_warn "  - ${g}.md"
    done
    log_warn "Create copilot/instructions/${orphaned_guidelines[0]}.instructions.md manually with appropriate applyTo frontmatter to enable sync."
fi
