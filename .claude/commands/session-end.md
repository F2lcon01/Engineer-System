---
description: Update PROJECT_MAP.md with session work, cost tracking, and plan-adherence score
---

# Session End Protocol v3.1

Execute this protocol to close the session cleanly. **Do not skip steps.**

## Step 1 — Read current state

```
Read memory/PROJECT_MAP.md fully
Run `date` in bash for the current timestamp
Identify what was accomplished this session
```

## Step 2 — Calculate the three metrics

### A. Score /50 (5 dimensions, 10 points each)
- Success criterion met
- Security and stability
- Code quality and organization
- Completeness of deliverable
- Adherence to constraints

### B. Plan-Adherence /10 (NEW)
How closely did execution match the original `/plan`?
- **10**: Executed exactly as planned
- **7-9**: Minor documented deviations
- **4-6**: Significant deviations, partially justified
- **0-3**: Plan abandoned mid-execution

### C. Cost-of-Pass (NEW)
- Subagent invocations count
- Approximate token usage (Claude Code shows running total)
- Wall-clock time (first to last message)
- Dollar estimate using current rates

If task was retried, **cost includes all retries**.

## Step 3 — Update PROJECT_MAP.md

### Standard sections (TECH_STACK, ARCHITECTURE, etc.)
Update as before.

### Append to [SESSIONS_LOG] with new metric fields

```markdown
### Session [N]
- **Date:** [from `date`]
- **Task:** [description]
- **Subagents invoked:** [list]
- **Outcome:**
  - Completed: [list]
  - Blocked: [list with reason]
- **Metrics:**
  - Score: [X/50]
  - Plan-adherence: [X/10]
  - Cost: [N calls, ~T tokens, ~$X]
- **Files modified:** [list]
- **Lessons:** [what would you do differently?]
```

### Update [COST_LEDGER] (create if absent)

```markdown
## [COST_LEDGER]

| Session | Date | Score | Adherence | Tokens | Cost $ | $/point |
|---------|------|-------|-----------|--------|--------|---------|
| 14 | 2026-05-18 | 47 | 9 | 18,500 | $0.058 | $0.0012 |
```

**The $/point column reveals which sessions delivered best value.**

## Step 4 — Session summary for the user

```markdown
## Session Summary

### Accomplished
- [Task: outcome]

### Metrics
- Score: [X/50] [⭐/✅/⚠️/❌]
- Plan-adherence: [X/10]
- Cost: ~$[X] for [N] calls

### Value vs history
- This session: $[X]/point
- Your average: $[Y]/point  ← from COST_LEDGER
- Verdict: [better than average / typical / expensive]

### Remaining
- [Pending items]

### Next session recommended
[Specific task]
```

## Step 5 — Final verification

Before ending:
- ✅ PROJECT_MAP.md actually edited (Read to verify)
- ✅ Real date (not placeholder)
- ✅ All three metrics honest (not optimistic)
- ✅ COST_LEDGER updated
- ✅ Pending items specific enough to resume
