---
description: Update PROJECT_MAP.md with session work — clean, focused, no fake metrics
---

# Session End Protocol v3.3

Execute this protocol to close the session cleanly. **Do not skip steps.**

## Step 1 — Read current state

- Read `memory/PROJECT_MAP.md` fully
- Run `date` to get the current timestamp
- Identify what was actually accomplished this session (look at `.claude/.session-edits.log`)

## Step 2 — Score the session honestly (one number)

Single quality score **/50** across 5 dimensions:

- Success criterion met
- Security and stability
- Code quality and organization
- Completeness of deliverable
- Adherence to constraints

That's it. No fake adherence-percentages, no token-guessing.
If you want the real token cost, run the `/cost` slash command yourself.

## Step 3 — Update PROJECT_MAP.md

### Standard sections (TECH_STACK, ARCHITECTURE, PENDING/DONE)

Update with anything learned this session. Move completed items from PENDING to DONE.

### Append to [SESSIONS_LOG]

```markdown
### Session [N]
- **Date:** [from `date`]
- **Task:** [description]
- **Subagents invoked:** [list]
- **Outcome:**
  - Completed: [list]
  - Blocked: [list with reason]
- **Files modified:** [from .claude/.session-edits.log]
- **Score:** [X/50]
- **Lessons:** [what would you do differently?]
```

### Update [KNOWN_ISSUES] if any surfaced

## Step 4 — Session summary for the user

```markdown
## Session Summary

### Accomplished
- [Task: outcome]

### Score
- [X/50] [⭐ / ✅ / ⚠️ / ❌]

### Remaining
- [Pending items]

### Next session recommended
[Specific task]
```

## Step 5 — Final verification

Before ending:

- ✅ `PROJECT_MAP.md` actually edited (Read to verify)
- ✅ Real date (not placeholder)
- ✅ Score honest (not optimistic)
- ✅ Pending items specific enough to resume
