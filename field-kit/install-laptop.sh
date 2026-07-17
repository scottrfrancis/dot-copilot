#!/usr/bin/env bash
# install-laptop.sh -- install the tokometer field kit into ~/.tokometer (Git Bash).
# Idempotent: re-run after every kit update. Kit files are overwritten; the ledger
# (ledger.db), harvest state, and an existing tokometer.env are preserved.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKOMETER_HOME="${TOKOMETER_HOME:-$HOME/.tokometer}"
PY="$(command -v python3 || command -v python)"

[ -n "$PY" ] || { echo "install: no python found on PATH" >&2; exit 1; }
[ -d "$KIT_DIR/tokometer" ] || { echo "install: run from the unzipped field-kit folder" >&2; exit 1; }

echo "installing tokometer field kit -> $TOKOMETER_HOME"
mkdir -p "$TOKOMETER_HOME"/{collectors,lib,state,reports}

cp "$KIT_DIR"/tokometer/collectors/*.py "$TOKOMETER_HOME/collectors/"
cp "$KIT_DIR"/tokometer/lib/*.py        "$TOKOMETER_HOME/lib/"
cp "$KIT_DIR"/tokometer/schema*.sql     "$TOKOMETER_HOME/"
cp "$KIT_DIR"/tokometer/report_copilot.py "$TOKOMETER_HOME/"
cp "$KIT_DIR"/tokometer/harvest.sh      "$TOKOMETER_HOME/"
cp "$KIT_DIR"/tokometer/observe         "$TOKOMETER_HOME/"
chmod +x "$TOKOMETER_HOME/harvest.sh" "$TOKOMETER_HOME/observe"

# per-machine config: write the laptop profile only if none exists (preserve edits)
if [ ! -f "$TOKOMETER_HOME/tokometer.env" ]; then
  cp "$KIT_DIR/tokometer/tokometer.env" "$TOKOMETER_HOME/tokometer.env"
  echo "wrote laptop profile -> $TOKOMETER_HOME/tokometer.env"
else
  echo "kept existing $TOKOMETER_HOME/tokometer.env"
fi

# apply schemas (idempotent CREATE IF NOT EXISTS)
"$PY" - "$TOKOMETER_HOME" <<'EOF'
import sys, os, glob, sqlite3
home = sys.argv[1]
con = sqlite3.connect(os.path.join(home, "ledger.db"))
for schema in sorted(glob.glob(os.path.join(home, "schema*.sql"))):
    con.executescript(open(schema).read())
con.commit(); con.close()
print("ledger schema applied")
EOF

# make `observe` reachable from any Git Bash shell
BASHRC="$HOME/.bashrc"
if ! grep -q "tokometer/observe" "$BASHRC" 2>/dev/null; then
  echo "alias observe='bash $TOKOMETER_HOME/observe'" >> "$BASHRC"
  echo "added 'observe' alias to ~/.bashrc (open a new shell to use it)"
fi

echo
echo "install complete. Next:"
echo "  $PY $TOKOMETER_HOME/collectors/copilot_chat_log.py --dry-run   # smoke test"
echo "  bash $TOKOMETER_HOME/harvest.sh                                # first harvest"
echo "  $PY $TOKOMETER_HOME/report_copilot.py                          # first report"
