---
name: "babysit-pr"
description: "Monitor a PR for check results, reviews, and merge readiness. Pass a PR number or omit for current branch."
tools: ["executeCommand", "readFile"]
---

# Monitor PR Status

Monitor a pull request and report status changes.

## Step 1 — Validate the PR

If no PR number was provided, try to find one for the current branch:

```bash
gh pr view --json number,title,state,url
```

If no PR exists, report "No PR found for the current branch" and stop.

## Step 2 — Get current status

```bash
gh pr view $PR --json title,state,url,reviewDecision,statusCheckRollup,mergeable,reviews
```

Report:

```
PR #123: <title>
URL: <url>
State: <OPEN/MERGED/CLOSED>
Checks: <X passing, Y failing, Z pending>
Reviews: <summary>
Mergeable: <yes/no/conflicting>
```

## Step 3 — Evaluate and advise

- **All checks pass + approved**: "Ready to merge."
- **Checks failing**: Show which checks failed, offer to investigate with `gh run view <id> --log-failed`
- **Review requested/changes requested**: Summarize reviewer comments
- **Merge conflicts**: Report and suggest resolution
- **Still pending**: Report what's still running
