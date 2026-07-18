#!/usr/bin/env python3
"""Field-kit probe — read-only environment checks for the locked-down laptop.

Run after unzipping the bundle:    python probe.py
Bundle completeness self-test:     python probe.py --self-test

Prints a PASS/FAIL/WARN table and exits 0 (PASS/WARN) or 1 (any FAIL).
Writes nothing, changes nothing. stdlib-only; Python 3.11-compatible.
"""
import os
import sys
import glob

HERE = os.path.dirname(os.path.abspath(__file__))

# files that must ride in the bundle for the kit to work
BUNDLE_MANIFEST = [
    "tokometer/collectors/copilot_chat_log.py",
    "tokometer/collectors/vscode_events.py",
    "tokometer/collectors/copilot_observe.py",
    "tokometer/collectors/copilot_vscode.py",
    "tokometer/lib/ledger.py",
    "tokometer/lib/mechanisms.py",
    "tokometer/schema.sql",
    "tokometer/schema_copilot_vscode.sql",
    "tokometer/report_copilot.py",
    "tokometer/harvest.sh",
    "tokometer/observe",
    "tokometer/tokometer.env",
    "copilot/copilot-instructions.md",
    "copilot/instructions",
    "copilot/prompts",
    "install-laptop.sh",
    "install-into-project.ps1",
    "INSTALL.md",
    "RUNBOOK.md",
    "PROBE-RESULTS.md",
    "USING-COPILOT.md",
]


def check(name, ok, detail="", warn=False):
    status = "PASS" if ok else ("WARN" if warn else "FAIL")
    print(f"  [{status}] {name}" + (f" — {detail}" if detail else ""))
    return ok or warn


def self_test():
    print("Bundle self-test:")
    ok = True
    for rel in BUNDLE_MANIFEST:
        path = os.path.join(HERE, rel)
        ok &= check(rel, os.path.exists(path))
    print("self-test:", "OK" if ok else "INCOMPLETE BUNDLE")
    return 0 if ok else 1


def main(argv):
    if "--self-test" in argv:
        return self_test()

    print("Field-kit environment probe (read-only):")
    ok = True

    v = sys.version_info
    ok &= check("Python >= 3.11", v >= (3, 11), f"found {v.major}.{v.minor}.{v.micro}")

    appdata = os.environ.get("APPDATA")
    ok &= check("APPDATA set (Windows profile)", bool(appdata), appdata or "not set",
                warn=not bool(appdata))   # WARN on non-Windows dev machines

    logs = os.path.join(appdata or os.path.expanduser("~/AppData/Roaming"),
                        "Code", "logs")
    sessions = sorted(glob.glob(os.path.join(logs, "*")))
    ok &= check("VS Code session logs present", bool(sessions),
                f"{len(sessions)} session dir(s) under {logs}" if sessions
                else f"nothing under {logs}")

    chat_logs = glob.glob(os.path.join(
        logs, "*", "window*", "exthost", "output_logging_*",
        "*GitHub Copilot Chat*.log"))
    trace_ready = False
    for p in chat_logs[-3:]:
        try:
            with open(p, errors="replace") as f:
                head = f.read(65536)
            if "[trace]" in head:
                trace_ready = True
                break
        except OSError:
            pass
    ok &= check("Copilot Chat log at Trace level", trace_ready,
                "found [trace] lines" if trace_ready else
                "no [trace] lines found — Ctrl+Shift+P -> 'Developer: Set Log Level'"
                " -> GitHub Copilot Chat -> Trace, then use Copilot once",
                warn=bool(chat_logs))

    settings = os.path.join(appdata or "", "Code", "User", "settings.json")
    ok &= check("user settings.json readable",
                bool(appdata) and os.path.isfile(settings), settings, warn=True)

    home = os.path.expanduser(os.environ.get("TOKOMETER_HOME", "~/.tokometer"))
    parent = os.path.dirname(home) or "."
    ok &= check("can create TOKOMETER_HOME", os.access(parent, os.W_OK), home)

    print("probe:", "OK" if ok else "ISSUES FOUND — see FAILs above")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
