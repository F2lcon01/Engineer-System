---
description: First-session full project scan — reads the codebase, scouts GitHub for similar projects, and auto-populates PROJECT_MAP + CLAUDE.local + project.json
argument-hint: (optional) focus area to emphasize, e.g. "security" or "performance"
---

# Bootstrap Protocol v3.3

You are the Principal Engineer running the **first real session** in a project that just had `install-eng` run.

Your job: turn a fresh install into an **understood** install. Read the project, scout GitHub, fill the brain.

**Focus argument (optional):** $ARGUMENTS

---

## Phase 1 — Project scan (full read)

Run these in parallel where possible:

1. `ls -la` of repo root and main source directories
2. Read manifest files: `package.json`, `pyproject.toml`, `*.csproj`, `*.psd1`, `requirements.txt`, `Cargo.toml`, `go.mod`, `pom.xml` — whichever exist
3. Read `README.md` (root)
4. Glob for entry points: `src/**/index.*`, `src/**/main.*`, `*.psm1`, `app.py`, `Program.cs`
5. Read the largest 3-5 source files (use `Glob` + size, pick the meatiest)
6. `git log --oneline -20` for recent history
7. Read any existing `CONTRIBUTING.md`, `ARCHITECTURE.md`, or docs

**Budget:** ~30-50K tokens of project reading. The user authorized full read in the v3.3 design.

## Phase 2 — Detect project type and commands

Identify:

| Field | How |
|-------|-----|
| Primary language | File extensions + manifest |
| Framework | Manifest dependencies (react, django, .net, etc.) |
| Test command | Manifest scripts / convention (Pester for PS, npm test, pytest, dotnet test) |
| Lint command | Manifest / convention |
| Build command | Manifest / convention |

## Phase 3 — GitHub scout (via staff-engineer)

Invoke `staff-engineer` with this prompt:

```text
Scout GitHub for 3-5 production-quality projects in the same domain as <DETECTED_DOMAIN> using <DETECTED_LANGUAGE>. For each return:
- Repo URL
- Stars + last commit date
- One sentence on the key architectural pattern they use
- One sentence on what we can learn from them
Use the github-research skill for the methodology.
```

Wait for staff-engineer's report.

## Phase 4 — Write artifacts

### A. `.claude/project.json`

```json
{
  "name": "<detected>",
  "language": "<detected>",
  "framework": "<detected or null>",
  "test_command": "<detected or null>",
  "lint_command": "<detected or null>",
  "build_command": "<detected or null>",
  "entry_points": ["<list>"],
  "bootstrapped_at": "<ISO date>"
}
```

### B. `memory/PROJECT_MAP.md`

Fill these sections (preserve any existing user content):

- `[PROJECT_IDENTITY]` — name, purpose, stack, entry points, GitHub similar top 3
- `[TECH_STACK]` — tools + versions (verify versions from manifest only — don't invent)
- `[ARCHITECTURE]` — first 2-3 obvious architectural decisions detected
- `[SYSTEM_FLOW]` — one-paragraph data/user flow

### C. `CLAUDE.local.md`

Fill `## هوية المشروع` section. Leave preferences for the user to fill.

## Phase 5 — Report to user

```markdown
## /bootstrap complete

### Detected
- Language: <X>
- Framework: <Y>
- Test command: <Z>

### GitHub scouted
1. [project] — <star count> ⭐ — <takeaway>
2. ...

### Files written
- .claude/project.json
- memory/PROJECT_MAP.md (sections filled: ...)
- CLAUDE.local.md (identity filled)

### Next step
Edit CLAUDE.local.md "التفضيلات" if you want to set commit-message style or note files-not-to-touch.

Then start working with /plan <task>.
```

## Self-check before finishing

- ✅ Did I actually read source files, or just manifests?
- ✅ Did I run staff-engineer for GitHub scout, or skip it?
- ✅ Are `test_command`/`lint_command` real (in manifest), not invented?
- ✅ Did I preserve existing PROJECT_MAP content or overwrite blindly?
- ✅ Did I cite GitHub URLs with verified star counts (not guessed)?

## Refusal conditions

- Empty repo (no source files) → tell the user and skip phases 2-4
- Multi-language monorepo with no clear primary → ask the user which to focus on
- Network unavailable for GitHub scout → finish phases 1-2-4 and note the gap
