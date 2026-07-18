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

## 4. Install the Copilot config into your working project (.github may not be empty)

Two ways — both safe for a project whose `.github/` already has content. **Pick one.**

### Option A — let Copilot do it (recommended; handles merges with judgment)

Best when the target project already has its own `.github/copilot-instructions.md` or
instructions you don't want clobbered.

1. Open the **target project** in VS Code.
2. Make the expanded kit reachable in that workspace — simplest is to run the
   self-extracting `.ps1` from the project root so `field-kit\` lands inside it (or
   copy the extracted `field-kit\` folder into the project).
3. Open `field-kit/INSTALL.md`, copy its contents, paste into **Copilot Chat**, send.

Copilot surveys the existing `.github/`, merges the kit in file-by-file, reconciles an
existing `copilot-instructions.md` with your approval, and never overwrites without
showing you a diff first. It works in Manual mode — approve each step.

### Option B — deterministic script (no Copilot turns)

From the extracted field-kit folder:

```powershell
.\install-into-project.ps1 -Project C:\path\to\your\repo
.\install-into-project.ps1 -Project ..\repo -DryRun   # preview, writes nothing
```

It merges into `.github\`, backs up any conflicting file to `<name>.bak.<timestamp>`,
and refuses to overwrite an existing `copilot-instructions.md` (drops the kit's copy as
`copilot-instructions.base.md` for you to merge). It reports everything it backed up.

### Either way

Reload VS Code. Instructions apply automatically; the rituals are **runnable commands** —
type `/lets-go`, `/handoff`, `/recover`, `/report`, `/observe` … in the Chat box (args
after the name), press Enter, runs inline. No dropdown, no mode-switching.

## 5. Live with it

Two documents, two purposes:

- **`USING-COPILOT.md`** — read once, first day: how your Claude workflow maps onto
  Copilot here (session rituals, what doesn't port, working with the Auto router).
- **`RUNBOOK.md`** — the daily/weekly ritual, in ten lines. Day one is just: work
  normally, and at end of session run `harvest.sh` + the report.

*Everything collected stays on this machine. Nothing phones home.*
