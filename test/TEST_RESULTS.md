# Test Results — Engineer System v3.3 (post-improvements)

**Date:** 2026-05-19
**Fixture:** `test/SampleModule` — minimal PowerShell module with public function, Pester tests, and manifest.

## Test matrix

| # | Scenario | Result | Evidence |
|---|----------|:------:|----------|
| 1 | `install-eng -Mode DryRun` on empty target | ✅ PASS | 29 files would be created, no writes |
| 2 | `install-eng -Mode Install` on empty target | ✅ PASS | 29 files created, Node detected (v26.1.0), Claude Code detected |
| 3 | Smoke test inside installed target (10 patterns) | ✅ PASS | 10/10 pre-bash patterns: 5 benign allow, 5 dangerous block (exit 2) |
| 4 | `session-start.mjs` runs in target, injects PROJECT_MAP | ✅ PASS | Full project map content + git context emitted to stdout |
| 5 | `validator` reads `project.json`, runs real Pester | ✅ PASS | 5/5 Pester tests passed, exit 0, transcript captured |
| 6 | `install-eng -Mode Upgrade` after user customized CLAUDE.local.md | ✅ PASS | `CLAUDE.local.md` + `project.json` protected (2 skipped, 27 updated, 0 created) |
| 7 | `.gitignore` auto-created on first git repo install | ✅ PASS | Contains `.claude/.session-edits.log*` + `CLAUDE.local.md` |
| 8 | Claude Code (VS Code) auto-reads `CLAUDE.local.md` | ✅ PASS | Both `CLAUDE.md` and `CLAUDE.local.md` were injected into Claude's context by the harness |
| 9 | DryRun no longer emits false-positive "hooks missing" warning | ✅ PASS | After Bug #1 fix |
| 10 | `pre-bash.mjs` blocks new v3.2 patterns (docker prune, kubectl ns) | ✅ PASS | Both blocked at runtime when invoked via Bash tool |

## Bugs found and fixed

### Bug #1 — DryRun false-positive warning on Hooks check

- **Symptom:** Running `install-eng -Mode DryRun` on an empty target emitted `⚠ مجلد hooks غير موجود — تخطي`
- **Cause:** `Test-HooksInstalled` ran the check unconditionally; DryRun never copies files, so the hooks dir doesn't exist yet
- **Fix:** Short-circuit at start of `Test-HooksInstalled` when `$script:DryRun -eq $true`
- **Status:** ✅ Fixed in `installer/Install-EngineerSystem.ps1` — DryRun now prints `(DryRun) تخطي فحص hooks — لم يُكتب شيء فعلياً`

### Bug #2 — pre-bash false-positive on commit messages containing SQL keywords

- **Symptom:** `git commit -m "fix: handle DROP DATABASE on shutdown"` was BLOCKED by pre-bash hook
- **Cause:** SQL patterns matched any substring; a commit message mentioning the word triggered the block
- **Fix:** SQL patterns now require a DB-client context on the same command line (`psql`, `mysql`, `sqlite3`, `mongo`, `cqlsh`, etc.). Pure substring matches no longer trigger.
- **Status:** ✅ Fixed in `.claude/hooks/pre-bash.mjs`. Regression test added to `__smoke-test.mjs` — now 11/11 PASS.
- **Discovered when:** Trying to commit v3.3.1 with this very release notes file — eating our own dog food.

## Notes

- No edge case revealed a fundamental architectural issue.
- `/bootstrap` was simulated (Phase 1-4) manually since invoking a slash command from inside a slash-command context is not possible. The simulation validated the inputs/outputs would work; live testing happens the next time the user runs `/bootstrap` in a real session.
- `/scout` and `github-research` skill are similarly untested at runtime — they depend on `staff-engineer` with WebFetch/WebSearch which is a live-session-only path.
- `/update` is untested because it would actually pull from GitHub and modify the source on disk; defer to first real use.

## Recommendation

v3.3.1 is production-ready for `install-eng` + Pester-style validator flows. The bootstrap/scout/update flows are designed and code-complete but await first real-world session for runtime validation.
