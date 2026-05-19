# Changelog

All notable changes to Engineer System.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.4.0-alpha] - 2026-05-19

### Added — Claude Code Plugin distribution (alpha)

- **`.claude-plugin/plugin.json`** — official Claude Code plugin manifest (name, version, author, repo, license, keywords)
- **`.claude-plugin/marketplace.json`** — single-plugin marketplace catalog so users can install via `/plugin marketplace add F2lcon01/Engineer-System` + `/plugin install engineer-system@engineer-system-marketplace`
- **`installer/Build-Plugin.ps1`** — generates plugin layout (`agents/`, `commands/`, `skills/`, `scripts/`, `hooks/hooks.json`) from the canonical `.claude/` source. Supports `-Check` mode for CI (exit 1 on drift).
- **Generated plugin layout at repo root:**
  - `agents/` (7 files) — mirrors `.claude/agents/`
  - `commands/` (6 files) — mirrors `.claude/commands/`
  - `skills/` (6 files) — mirrors `.claude/skills/`
  - `scripts/` (4 files) — mirrors `.claude/hooks/*.mjs` (excluding `__smoke-test.mjs`)
  - `hooks/hooks.json` — invokes scripts via `${CLAUDE_PLUGIN_ROOT}/scripts/*.mjs`
- **README install section** restructured: Plugin (Method 1) + Installer (Method 2), with a comparison table.

### Why hybrid (plugin + installer)?

Plugin system distributes shared components (agents, hooks, skills, commands) — but **`CLAUDE.md`, `CLAUDE.local.md`, `memory/PROJECT_MAP.md`, `.claude/project.json` are project-scoped**. A plugin cannot place files in the user's project. The installer remains the only way to seed those. The two methods complement each other.

### Notes

- Alpha status: plugin layout works but full `/plugin install` flow untested in a real session. The `Build-Plugin.ps1 -Check` regression test guards against `.claude/` ↔ plugin paths drift going forward.
- Slash commands installed via plugin get a namespace prefix: `/engineer-system:plan` (vs `/plan` via installer). This is per Claude Code plugin spec — not a bug.
- `.claude/` remains the canonical source of truth in this repo (used for self-dogfooding while developing). Run `Build-Plugin.ps1` after any change to `.claude/` to refresh plugin paths.

## [3.3.1] - 2026-05-19

### Added

- **`/update` slash command** — pulls latest source from GitHub and re-runs `install-eng -Mode Upgrade` on the current project. One command instead of four.
- **3 new skills:**
  - `nodejs-testing` — vitest/jest/node:test patterns with mocking, async, fake timers
  - `python-testing` — pytest fixtures, parametrize, monkeypatch, async with pytest-asyncio
  - `git-conventions` — Conventional Commits detection + branch naming + footer rules
- **Releases workflow documentation** in `README.md` (commit → tag → `gh release create`)
- **`test/SampleModule/`** — a real PowerShell module fixture used to e2e-test `install-eng` (Install/Upgrade/DryRun) + the validator running real Pester
- **`test/TEST_RESULTS.md`** — 10-scenario test matrix with evidence

### Fixed

- **Installer Bug #1:** DryRun mode emitted a false-positive `مجلد hooks غير موجود` warning because `Test-HooksInstalled` ran before any files were written. Now short-circuits when `$script:DryRun -eq $true`.
- **pre-bash Bug #2:** SQL data-loss patterns matched any substring (so a git commit message mentioning `DROP DATABASE` was blocked). Now requires a DB-client context (`psql`/`mysql`/`sqlite3`/`mongo`/`cqlsh`) on the same command line. Regression test added to `__smoke-test.mjs` (now 11/11 instead of 10/10).

### Verified (end-to-end testing)

- ✅ `install-eng` Install/Upgrade/DryRun on a real PowerShell module
- ✅ `CLAUDE.local.md` and `.claude/project.json` protected on Upgrade
- ✅ `validator` reads `project.json` and runs real Pester (5/5 tests pass)
- ✅ Both `CLAUDE.md` and `CLAUDE.local.md` auto-injected into Claude Code's context
- ✅ pre-bash hook blocks the 5 dangerous patterns (incl. new v3.2 docker/kubectl) and allows the 5 benign ones

## [3.3.0] - 2026-05-19

### ⚠️ BREAKING

- **`CLAUDE.md` split into `CLAUDE.md` (immutable system) + `CLAUDE.local.md` (per-project, gitignored).** On upgrade, `CLAUDE.md` is now always refreshed (no more "is this customization or system?" ambiguity). Move your project-specific notes from old `CLAUDE.md` into `CLAUDE.local.md` after upgrade.
- **COST_LEDGER and Plan-Adherence /10 removed from `/session-end` and `PROJECT_MAP.md`.** They were aspirational metrics that depended on data Claude Code does not expose reliably. `/session-end` now records a single honest Score /50. Existing `[COST_LEDGER]` entries in your PROJECT_MAP can stay as historical record — the template no longer creates the section.

### Added

- **`/bootstrap` slash command** — first-session full project scan. Reads source, manifests, README, git history. Then invokes `staff-engineer` to scout GitHub for 3-5 similar projects. Writes `.claude/project.json`, fills `memory/PROJECT_MAP.md` sections (`[PROJECT_IDENTITY]`, `[TECH_STACK]`, `[ARCHITECTURE]`, `[SYSTEM_FLOW]`), and seeds `CLAUDE.local.md`. This is the "one-command → smart" promise made real.
- **`/scout [domain]` slash command** — on-demand GitHub reconnaissance. Returns 5 verified production-quality projects with stars, last commit, language, takeaway, and risk. Uses `github-research` skill for methodology.
- **`github-research` skill** — methodology for scouting GitHub: search patterns, quality filters (12-month freshness, license check, bus-factor signals), citation discipline (WebFetch each repo, never trust search snippets). Loaded by `staff-engineer` and the `/scout` command.
- **`.claude/project.json`** — machine-readable project metadata (language, framework, test/lint/build commands, entry points). Written by `/bootstrap`, **read by `validator`** so it stops guessing commands.
- **`CLAUDE.local.md`** — per-project notes file. Always protected on upgrade, gitignored by default, auto-read by Claude Code alongside `CLAUDE.md`.
- **`memory/PROJECT_MAP.md` new section `[PROJECT_IDENTITY]`** — replaces the manual-fill awkwardness of v3.2.

### Changed

- `validator` agent now reads `.claude/project.json` first; falls back to manifest detection only if commands are absent. Refuses to invent a command.
- `staff-engineer` agent points to `github-research` skill for GitHub scouting tasks (no more improvised searches).
- Installer:
  - `CLAUDE.md` is now always overwritten on upgrade (it's pure system).
  - `CLAUDE.local.md` is protected if exists, seeded from source template if missing.
  - `.claude/project.json` is protected if it has user data.
  - `.session-edits.log` and its rotated `.old` variant are never copied.
  - `.gitignore` updated to add `CLAUDE.local.md` and `.claude/.session-edits.log.old`.
  - Post-install hint replaced — now suggests `/bootstrap` as the first step instead of "edit CLAUDE.md context section."
- `/session-end` simplified: one Score /50, no fake adherence/cost metrics.

### Removed

- `[COST_LEDGER]` section from `memory/PROJECT_MAP.md` template (it's gone for new installs; existing PROJECT_MAPs keep their data).
- Plan-Adherence /10 metric (was subjective, low signal).
- "Cost-of-Pass" $/point insight (Claude Code lacks reliable per-session token reporting).

## [3.2.0] - 2026-05-19

### ⚠️ BREAKING

- **Project scope narrowed to Windows + Claude Code for VS Code extension.** Linux/macOS sections removed from README, `installer/install.sh` is now deprecated (deletion candidate for v3.3).
- **Hooks migrated from bash (`.sh`) to Node.js (`.mjs`)**. Old `.claude/hooks/*.sh` files are no longer referenced. Delete them after upgrade.
- **`node` (v18+) is now a hard runtime requirement** for hooks. It was already required by Claude Code itself, so this should affect no one in practice.
- **`code-reviewer` lost the `Bash` tool** — it is strictly read-only now. Execution of tests/lint moved to the new `validator` agent.
- **`plan-reviewer` model changed from `opus` to `sonnet`** by default. Override in the frontmatter if you handle architecture-critical reviews and want Opus.

### Added

- `validator` subagent (Haiku) — runs the actual command that proves the success criterion (Pester / npm / pytest / build), captures exit code + transcript, returns PASS/FAIL. Distinct from code-reviewer (inspector).
- Node hooks: `session-start.mjs`, `pre-bash.mjs`, `post-edit.mjs`, `stop-reminder.mjs`.
- `.gitattributes` extended to cover `.mjs/.js/.cjs` with LF.
- Installer (PS1 + Bash) now probes Node.js version and warns if `< 18` or missing.
- Installer warns when legacy `.sh` hooks are detected and shows the exact remove command.
- `pre-bash.mjs` expanded pattern catalog: now blocks ~20 destructive families including `rm --no-preserve-root`, `chown -R … /`, `git reset --hard HEAD~`, force-delete of protected branches, `git clean` at root, `TRUNCATE TABLE`, `docker system prune -a`, `kubectl delete ns/all`, and `curl|wget piped into a shell`.

### Fixed

- **Security: pre-bash bypass via shell escaping.** v3.1 extracted `$.tool_input.command` via `grep` on the raw JSON, which broke on escaped quotes and allowed nested commands to slip past the pattern list. v3.2 uses `JSON.parse` on stdin.
- **Compatibility: Windows + WSL hook hang.** v3.1 `.sh` hooks resolved `bash` to `C:\Windows\System32\bash.exe` (WSL stub) on Windows machines that had WSL installed (common with Docker Desktop), which froze the TUI. v3.2 has no bash dependency.
- **Stability: log unbounded growth.** `post-edit` now rotates `.session-edits.log` at 256 KB to `.session-edits.log.old`.
- **Hygiene: Stop-hook count is meaningful.** Reminder now reports unique edited files, not raw event lines.

### Changed

- README: removed fabricated session metrics (`Score 47/50 | $/pt $0.0012` were illustrative not measured — relabeled explicitly).
- README: comparison table updated with verified competitor file/agent counts (wshobson ~185, VoltAgent ~131).
- Roadmap: validator moved from v3.2 (promised) to v3.2 (delivered).

### Removed (deprecated)

- `.claude/hooks/*.sh` — no longer invoked by `settings.json`. Will be deleted in v3.3.

## [3.1.0] - 2026-05-18

### Added
- `plan-reviewer` subagent - reviews plans before execution to catch errors early
- `code-reviewer` subagent - independently verifies contracts after implementation
- `windows-registry` skill - safe Registry modification patterns
- `pester-testing` skill - production Pester 5+ test patterns
- Plan-Adherence /10 metric in session-end
- Cost-of-Pass tracking with $/point insight
- COST_LEDGER section in PROJECT_MAP.md template
- Setup-EngineerSystem.ps1 for clean ZIP-based installation
- Verify-EngineerSystem.ps1 for installation validation

### Changed
- /plan command now auto-invokes plan-reviewer for M/L tasks
- /session-end now calculates three metrics instead of one
- CLAUDE.md updated to describe two-gate workflow

### Architecture
- Skills introduced as progressive-disclosure pattern
- Reviewers separated from executors for independent verification

## [3.0.0] - 2026-05-17

### Added
- Real subagents with YAML frontmatter in `.claude/agents/`
- 4 hooks (SessionStart, PreToolUse, PostToolUse, Stop)
- 3 slash commands (plan, review, session-end)
- PROJECT_MAP.md as external memory injected via SessionStart hook
- PowerShell installer (Install-EngineerSystem.ps1) with Install/Upgrade/DryRun modes
- Bash installer (install.sh) for Linux/macOS/WSL
- Claude-driven installation prompt for in-session setup

### Changed
- Migrated from monolithic prompt to real Claude Code subagents
- CLAUDE.md reduced to orchestration layer (< 100 lines)

## [2.x] - Pre-public

Internal iterations. Not released.

## [1.0.0] - Initial concept

Original monolithic Principal Engineer prompt.
