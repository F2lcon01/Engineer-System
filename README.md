# Engineer System for Claude Code

> A production-grade multi-agent orchestration framework for Claude Code, built with real subagents, hooks, persistent memory, and verifiable success metrics.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Claude Code](https://img.shields.io/badge/Claude%20Code-2.1%2B-blue.svg)](https://claude.com/claude-code) [![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://learn.microsoft.com/powershell/) [![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](https://claude.ai/chat/ccacf0d6-454e-4bf6-b6b0-ee777f0d749a)

---

## What is this?

Engineer System turns Claude Code from a chat-based tool into a structured multi-agent engineering harness with:

- **6 specialized subagents** (Principal, Staff, Senior, Windows Architect, PowerShell Lead, Plan Reviewer, Code Reviewer)
- **Programmatic hooks** that enforce safety rules and inject project memory automatically
- **Persistent memory** via `PROJECT_MAP.md` that survives across sessions
- **Two-gate quality workflow** (plan review before execution, code review after)
- **Cost-of-Pass tracking** with `$/point` value metric
- **Dual installer** for Windows (PowerShell) and Linux/macOS (Bash)

Built for engineers who treat Claude Code as a serious tool, not a toy.

---

## Why this exists

Most Claude Code templates are either:

- Catalogs of 100+ subagents you'll never use, or
- Long prompts in a single `CLAUDE.md` that the model forgets mid-session

This system is different. It uses Claude Code's actual mechanisms (`.claude/agents/`, hooks, slash commands) to enforce engineering discipline programmatically — not by hope.

**Key differentiator:** Windows-first and PowerShell-aware. Most templates assume Unix; this one ships with `windows-architect` and `ps-lead` subagents that know Registry, Group Policy, Pester, and module structure.

---

## Features

### Real subagents (not just markdown prompts)

Each subagent has YAML frontmatter, runs in an isolated context window, and gets selected automatically by Claude Code based on task description.

| Subagent            | Role                               | Model  |
| ------------------- | ---------------------------------- | ------ |
| `staff-engineer`    | Research and analysis              | Sonnet |
| `senior-engineer`   | Production code implementation     | Sonnet |
| `windows-architect` | Registry, GPO, deployment          | Opus   |
| `ps-lead`           | PowerShell modules and Pester      | Sonnet |
| `plan-reviewer`     | Reviews plans before execution     | Opus   |
| `code-reviewer`     | Verifies contracts after execution | Sonnet |

### Hooks that enforce, not request

| Hook           | Trigger                   | Purpose                                               |
| -------------- | ------------------------- | ----------------------------------------------------- |
| `SessionStart` | Every new session         | Auto-inject `PROJECT_MAP.md` + git context            |
| `PreToolUse`   | Before every bash command | Block destructive patterns (`rm -rf /`, `mkfs`, etc.) |
| `PostToolUse`  | After every file edit     | Track changes for session ledger                      |
| `Stop`         | End of every turn         | Remind about `/session-end` if changes weren't logged |

### Slash commands for repeatable workflows

- `/plan <task>` — Analyzes scope, picks subagent, defines success criterion, invokes plan-reviewer for M/L tasks
- `/review <file>` — Strict code review with /50 scoring
- `/session-end` — Updates `PROJECT_MAP.md` with score, plan-adherence, and cost metrics

### Skills (progressive disclosure)

Domain-specific knowledge loaded only when needed:

- `windows-registry` — safe Registry modification patterns
- `pester-testing` — production Pester 5+ test patterns

---

## Installation

### Quick install (Windows)

1. Clone or download this repository
2. Copy the folder to `Desktop\Engineer System`
3. Open PowerShell as your user (no admin required) and run:

```powershell
cd "$env:USERPROFILE\Desktop\Engineer System"

# One-time profile setup for convenience
$func = 'function install-eng { & "$env:USERPROFILE\Desktop\Engineer System\installer\Install-EngineerSystem.ps1" @args }'
Add-Content -Path $PROFILE -Value $func -Force
. $PROFILE

# Install into any project
cd C:\path\to\your-project
install-eng
```

### Install on Linux / macOS / WSL

```bash
git clone https://github.com/F2lcon01/Engineer-System.git ~/.engineer-system
cd ~/your-project
bash ~/.engineer-system/installer/install.sh
```

### Verify installation

After running the installer, confirm the layout:

```powershell
Test-Path .\CLAUDE.md
Test-Path .\.claude\settings.json
Test-Path .\memory\PROJECT_MAP.md
Get-ChildItem .\.claude\agents
```

You should see `CLAUDE.md`, `.claude/settings.json`, `memory/PROJECT_MAP.md`, and six agent files.

---

## Usage

### First session

```powershell
cd C:\path\to\your-project
install-eng                           # one-time setup
claude                                # open Claude Code
```

Inside Claude Code:

```
/plan Add a PowerShell function to check Windows Update service status
```

Claude analyzes the task, suggests `ps-lead` subagent, defines a testable success criterion, and (for M/L tasks) invokes `plan-reviewer` automatically. Confirm to proceed.

### End every session with `/session-end`

This updates `PROJECT_MAP.md` with three metrics:

- **Score /50** — overall quality
- **Plan-adherence /10** — how closely execution matched the plan
- **Cost-of-Pass** — actual token usage and dollar estimate

After 10–15 sessions, the `[COST_LEDGER]` table reveals which workflows actually pay off.

---

## Folder structure after installation

```
your-project/
├── CLAUDE.md                          # Orchestration layer (auto-loaded)
├── memory/
│   └── PROJECT_MAP.md                 # Persistent memory (auto-injected)
└── .claude/
    ├── settings.json                  # Hook configuration
    ├── agents/                        # 6 subagents with YAML frontmatter
    ├── commands/                      # 3 slash commands
    ├── hooks/                         # 4 shell scripts
    └── skills/                        # 2 progressive-disclosure skills
```

---

## Comparison vs other Claude Code templates

| Feature                           | This system    | wshobson/agents | VoltAgent | peterkrueck/CCDK |
| --------------------------------- | -------------- | --------------- | --------- | ---------------- |
| Real subagents (YAML)             | Yes            | Yes             | Yes       | Yes              |
| Programmatic hooks                | Yes (4 events) | Partial         | No        | Partial          |
| Persistent memory (auto-injected) | Yes            | No              | No        | Partial          |
| Two-gate review workflow          | Yes            | No              | No        | No               |
| Windows/PowerShell first-class    | Yes            | No              | No        | No               |
| Cost tracking ($/point)           | Yes            | No              | No        | No               |
| Dual installer (PS + Bash)        | Yes            | No              | No        | Bash only        |
| File count                        | 23             | 500+            | 100+      | 50+              |

This system is intentionally smaller and more focused. It's not a catalog — it's an opinionated framework.

---

## Limitations and trade-offs

Being honest about what this system cannot do:

- **Not for short sessions.** Subagent overhead costs ~3-4K tokens per session start. Worth it for 2+ hour sessions, wasteful for 10-minute Q&A.
- **Plan-reviewer can be overly cautious.** Expect ~10% false rejection rate on simple plans. Override when justified.
- **Cost tracking is approximate.** Claude Code doesn't expose exact token counts in real time. Treat as a directional indicator.
- **Claude Code only.** Hooks and subagents don't exist in claude.ai. This system has no value there.

---

## Requirements

- Claude Code 2.1.0 or newer
- Node.js 18+ (for Claude Code CLI)
- PowerShell 5.1+ (Windows) or Bash 4+ (Linux/macOS)
- Git for Windows (Windows users — needed for hook execution)

---

## Roadmap

- [ ] v3.2: Validator subagent that auto-runs success-criterion checks
- [ ] v3.3: Plugin marketplace publication (when Claude Code plugin spec stabilizes)
- [ ] v4.0: Multi-session orchestration for long-running projects

---

## Contributing

Pull requests welcome. Before opening one:

1. Run `Verify-EngineerSystem.ps1` and ensure 0 failures
2. Test your change with a real project for at least one full session
3. Update `README.md` if you added/changed user-facing behavior

---

## License

MIT License — see [LICENSE](https://claude.ai/chat/LICENSE) file.

---

<div dir="rtl" lang="ar">

## بالعربية

نظام Engineer System هو إطار عمل لتنسيق وكلاء متعددين في Claude Code. يحوّل Claude Code من أداة محادثة إلى منظومة هندسية منضبطة مع:

- **6 وكلاء متخصصون** يعملون بسياقات منفصلة
- **Hooks برمجية** تفرض القواعد بدلاً من طلبها
- **ذاكرة دائمة** عبر `PROJECT_MAP.md` تنتقل بين الجلسات
- **مراجعة بمرحلتين** (الخطة قبل التنفيذ، الكود بعده)
- **تتبع تكلفة** بمقياس `$/point` يكشف القيمة الحقيقية
- **مثبّت مزدوج** للويندوز (PowerShell) ولينكس/ماك (Bash)

### التثبيت السريع

```powershell
git clone https://github.com/F2lcon01/Engineer-System.git "$env:USERPROFILE\Desktop\Engineer System"
cd "$env:USERPROFILE\Desktop\Engineer System"

# اختصار اختياري في profile
$func = 'function install-eng { & "$env:USERPROFILE\Desktop\Engineer System\installer\Install-EngineerSystem.ps1" @args }'
Add-Content -Path $PROFILE -Value $func -Force
. $PROFILE
```

ثم في أي مشروع:

```powershell
cd C:\path\to\your-project
install-eng
claude
```

### مثال workflow كامل (two-gate)

```text
المستخدم: /plan add Cortana disable feature

Principal:
  → يحلل، يصنف M، يقترح windows-architect
  → يستدعي plan-reviewer تلقائياً
     plan-reviewer: "rollback plan missing for HKLM:\...\Cortana"
  → Principal: "أصلح الخطة، أضف rollback"
  → plan-reviewer: APPROVED
  → ينتظر تأكيد المستخدم

المستخدم: نفّذ
  → windows-architect ينفّذ
  → code-reviewer يتحقق: pre/post conditions، Pester
  → code-reviewer: VERIFIED

Principal: يقبل → /session-end
  → Score: 47/50 | Adherence: 9/10 | Cost: $0.058 | $/point: $0.0012
```

داخل Claude Code:

```
/plan <وصف المهمة>
```

النظام يحلل، يقترح الوكيل المناسب، يراجع الخطة، وينفّذ. عند انتهاء الجلسة:

```
/session-end
```

لتحديث الذاكرة وتسجيل المقاييس الثلاثة (الدرجة، الالتزام بالخطة، التكلفة).

</div>

---

**Built by [Falcon](https://github.com/F2lcon01)** — Polar OS v2.3, everything-claude-code, multi-agent prompt engineering.
