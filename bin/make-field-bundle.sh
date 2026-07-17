#!/usr/bin/env bash
# make-field-bundle.sh -- assemble the email-transferable Copilot field kit.
#
#   zip -> SHA-256 manifest -> base64 -> ordered chunks < 5 MB -> round-trip check
#
# Sources: this repo (copilot/ config, field-kit/ docs+probe) and the tokometer
# repo (collectors, lib, schemas, report). Output: dist/field-kit-<date>/ holding
# the chunk .txt files to email, MANIFEST.txt, and BOOTSTRAP-email-body.txt (paste
# into the first email — it can't ride inside the zip it reconstructs).
#
# Identity scrub gate: if ~/.config/field-kit.scrublist exists (one case-insensitive
# pattern per line: client names, hostnames, usernames), any hit in the staged
# bundle aborts the build. The scrublist itself is never committed anywhere.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOKOMETER_REPO="${TOKOMETER_REPO:-$REPO_DIR/../coder}"
SCRUBLIST="${FIELD_KIT_SCRUBLIST:-$HOME/.config/field-kit.scrublist}"
CHUNK_BYTES=$(( 4 * 1024 * 1024 ))   # 4 MiB raw chunks -> < 5 MB email attachments
DATE="$(date +%Y-%m-%d)"
NAME="field-kit-$DATE"
DIST="$REPO_DIR/dist/$NAME"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/fieldkit.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1
           else shasum -a 256 "$1" | cut -d' ' -f1; fi; }

[ -d "$TOKOMETER_REPO/collectors" ] || {
  echo "make-field-bundle: tokometer repo not found at $TOKOMETER_REPO (set TOKOMETER_REPO)" >&2
  exit 1
}

echo "==> staging"
KIT="$STAGE/field-kit"
mkdir -p "$KIT/tokometer/collectors" "$KIT/tokometer/lib"

# tokometer subset (laptop collectors + shared lib + report)
for f in copilot_chat_log.py vscode_events.py copilot_observe.py copilot_vscode.py; do
  cp "$TOKOMETER_REPO/collectors/$f" "$KIT/tokometer/collectors/"
done
cp "$TOKOMETER_REPO/lib/ledger.py" "$TOKOMETER_REPO/lib/mechanisms.py" "$KIT/tokometer/lib/"
cp "$TOKOMETER_REPO/schema.sql" "$TOKOMETER_REPO/schema_copilot_vscode.sql" \
   "$TOKOMETER_REPO/report_copilot.py" "$TOKOMETER_REPO/harvest.sh" \
   "$TOKOMETER_REPO/observe" "$KIT/tokometer/"
# git_metrics rides along when present (harvest tolerates its absence)
[ -f "$TOKOMETER_REPO/collectors/git_metrics.py" ] && \
  cp "$TOKOMETER_REPO/collectors/git_metrics.py" "$KIT/tokometer/collectors/"

# copilot config payload (instructions + agents + global rules)
cp -R "$REPO_DIR/copilot" "$KIT/copilot"

# field-kit docs, probe, installer, laptop env
cp "$REPO_DIR/field-kit/probe.py" "$REPO_DIR/field-kit/PROBE-RESULTS.md" \
   "$REPO_DIR/field-kit/RUNBOOK.md" "$REPO_DIR/field-kit/install-laptop.sh" "$KIT/"
cp "$REPO_DIR/field-kit/BOOTSTRAP.md" "$KIT/"      # reference copy inside the zip too
cp "$REPO_DIR/field-kit/tokometer.env" "$KIT/tokometer/tokometer.env"

echo "==> identity scrub gate"
if [ -f "$SCRUBLIST" ]; then
  HITS=0
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if grep -riIl -- "$pattern" "$KIT" >/dev/null 2>&1; then
      echo "SCRUB HIT: pattern '$pattern' found in:" >&2
      grep -riIl -- "$pattern" "$KIT" >&2
      HITS=1
    fi
  done < "$SCRUBLIST"
  [ "$HITS" = "0" ] || { echo "make-field-bundle: ABORTED — scrub the files above" >&2; exit 2; }
  echo "    clean against $(wc -l < "$SCRUBLIST" | tr -d ' ') pattern(s)"
else
  echo "    WARNING: no scrublist at $SCRUBLIST — identity gate SKIPPED" >&2
fi

echo "==> bundle self-test"
( cd "$KIT" && python3 probe.py --self-test )

echo "==> zip + encode + chunk"
mkdir -p "$DIST"
( cd "$STAGE" && zip -qr "$NAME.zip" field-kit )
ZIP="$STAGE/$NAME.zip"
ZIP_SHA="$(sha256 "$ZIP")"
base64 < "$ZIP" > "$STAGE/$NAME.b64"
( cd "$STAGE" && split -b "$CHUNK_BYTES" "$NAME.b64" "chunk_" )

CHUNKS=("$STAGE"/chunk_*)
TOTAL="${#CHUNKS[@]}"
MANIFEST="$DIST/MANIFEST.txt"
{
  echo "# $NAME — reassembly manifest ($(date))"
  echo "zip: $NAME.zip"
  echo "zip_sha256: $ZIP_SHA"
  echo "chunks: $TOTAL"
} > "$MANIFEST"
i=0
for c in "${CHUNKS[@]}"; do
  i=$((i+1))
  nn=$(printf "%02d" "$i"); mm=$(printf "%02d" "$TOTAL")
  out="$DIST/$NAME.b64.$nn-of-$mm.txt"
  mv "$c" "$out"
  echo "$(basename "$out") sha256: $(sha256 "$out")" >> "$MANIFEST"
done

# the email-body bootstrap card (travels OUTSIDE the zip)
cp "$REPO_DIR/field-kit/BOOTSTRAP.md" "$DIST/BOOTSTRAP-email-body.txt"

echo "==> round-trip verification"
RT="$STAGE/roundtrip"
mkdir -p "$RT"
cat "$DIST/$NAME".b64.*-of-*.txt | base64 -d > "$RT/$NAME.zip" 2>/dev/null || \
  cat "$DIST/$NAME".b64.*-of-*.txt | base64 -D > "$RT/$NAME.zip"   # BSD fallback
RT_SHA="$(sha256 "$RT/$NAME.zip")"
[ "$RT_SHA" = "$ZIP_SHA" ] || { echo "ROUND-TRIP FAILED: $RT_SHA != $ZIP_SHA" >&2; exit 3; }
( cd "$RT" && unzip -q "$NAME.zip" && cd field-kit && python3 probe.py --self-test )

echo
echo "bundle OK: $DIST"
ls -lh "$DIST" | sed 1d
echo
echo "email: attach every .txt in $DIST; paste BOOTSTRAP-email-body.txt into the first message."
