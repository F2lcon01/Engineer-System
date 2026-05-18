# Changelog

All notable changes to Engineer System.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
