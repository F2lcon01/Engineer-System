---
name: github-research
description: Methodology for scouting GitHub for production-quality projects in a given domain. Loaded by staff-engineer when researching prior art, similar projects, or competitive landscape. Provides verified search patterns, quality filters, and citation discipline. Use before recommending any external project or pattern.
---

# GitHub Research Skill

This skill activates when scouting GitHub for similar projects or prior art. Read it **before** issuing any "use project X" recommendation.

## The Three Laws of GitHub Scouting

1. **Verify, don't trust search snippets** — WebFetch the repo page itself; stars and dates from search results lag and lie.
2. **Active beats popular** — a 20k-star repo with last commit 18 months ago is worse than a 2k-star repo updated last week.
3. **Diversity beats density** — 5 different architectural approaches > 5 forks of the same idea.

## Search query patterns (use multiple)

For a domain like "PowerShell module testing":

```text
1. WebSearch: site:github.com "PowerShell" "Pester" stars:>500
2. WebSearch: github topics page for the language/framework
3. WebSearch: "awesome <language>" curated lists for hand-picked recommendations
4. WebSearch: explicit pattern like "PowerShell DSC module" if domain has a known term
```

For each promising result, **WebFetch the GitHub repo page** and extract:

- Star count (current, not cached)
- Last commit date (must be visible on the repo page)
- Primary language %
- Number of open issues / PRs (activity proxy)
- License (avoid proprietary)
- README first 50 lines (architectural summary)

## Quality filters — reject if

| Filter | Why |
|--------|-----|
| Last commit > 12 months ago | Likely abandoned |
| < 100 stars AND last commit > 6 months | Hobby project, low survival probability |
| README is just badges with no content | Quality signal absent |
| Open issues > 5x recent commits | Maintainer overwhelmed |
| No license file | Cannot legally adopt patterns |
| Single contributor + < 50 stars | Bus-factor of 1 |

## Output structure (mandatory)

```markdown
## GitHub scout report — domain: <domain>

| # | Repo | Stars | Last commit | Language | Takeaway | Risk |
|---|------|-------|-------------|----------|----------|------|
| 1 | [owner/repo](url) | 12.3k ⭐ | 2026-04-15 | PowerShell | Uses Pester 5 nested Describe blocks for cross-module integration tests | Heavy mock setup — boilerplate-heavy |
| 2 | ... | ... | ... | ... | ... | ... |

## Patterns worth adopting
1. [Specific pattern from result #N, with file:line citation if you fetched README/source]
2. ...

## Patterns to avoid (negative findings)
1. [Anti-pattern observed in 2+ projects, with which]

## Verified date: YYYY-MM-DD
```

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Citing repos from memory | NEVER. Always WebSearch + WebFetch fresh. |
| Listing every search hit | Filter aggressively — top 5 max. |
| Generic takeaways ("good code structure") | Cite the specific pattern with file/line or commit SHA. |
| Ignoring license | If MIT/Apache/BSD: adoptable. If GPL/AGPL: warn the user before adopting. |
| Star count without WebFetch | Search results lag — always verify on repo page. |

## When NOT to scout

- If the user asked a XS question, skip — overkill.
- If domain is too niche (no comparable projects exist) → say so honestly, don't pad with unrelated repos.
- If under deadline → cap at 3 results, not 5.

## Integration with /bootstrap and /scout

- `/bootstrap` calls staff-engineer once for a quick 3-result scout to seed PROJECT_MAP
- `/scout [domain]` calls staff-engineer for a full 5-result deep scout on demand
- Both rely on this skill being read first by staff-engineer
