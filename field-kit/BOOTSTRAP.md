# Field Kit — Bootstrap (paste this into the email body)

You received a file named `field-kit-YYYY-MM-DD.ps1.txt` — a **self-extracting
PowerShell script** carrying the whole kit inline (emailed as `.txt` so it passes
mail filters). It decodes, verifies its own SHA-256, and unzips locally. No admin,
nothing leaves the machine.

## 1. Rename and run the script

Save the attachment, then:

1. **Rename** `field-kit-YYYY-MM-DD.ps1.txt` → `field-kit-YYYY-MM-DD.ps1`
   (drop the `.txt`).
2. Open **PowerShell** in that folder and run it:

   ```powershell
   # if Windows flagged it as "from the internet", clear that first:
   Unblock-File .\field-kit-YYYY-MM-DD.ps1
   # then run (bypass covers the unsigned-script execution policy — no admin):
   powershell -ExecutionPolicy Bypass -File .\field-kit-YYYY-MM-DD.ps1
   ```

It prints "SHA-256 OK." and extracts to `%USERPROFILE%\field-kit`. If it reports a
**SHA-256 mismatch**, the file was mangled in transit — re-save the attachment (don't
copy-paste its text) and rerun. The expected hash is also in `MANIFEST.txt`.

## 2. Probe

```bash
cd ~/field-kit          # Git Bash;  or  cd %USERPROFILE%\field-kit  in cmd
python probe.py         # read-only environment check — expect PASS/WARN only
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

Two documents, two purposes:

- **`USING-COPILOT.md`** — read once, first day: how your Claude workflow maps onto
  Copilot here (session rituals, what doesn't port, working with the Auto router).
- **`RUNBOOK.md`** — the daily/weekly ritual, in ten lines. Day one is just: work
  normally, and at end of session run `harvest.sh` + the report.

*Everything collected stays on this machine. Nothing phones home.*
