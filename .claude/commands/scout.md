---
description: Scout GitHub for production-quality projects similar to the current project (or a specified domain). Returns a curated list with stars, last commit, and key takeaways.
argument-hint: (optional) domain or stack to scout, e.g. "PowerShell module testing" or "React state management"
---

# /scout — GitHub Reconnaissance

You are the Principal Engineer. Delegate to `staff-engineer` to scout GitHub.

**Target:** `$ARGUMENTS` (if empty, infer from `memory/PROJECT_MAP.md` `[PROJECT_IDENTITY]` + `.claude/project.json`)

## Protocol

1. **Determine the domain.** If $ARGUMENTS empty:
   - Read `memory/PROJECT_MAP.md` for project identity
   - Read `.claude/project.json` for language/framework
   - Synthesize the domain (e.g. "Windows hardening + PowerShell modules")
   - If still ambiguous, ask the user before scouting

2. **Invoke `staff-engineer`** with this prompt:

   ```text
   Scout GitHub for top production-quality projects in the domain: <DOMAIN>.

   Use the `github-research` skill for methodology. Specifically:
   - Search by topic, stars, last commit (must be active in last 12 months)
   - Verify each result by WebFetch on the repo page (don't trust search snippets)
   - Pick 5 distinct approaches (not 5 forks of the same idea)
   - For each: URL, stars (verified), last commit date, language, one architectural takeaway, one risk/limitation
   - Avoid abandoned or low-quality repos — even if popular

   Return a markdown table + a 3-line "patterns we should consider adopting" summary.
   ```

3. **Pass through the report** to the user. Append to `memory/PROJECT_MAP.md` `[PROJECT_IDENTITY]` -> "GitHub similar projects".

4. **Suggest a follow-up:** "Want me to /plan adopting one of these patterns?"

## Refusal conditions

- $ARGUMENTS empty AND `PROJECT_MAP` empty → ask the user to run `/bootstrap` first
- Network unavailable → tell the user, don't fabricate results

## What NOT to do

- Don't cite repos from memory — they may not exist or may have been renamed
- Don't list 20 results — quality over quantity
- Don't include star counts you didn't WebFetch — claims must be verifiable
