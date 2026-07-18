#!/usr/bin/env python3
"""entity-advisory — the graylist half of a black/white/gray data-diode control.

Three lists guard a one-way egress boundary (here: config/bundle content about to be
pushed or emailed). See the `data-diode-list-control` guideline for the pattern.

    BLACKLIST  ~/.config/field-kit.scrublist   deny — exact-match block (hard gate)
    WHITELIST  ~/.config/field-kit.allowlist   allow — known-safe, silenced
    GRAYLIST   ~/.config/field-kit.graylist    pending — seen, undecided, PROMOTABLE

This tool populates and works the graylist: it scans what you're about to push for
entity-shaped tokens (client/project/person/host candidates), and anything in NEITHER
the black nor white list is a GRAY. New grays are reported for triage; you PROMOTE each
gray to black (scrub) or white (allow). Grays already recorded don't re-nag.

ADVISORY by default (prints, exits 0). --strict exits 1 on new grays (CI gate).

Usage:
    entity-advisory.py                      # scan origin/<default>..HEAD; report NEW grays
    entity-advisory.py --range A..B         # scan an explicit git range
    entity-advisory.py --staged             # scan staged changes
    entity-advisory.py --files f1 f2        # scan specific files (whole content)
    entity-advisory.py --record             # also append new grays to the graylist
    entity-advisory.py --list-gray          # show the pending graylist
    entity-advisory.py --promote TERM --to scrub|allow   # graylist → black/white
    entity-advisory.py --self-test
    entity-advisory.py --strict

Config (env overrides, else ~/.config): FIELD_KIT_SCRUBLIST / _ALLOWLIST / _GRAYLIST.
stdlib only; Python 3.11-compatible.
"""
import os
import re
import sys
import subprocess

HOME = os.path.expanduser("~")
_CFG = lambda name, default: os.environ.get(name, os.path.join(HOME, ".config", default))
SCRUBLIST = _CFG("FIELD_KIT_SCRUBLIST", "field-kit.scrublist")
ALLOWLIST = _CFG("FIELD_KIT_ALLOWLIST", "field-kit.allowlist")
GRAYLIST  = _CFG("FIELD_KIT_GRAYLIST",  "field-kit.graylist")

EXTRACTORS = [
    ("multi-word name", re.compile(r"\b([A-Z][a-z]{2,}(?:[ -][A-Z][a-z]+){1,3})\b"), 1),
    ("CamelCase brand",  re.compile(r"\b([A-Z][a-z]+[A-Z][A-Za-z]{2,})\b"), 1),
    ("domain",           re.compile(r"\b((?:[a-z0-9][a-z0-9-]*\.)+(?:com|net|org|io|ai|co|gov|edu))\b", re.I), 1),
    ("Windows identity", re.compile(r"\b([A-Z0-9]{3,}\\[A-Za-z0-9._-]+|Users[\\/][A-Za-z0-9._-]+)\b"), 1),
    ("hostname",         re.compile(r"\b([A-Z]{2}-[A-Z0-9]{5,})\b"), 1),
    ("ALLCAPS acronym",  re.compile(r"\b([A-Z]{3,6})\b"), 1),
]

BUILTIN_SAFE = {w.lower() for w in """
github gitlab git copilot claude cursor droid opencode anthropic openai microsoft
google amazon aws gcp azure windows macos linux ubuntu debian chrome firefox safari
python typescript javascript node nodejs deno bun java kotlin swift rust golang ruby
docker kubernetes terraform ansible bash powershell cmd zsh readme changelog license
contributing makefile dockerfile gherkin cucumber pytest jest mocha vitest playwright
vscode jetbrains intellij
dot-copilot dot-claude dot-cursor dot-droid dot-opencode tokometer routometer field-kit
adr sdlc mcp cli api sdk json yaml yml html css scss sql http https url uri utc pst pdt
edt est tdd bdd otel otlp oom cpu gpu ram ssd usb pdf png jpg svg csv tsv toml env
crud rest grpc jwt oauth saml sso rbac vpc dns ssl tls ssh scp ftp smtp imap
the this that these those when where while with without from into onto over under
and but for nor yet not use uses used using see set sets run runs runa add adds note
notes new old all any each per via etc via fix fixes feat docs test tests build ci
chore refactor perf style revert wip todo fixme
part phase step steps input inputs output outputs status context decision consequences
example examples usage arguments verification background feature scenario given then
""".split()}

STOP_LEADERS = {"the","this","that","these","those","when","where","while","with",
    "from","into","use","see","set","run","add","note","new","for","and","but","how",
    "why","what","which","each","every","some","any","all","most","more","less","one",
    "two","first","next","last","phase","step","part","also","then","given","before",
    "after","following","optional","required"}


def _read_lines(path):
    out = []
    try:
        with open(path) as f:
            for line in f:
                s = line.strip()
                if not s or s.startswith("#"):
                    continue
                s = re.split(r"\s+#", s, maxsplit=1)[0].strip()
                if s:
                    out.append(s)
    except FileNotFoundError:
        pass
    return out


def _append_line(path, term):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    existing = set(_read_lines(path))
    if term in existing:
        return False
    with open(path, "a") as f:
        f.write(term + "\n")
    return True


def _remove_line(path, term):
    try:
        lines = open(path).read().splitlines()
    except FileNotFoundError:
        return False
    kept, removed = [], False
    for line in lines:
        if re.split(r"\s+#", line.strip(), maxsplit=1)[0].strip() == term:
            removed = True
            continue
        kept.append(line)
    if removed:
        with open(path, "w") as f:
            f.write("\n".join(kept) + ("\n" if kept else ""))
    return removed


def _git(args):
    return subprocess.run(["git"] + args, capture_output=True, text=True).stdout


def _added_text(range_=None, staged=False, files=None):
    if files:
        chunks = []
        for fp in files:
            try:
                chunks.append(open(fp, errors="replace").read())
            except OSError:
                pass
        return "\n".join(chunks)
    if staged:
        diff = _git(["diff", "--cached", "--unified=0"])
    else:
        if not range_:
            head = _git(["symbolic-ref", "--quiet", "--short", "HEAD"]).strip() or "HEAD"
            base = _git(["rev-parse", "--verify", "--quiet", "origin/HEAD"]).strip()
            if not base:
                for b in ("origin/main", "origin/master"):
                    if _git(["rev-parse", "--verify", "--quiet", b]).strip():
                        base = b
                        break
            range_ = f"{base}..{head}" if base else "HEAD~1..HEAD"
        diff = _git(["diff", range_, "--unified=0"])
    return "\n".join(l[1:] for l in diff.splitlines()
                     if l.startswith("+") and not l.startswith("+++"))


def extract_entities(text):
    found = {}
    for label, rx, gi in EXTRACTORS:
        for m in rx.finditer(text):
            found.setdefault(m.group(gi), label)
    return found


def _is_known(tok, allow_lower, scrub_regexes):
    low = tok.lower()
    if low in BUILTIN_SAFE or low in allow_lower:
        return True
    if re.match(r"^(?:[a-z0-9-]+\.)+[a-z]{2,}$", low):
        labels = low.split(".")[:-1]
        if labels and all(l in BUILTIN_SAFE or l in allow_lower for l in labels):
            return True
    words = re.split(r"[ -]", low)
    if words and all(w in BUILTIN_SAFE or w in allow_lower for w in words):
        return True
    if words and words[0] in STOP_LEADERS:
        return True
    for rx in scrub_regexes:
        if rx.search(tok):
            return True
    return False


def find_grays(text, allow_lower, scrub_regexes):
    """All entity tokens that are neither white nor black → grays."""
    grays = {}
    for tok, label in extract_entities(text).items():
        if not _is_known(tok, allow_lower, scrub_regexes):
            grays.setdefault(tok, label)
    return grays


def _compile_scrub(patterns):
    out = []
    for p in patterns:
        try:
            out.append(re.compile(p, re.I))
        except re.error:
            out.append(re.compile(re.escape(p), re.I))
    return out


def promote(term, to):
    if to not in ("scrub", "allow"):
        print(f"entity-advisory: --to must be 'scrub' or 'allow', got {to!r}", file=sys.stderr)
        return 2
    target = SCRUBLIST if to == "scrub" else ALLOWLIST
    _remove_line(GRAYLIST, term)
    added = _append_line(target, term)
    dest = "scrublist (BLACK)" if to == "scrub" else "allowlist (WHITE)"
    print(f"entity-advisory: promoted '{term}' → {dest}"
          + ("" if added else " (already present)"))
    return 0


def run(range_=None, staged=False, files=None, strict=False, record=False):
    allow_lower = {a.lower() for a in _read_lines(ALLOWLIST)}
    scrub_regexes = _compile_scrub(_read_lines(SCRUBLIST))
    pending = set(_read_lines(GRAYLIST))

    grays = find_grays(_added_text(range_, staged, files), allow_lower, scrub_regexes)
    new_grays = {t: l for t, l in grays.items() if t not in pending}
    seen_again = [t for t in grays if t in pending]

    if not new_grays:
        msg = "entity-advisory: no new entity-like names. ✓"
        if seen_again:
            msg += f" ({len(seen_again)} pending gray(s) still unpromoted)"
        print(msg)
        return 0

    total = len(new_grays)
    print(f"entity-advisory: {total} NEW gray(s) — entity-like names in neither list.")
    print("Triage each: PROMOTE to black (identifying) or white (safe).")
    print(f"  scrub:  entity-advisory.py --promote '<term>' --to scrub   # → {SCRUBLIST}")
    print(f"  allow:  entity-advisory.py --promote '<term>' --to allow   # → {ALLOWLIST}\n")
    by_label = {}
    for tok, label in new_grays.items():
        by_label.setdefault(label, set()).add(tok)
    for label in sorted(by_label):
        print(f"  [{label}]")
        for tok in sorted(by_label[label]):
            print(f"    {tok}")
    if record:
        n = sum(1 for t in new_grays if _append_line(GRAYLIST, t))
        print(f"\nrecorded {n} new gray(s) to {GRAYLIST} (won't re-nag until promoted)")
    if seen_again:
        print(f"\n(+{len(seen_again)} pending gray(s) from earlier, still unpromoted)")
    print("\n(advisory — not blocking" + ("" if strict else "; --strict makes it fail)"))
    return 1 if strict else 0


# ── self-test ────────────────────────────────────────────────────────────────
def _self_test():
    import tempfile
    allow = {"acme"}
    scrub = _compile_scrub(["Vantage", r"\bEY\b"])
    text = ("We deployed for Catalyst Athletics using GitHub and Python. "
            "The BrightSign player talked to acme.com and vantage. "
            "User UPSTREAMACCTS\\SFRANC8 on host ZT-6XFDGB4. Casper Launchpad Labs. "
            "This Section covers ADR and SDLC. EY reviewed it.")
    grays = find_grays(text, allow, scrub)
    flat = set(grays)
    assert "Catalyst Athletics" in flat, flat
    assert "BrightSign" in flat, flat
    assert any("Launchpad Labs" in t for t in flat), flat
    assert "ZT-6XFDGB4" in flat, flat
    assert any("SFRANC8" in t for t in flat), flat
    assert "GitHub" not in flat and "Python" not in flat, flat
    assert "acme.com" not in flat, "allowlisted domain leaked"
    assert not any(t.lower() == "vantage" for t in flat), flat
    assert "EY" not in flat, "scrublisted acronym leaked"
    assert "ADR" not in flat and "SDLC" not in flat, flat
    assert "The Section" not in flat and "This Section" not in flat, flat
    # promote round-trip on temp files
    global GRAYLIST, SCRUBLIST, ALLOWLIST
    d = tempfile.mkdtemp()
    GRAYLIST = os.path.join(d, "gray"); SCRUBLIST = os.path.join(d, "scrub"); ALLOWLIST = os.path.join(d, "allow")
    _append_line(GRAYLIST, "Globex Dynamics")
    assert "Globex Dynamics" in set(_read_lines(GRAYLIST))
    promote("Globex Dynamics", "scrub")
    assert "Globex Dynamics" not in set(_read_lines(GRAYLIST)), "not removed from gray"
    assert "Globex Dynamics" in set(_read_lines(SCRUBLIST)), "not added to scrub"
    print("entity-advisory self-test: OK")
    return 0


def main(argv):
    if "--self-test" in argv:
        return _self_test()
    if "--promote" in argv:
        term = argv[argv.index("--promote") + 1]
        to = argv[argv.index("--to") + 1] if "--to" in argv else None
        return promote(term, to)
    if "--list-gray" in argv:
        grays = _read_lines(GRAYLIST)
        print("\n".join(grays) if grays else "(graylist empty)")
        return 0
    strict = "--strict" in argv
    staged = "--staged" in argv
    record = "--record" in argv
    range_ = argv[argv.index("--range") + 1] if "--range" in argv else None
    files = argv[argv.index("--files") + 1:] if "--files" in argv else None
    return run(range_=range_, staged=staged, files=files, strict=strict, record=record)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
