# Field Kit — Bootstrap (paste this into the FIRST email's body)

You received one or more `.txt` files named like `field-kit-YYYY-MM-DD.b64.01-of-02.txt`
plus a `MANIFEST.txt`. They are one zip, base64-encoded and split for email. Reassemble
on the laptop, verify, unzip, install. No admin needed anywhere.

## 1. Reassemble the zip

Put every chunk in one folder (e.g. `%USERPROFILE%\Downloads\fieldkit`). Then EITHER:

**Git Bash:**

```bash
cd ~/Downloads/fieldkit
cat field-kit-*.b64.*-of-*.txt | base64 -d > field-kit.zip
sha256sum field-kit.zip        # compare with the zip hash in MANIFEST.txt
```

**cmd (built-ins only):**

```bat
cd %USERPROFILE%\Downloads\fieldkit
copy /b field-kit-*.b64.01-of-*.txt+field-kit-*.b64.02-of-*.txt combined.b64
:: (add +…03-of… etc. in order if there are more chunks; single chunk: just rename)
certutil -decode combined.b64 field-kit.zip
certutil -hashfile field-kit.zip SHA256    :: compare with MANIFEST.txt
```

If the hash doesn't match: a chunk is missing/duplicated/mangled — check the
`NN-of-MM` numbering against MANIFEST.txt and redo.

## 2. Unzip and probe

Unzip `field-kit.zip` into a new folder (right-click → Extract All, or
`unzip field-kit.zip -d ~/field-kit` in Git Bash). Then:

```bash
cd ~/field-kit
python probe.py          # read-only environment check — expect PASS/WARN only
```

If "Copilot Chat log at Trace level" fails: in VS Code, `Ctrl+Shift+P` →
**Developer: Set Log Level** → **GitHub Copilot Chat** → **Trace**, use Copilot
once, rerun the probe.

## 3. Install the instrumentation (tokometer)

```bash
bash install-laptop.sh   # creates ~/.tokometer, applies schema, writes laptop config
```

Smoke-test against your real logs (writes nothing):

```bash
python ~/.tokometer/collectors/copilot_chat_log.py --dry-run
```

You should see nonzero file/request counts. Then take the first real harvest + report:

```bash
bash ~/.tokometer/harvest.sh
python ~/.tokometer/report_copilot.py
```

## 4. Install the Copilot config into your working project

Copy (not symlink — keeps it simple on Windows) into the project you work in:

```bash
cp -r ~/field-kit/copilot/copilot-instructions.md  <project>/.github/copilot-instructions.md
cp -r ~/field-kit/copilot/instructions             <project>/.github/instructions
cp -r ~/field-kit/copilot/agents                   <project>/.github/agents
```

Reload VS Code. The agents (lets-go, recover, observe, report, handoff, …) appear in
the Copilot agent dropdown; the instructions apply automatically.

## 5. Live with it

Open `RUNBOOK.md` — the daily/weekly ritual, in ten lines. Day one is just: work
normally, and at end of session run `harvest.sh` + the report.

*Everything collected stays on this machine. Nothing phones home.*
