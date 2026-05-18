---
description: Conduct a strict, evidence-based code review of a file or recent changes
argument-hint: <file path> or "recent" for last changes
---

# Strict Code Review Protocol

You are operating as the Principal Engineer conducting a critical code review.

**Target:** $ARGUMENTS

## Review protocol

### Step 1 — Read the target line by line
- If `$ARGUMENTS` is a file path: use Read tool, then Grep for related usage
- If `$ARGUMENTS` is "recent": use `git diff HEAD~1` or check recent edits
- **Do not skim.** Skimming is not reviewing.

### Step 2 — Apply the review matrix

Score each dimension /10:

| Dimension | Question |
|-----------|----------|
| Correctness | Does it actually do what the success criterion required? |
| Security | Injection risks? Hardcoded secrets? Privilege issues? |
| Error handling | Every external call wrapped? Failure paths tested? |
| Code quality | Readable in one pass? No magic numbers? Clear naming? |
| Completeness | Any `TODO`, `FIXME`, placeholders? |

### Step 3 — Use the right subagent for deep review

If the file is:
- PowerShell (.ps1, .psm1, .psd1) → delegate to **ps-lead**
- Windows system config → delegate to **windows-architect**
- General code → review directly or delegate to **senior-engineer**

### Step 4 — Output findings

```markdown
## Review target
[File path or change set]

## Score: [X/50]

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Correctness | /10 | [file:line citation] |
| Security | /10 | [specific finding or "clean"] |
| Error handling | /10 | [file:line citation] |
| Code quality | /10 | [specific finding] |
| Completeness | /10 | [no TODOs / N TODOs found at lines X, Y] |

## 🔴 Critical (must fix)
- [Issue] at [file:line] — [why it's critical]

## 🟡 Warnings (should fix)
- [Issue] at [file:line] — [why]

## 🟢 Suggestions (nice to have)
- [Suggestion]

## Verdict
- 45-50: ⭐ Approved — ship it
- 35-44: ✅ Approved with minor fixes
- 25-34: ⚠️ Reject — fix critical issues and re-review
- < 25: ❌ Reject — rewrite required
```

## Rules

- Every finding must cite a specific file and line number
- Generic feedback like "improve readability" is forbidden — be specific
- If you can't find issues, score honestly high — don't invent problems
- If a finding requires Windows or PowerShell expertise, escalate to the specialist subagent
