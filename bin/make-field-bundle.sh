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
   "$REPO_DIR/field-kit/RUNBOOK.md" "$REPO_DIR/field-kit/USING-COPILOT.md" \
   "$REPO_DIR/field-kit/INSTALL.md" "$REPO_DIR/field-kit/install-into-project.ps1" \
   "$REPO_DIR/field-kit/install-laptop.sh" "$KIT/"
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

echo "==> zip + encode"
mkdir -p "$DIST"
( cd "$STAGE" && zip -qr "$NAME.zip" field-kit )
ZIP="$STAGE/$NAME.zip"
ZIP_SHA="$(sha256 "$ZIP")"
# base64, wrapped to 120-col lines for a readable/mail-safe here-string body.
# Guarantee a trailing newline: PowerShell's here-string terminator '@ must sit at
# column 0, and fold does not always emit a final newline.
base64 < "$ZIP" | tr -d '\n' | fold -w 120 > "$STAGE/$NAME.b64"
printf '\n' >> "$STAGE/$NAME.b64"

echo "==> emit self-extracting PowerShell (.ps1.txt)"
# Deliverable: ONE PowerShell script carrying the base64 inline. Emailed as .txt;
# on the target the recipient renames it to .ps1 and runs it. It decodes, verifies
# the SHA-256, unzips into %USERPROFILE%\field-kit, and prints next steps. Windows
# PowerShell 5.1 (the box's default) — no admin, no external modules.
PS1_TXT="$DIST/$NAME.ps1.txt"
{
cat <<PSHEAD
<#
  $NAME — self-extracting GitHub Copilot field kit.

  Emailed as .txt. On the TARGET machine:
    1. Save this file, rename it from .txt to  $NAME.ps1
    2. Open PowerShell in that folder and run:
         powershell -ExecutionPolicy Bypass -File .\\$NAME.ps1
       (If Windows flagged it as from-the-internet:  Unblock-File .\\$NAME.ps1  first.)

  It decodes + verifies + unzips into the CURRENT folder (creates .\\field-kit\\).
  Nothing leaves the machine. Then follow field-kit\\BOOTSTRAP.md from step 2.
#>
\$ErrorActionPreference = 'Stop'
\$Name           = '$NAME'
\$ExpectedZipSha = '$ZIP_SHA'
\$Dest           = (Get-Location).Path
\$ZipPath        = Join-Path \$env:TEMP "\$Name.zip"

Write-Host "Decoding \$Name ..."
\$b64 = @'
PSHEAD
cat "$STAGE/$NAME.b64"
cat <<'PSFOOT'
'@
[IO.File]::WriteAllBytes($ZipPath, [Convert]::FromBase64String(($b64 -replace '\s','')))

$actual = (Get-FileHash -Algorithm SHA256 $ZipPath).Hash.ToLower()
if ($actual -ne $ExpectedZipSha.ToLower()) {
    Write-Error "SHA-256 mismatch — file corrupted in transit.`n expected $ExpectedZipSha`n got      $actual"
    exit 1
}
Write-Host "SHA-256 OK."

if (Test-Path (Join-Path $Dest 'field-kit')) {
    Write-Host "Note: $Dest\field-kit already exists — it will be overwritten."
}
Expand-Archive -Path $ZipPath -DestinationPath $Dest -Force
Remove-Item $ZipPath -ErrorAction SilentlyContinue

$KitDir = Join-Path $Dest 'field-kit'
Write-Host ""
Write-Host "Extracted to $KitDir"
Write-Host ""
Write-Host "Next (see field-kit\BOOTSTRAP.md for the full walk-through):"
Write-Host "  1. cd `"$KitDir`"  then  python probe.py        # read-only environment check"
Write-Host "  2. bash install-laptop.sh                        # tokometer instrumentation (Git Bash)"
Write-Host "  3. Install the /commands + instructions into a project's .github\ — two ways:"
Write-Host "     * PROMPT (handles a non-empty .github with judgment): open the target project"
Write-Host "       in VS Code and paste field-kit\INSTALL.md into Copilot Chat."
Write-Host "     * SCRIPT (deterministic): .\install-into-project.ps1 -Project <path-to-repo>"
Write-Host ""
Write-Host "Read USING-COPILOT.md once, RUNBOOK.md daily."
PSFOOT
} > "$PS1_TXT"

PS1_SHA="$(sha256 "$PS1_TXT")"
MANIFEST="$DIST/MANIFEST.txt"
{
  echo "# $NAME — manifest ($(date))"
  echo "deliverable: $NAME.ps1.txt   (email as .txt; rename to .ps1 on the target and run)"
  echo "ps1_sha256: $PS1_SHA"
  echo "inner_zip_sha256: $ZIP_SHA   (the script verifies this after decoding)"
} > "$MANIFEST"

# email-body card (travels outside the payload)
cp "$REPO_DIR/field-kit/BOOTSTRAP.md" "$DIST/BOOTSTRAP-email-body.txt"

echo "==> round-trip verification"
# extract the here-string body straight out of the emitted .ps1.txt, decode, and
# confirm it reproduces the exact zip — this tests the actual deliverable, not a copy.
RT="$STAGE/roundtrip"
mkdir -p "$RT"
awk "/^\\\$b64 = @'/{f=1;next} /^'@/{f=0} f" "$PS1_TXT" | tr -d '\n' \
  | { base64 -d 2>/dev/null || base64 -D; } > "$RT/$NAME.zip"
RT_SHA="$(sha256 "$RT/$NAME.zip")"
[ "$RT_SHA" = "$ZIP_SHA" ] || { echo "ROUND-TRIP FAILED: $RT_SHA != $ZIP_SHA" >&2; exit 3; }
( cd "$RT" && unzip -q "$NAME.zip" && cd field-kit && python3 probe.py --self-test )

# email size guard (single-attachment flow; base64+script overhead ~ +35%)
PS1_BYTES=$(wc -c < "$PS1_TXT" | tr -d ' ')
if [ "$PS1_BYTES" -gt "$CHUNK_BYTES" ]; then
  echo "WARNING: $NAME.ps1.txt is $((PS1_BYTES/1024/1024))MB (> $((CHUNK_BYTES/1024/1024))MB email guard)." >&2
  echo "         Split it or trim the payload before emailing." >&2
fi

echo
echo "bundle OK: $DIST  (payload $((PS1_BYTES/1024))KB)"
ls -lh "$DIST" | sed 1d
echo
echo "email: attach $NAME.ps1.txt; paste BOOTSTRAP-email-body.txt into the message."
echo "target: rename .txt -> .ps1, then  powershell -ExecutionPolicy Bypass -File .\\$NAME.ps1"
