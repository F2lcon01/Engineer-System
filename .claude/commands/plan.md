---
description: Analyze task, propose subagent, and trigger plan-reviewer gate for M/L tasks
argument-hint: <task description>
---

# Task Planning Protocol v3.1

Operating as Principal Engineer. Task: **$ARGUMENTS**

## Execute in order:

### Step 1 — Size classification

| Size | Definition | Decision |
|------|------------|----------|
| XS | Single question / trivial edit | Answer directly, no subagent, no review |
| S | Single scope, 1-2 files | One subagent + optional code-reviewer |
| M | 2+ scopes or dependencies | **plan-reviewer required** + executor + code-reviewer |
| L | Multi-component | **plan-reviewer required** + multiple executors + code-reviewer per stage |

### Step 2 — Subagent selection

Match to subagent description:
- **staff-engineer** → research, comparison, investigation
- **senior-engineer** → implementation, bug fix, refactor
- **windows-architect** → Registry, services, deployment
- **ps-lead** → PowerShell module, automation

### Step 3 — Write the success criterion

A **single testable sentence**:
- ❌ Vague: "Make the system better"
- ✅ Testable: "Module exports `Get-TelemetryStatus` returning `$true` when 4 telemetry services disabled, verified by Pester test"

### Step 4 — Estimate cost

Quick mental model:
- 1 subagent call ≈ 5-15K tokens
- Opus calls ≈ 5× Sonnet cost
- Each retry adds full cost

State the estimate upfront. The user should know before approving.

### Step 5 — Output the plan

```markdown
## Task analysis
[Restated in your own words]

## Size: [XS/S/M/L]

## Subagent(s)
1. [name] — for [sub-task]

## Execution order
[Parallel / Sequential]

## Success criterion (testable)
[One sentence]

## Cost estimate
~$[X] across [N] subagent calls
[State which model each will use: Opus/Sonnet/Haiku]

## Open questions (if any)
[Ask before proceeding]

## Next gate
- If Size = M/L: invoking plan-reviewer for approval
- If Size = S/XS: ready for direct execution (your confirm to proceed)
```

### Step 6 — Trigger plan-reviewer for M/L

If size is **M or L**, **immediately** invoke `plan-reviewer` subagent via Task tool to review the plan.

Pass the full plan as context. Wait for the review verdict before proceeding.

The plan-reviewer will return:
- **APPROVED** → proceed to delegation
- **REJECTED** → revise plan and re-review (max 2 cycles before escalating to user)
- **APPROVED WITH CHANGES** → adopt suggested changes, then proceed

### Step 7 — Wait for user confirmation

Even after plan-reviewer approval, **wait for the user** to say "proceed" or equivalent before invoking executors.

This prevents runaway agent loops on misunderstood tasks.
