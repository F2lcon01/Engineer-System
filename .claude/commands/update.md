---
description: Pull latest Engineer System from GitHub then re-run install-eng in upgrade mode on the current project
---

# /update — Sync source + upgrade current project

You are operating as Principal Engineer. This command updates the Engineer System source on disk and refreshes the current project's installation, preserving user data.

## Protocol

### Step 1 — Locate the source

The source folder is by convention at `$env:USERPROFILE\Desktop\Engineer System`. If a different path is needed, ask the user before proceeding.

Verify the source is a git repo:

```powershell
Test-Path "$env:USERPROFILE\Desktop\Engineer System\.git"
```

If false → report and stop. The source must be a clone of `F2lcon01/Engineer-System` to update.

### Step 2 — Pull the latest

```powershell
Push-Location "$env:USERPROFILE\Desktop\Engineer System"
git fetch origin
$behind = (git rev-list --count HEAD..origin/main)
if ($behind -eq 0) {
    Write-Host "Source already up to date."
    Pop-Location
    return
}
git pull --ff-only origin main
Pop-Location
```

Report what changed: show `git log <OLD>..<NEW> --oneline` so the user sees what's incoming.

### Step 3 — Upgrade the current project

```powershell
install-eng -Mode Upgrade
```

In Upgrade mode the installer protects:

- `CLAUDE.local.md`
- `memory/PROJECT_MAP.md` (if it has session data)
- `.claude/project.json` (if it has real data)

Everything else refreshes from the new source.

### Step 4 — Summarize

```markdown
## /update complete

### Source
- Pulled: <N> commits  (<OLD_SHA>..<NEW_SHA>)
- Highlights: <one line per commit, max 5>

### Project
- Files updated: <count from installer summary>
- Files protected: <count>

### Action items (if any new)
- [from CHANGELOG NEW sections]
```

## Refusal conditions

- Source path is not a git repo → tell user, do not pull
- Source has uncommitted changes → refuse pull (would lose local edits to source)
- Network unavailable → finish silently with a warning, don't fail the session
- `install-eng` function not on PATH → suggest `. $PROFILE` and stop

## What NOT to do

- Do not run `git pull` with conflicts unresolved — abort and surface to the user
- Do not run `install-eng -Force` here; user data protection is the whole point
- Do not invent commit messages — show real ones from `git log`
