<#
.SYNOPSIS
    Installs the Principal Engineer System into the current project.

.DESCRIPTION
    Copies CLAUDE.md, .claude/, and memory/ from the system source into the
    target project. Detects conflicts, preserves user data, sets permissions,
    and updates .gitignore. Safe to re-run for upgrades.

.PARAMETER SourcePath
    Path to the Engineer System folder on disk.
    Default: "$env:USERPROFILE\Desktop\Engineer System"

.PARAMETER TargetPath
    Path to the project where the system will be installed.
    Default: current directory (Get-Location)

.PARAMETER Mode
    Install | Upgrade | DryRun
    - Install: fresh install (fails if system files already exist)
    - Upgrade: refresh agents/commands/hooks but preserve CLAUDE.md customization and PROJECT_MAP data
    - DryRun: show what would happen without writing anything

.PARAMETER Force
    Overwrite even if conflicts detected. Use with caution.

.EXAMPLE
    .\Install-EngineerSystem.ps1
    Installs into current directory using default source.

.EXAMPLE
    .\Install-EngineerSystem.ps1 -TargetPath C:\projects\polar-os -Mode Upgrade
    Upgrades existing installation, preserves user data.

.EXAMPLE
    .\Install-EngineerSystem.ps1 -Mode DryRun
    Shows what would change without writing.

.NOTES
    Requires PowerShell 5.1+
    Works on Windows. On Linux/macOS use install.sh instead.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SourcePath = (Join-Path $env:USERPROFILE 'Desktop\Engineer System'),

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TargetPath = (Get-Location).Path,

    [Parameter()]
    [ValidateSet('Install', 'Upgrade', 'DryRun')]
    [string]$Mode = 'Install',

    [Parameter()]
    [switch]$Force
)

# ==================== Setup ====================

$ErrorActionPreference = 'Stop'
$script:Changes = @()
$script:Warnings = @()
$script:DryRun = ($Mode -eq 'DryRun')

# Colors for output
function Write-Step  { param($Msg) Write-Host "→ $Msg" -ForegroundColor Cyan }
function Write-OK    { param($Msg) Write-Host "✓ $Msg" -ForegroundColor Green }
function Write-Warn  { param($Msg) Write-Host "⚠ $Msg" -ForegroundColor Yellow; $script:Warnings += $Msg }
function Write-Err   { param($Msg) Write-Host "✗ $Msg" -ForegroundColor Red }
function Write-Info  { param($Msg) Write-Host "  $Msg" -ForegroundColor DarkGray }

function Write-Banner {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "    Principal Engineer System — Installer v1.0" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
}

# ==================== Validation ====================

function Test-Prerequisites {
    Write-Step "التحقق من المتطلبات..."

    # PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "يتطلب PowerShell 5.1 على الأقل. الإصدار الحالي: $($PSVersionTable.PSVersion)"
    }
    Write-Info "PowerShell $($PSVersionTable.PSVersion) ✓"

    # Source exists
    if (-not (Test-Path $SourcePath -PathType Container)) {
        throw "مجلد المصدر غير موجود: $SourcePath`nتأكد أن النظام محفوظ في المسار المطلوب."
    }
    Write-Info "المصدر موجود: $SourcePath"

    # Source has required files (v3.3: CLAUDE.local.md is optional but recommended as seed)
    $requiredFiles = @('CLAUDE.md', '.claude/settings.json', 'memory/PROJECT_MAP.md')
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $SourcePath $file
        if (-not (Test-Path $fullPath)) {
            throw "ملف أساسي مفقود في المصدر: $file"
        }
    }
    Write-Info "ملفات النظام مكتملة (CLAUDE.md, .claude/, memory/)"

    if (-not (Test-Path (Join-Path $SourcePath 'CLAUDE.local.md'))) {
        Write-Info "تنبيه: CLAUDE.local.md غير موجود في المصدر — لن يُنشَأ template في الهدف"
    }

    # Target exists and is directory
    if (-not (Test-Path $TargetPath -PathType Container)) {
        throw "مجلد الهدف غير موجود: $TargetPath"
    }
    Write-Info "الهدف: $TargetPath"

    # Claude Code installed?
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claudeCmd) {
        Write-Warn "Claude Code CLI غير مثبّت. ثبّته بـ: npm install -g @anthropic-ai/claude-code"
    } else {
        Write-Info "Claude Code متاح: $($claudeCmd.Source)"
    }

    # Node.js — required for hooks in v3.2+
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) {
        Write-Warn "Node.js غير موجود في PATH. الـ hooks لن تعمل."
        Write-Info "  ثبّت Node 18+: https://nodejs.org/  (يُثبَّت تلقائياً مع Claude Code عادةً)"
    } else {
        $nodeVer = & node --version 2>$null
        if ($nodeVer -match '^v(\d+)') {
            $major = [int]$Matches[1]
            if ($major -lt 18) {
                Write-Warn "Node.js $nodeVer أقدم من المطلوب (18+). الـ hooks قد تفشل."
            } else {
                Write-Info "Node.js $nodeVer ✓"
            }
        }
    }

    Write-OK "المتطلبات مكتملة"
}

# ==================== Conflict Detection ====================

function Get-Conflicts {
    Write-Step "فحص الـ Conflicts..."

    $conflicts = @{
        ClaudeMd      = $false
        ProjectMap    = $false
        ClaudeFolder  = $false
        MemoryFolder  = $false
        HasData       = $false
    }

    # CLAUDE.md
    $targetClaudeMd = Join-Path $TargetPath 'CLAUDE.md'
    if (Test-Path $targetClaudeMd) {
        $conflicts.ClaudeMd = $true
        Write-Info "CLAUDE.md موجود مسبقاً ($(((Get-Item $targetClaudeMd).Length / 1KB).ToString('F1')) KB)"
    }

    # PROJECT_MAP.md (must check for actual user data)
    $targetProjectMap = Join-Path $TargetPath 'memory\PROJECT_MAP.md'
    if (Test-Path $targetProjectMap) {
        $conflicts.ProjectMap = $true
        $content = Get-Content $targetProjectMap -Raw
        # Check if it has real session data (more than template)
        if ($content -match '### Session \d+' -or $content.Length -gt 3000) {
            $conflicts.HasData = $true
            Write-Info "PROJECT_MAP.md يحتوي بيانات فعلية — سيُحمى"
        }
    }

    # .claude folder
    $targetClaudeDir = Join-Path $TargetPath '.claude'
    if (Test-Path $targetClaudeDir) {
        $conflicts.ClaudeFolder = $true
        $fileCount = (Get-ChildItem $targetClaudeDir -Recurse -File).Count
        Write-Info ".claude/ موجود ($fileCount ملف)"
    }

    return $conflicts
}

function Resolve-InstallMode {
    param([hashtable]$Conflicts)

    if ($Mode -eq 'DryRun') { return }

    $hasConflicts = $Conflicts.ClaudeMd -or $Conflicts.ClaudeFolder

    if ($Mode -eq 'Install' -and $hasConflicts -and -not $Force) {
        Write-Host ""
        Write-Warn "النظام مثبّت سابقاً في هذا المشروع."
        Write-Host ""
        Write-Host "خياراتك:" -ForegroundColor Yellow
        Write-Host "  1. أعد تشغيل السكريبت بـ -Mode Upgrade للتحديث (يحفظ بياناتك)" -ForegroundColor Gray
        Write-Host "  2. أعد تشغيل السكريبت بـ -Force للاستبدال (خطر — قد تفقد التخصيصات)" -ForegroundColor Gray
        Write-Host "  3. احذف الملفات الموجودة يدوياً وأعد تشغيل السكريبت" -ForegroundColor Gray
        Write-Host ""
        throw "العملية أُلغيت — اختر طريقة من الخيارات أعلاه."
    }

    if ($Conflicts.HasData -and $Mode -ne 'Upgrade') {
        Write-Warn "PROJECT_MAP.md يحتوي بيانات — لن أكتب فوقه. سيُتجاهل النسخ."
    }
}

# ==================== Copy Operations ====================

function Copy-WithProtection {
    param(
        [string]$SourceFile,
        [string]$TargetFile,
        [bool]$ProtectExisting = $false
    )

    $rel = $TargetFile.Replace($TargetPath, '').TrimStart('\').Replace('\', '/')

    # Protected file that exists — skip
    if ($ProtectExisting -and (Test-Path $TargetFile)) {
        Write-Info "تخطي (محمي): $rel"
        $script:Changes += [PSCustomObject]@{ Action = 'Skipped'; File = $rel; Reason = 'Protected' }
        return
    }

    # Ensure parent directory exists
    $parent = Split-Path $TargetFile -Parent
    if (-not (Test-Path $parent)) {
        if (-not $script:DryRun) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }

    $action = if (Test-Path $TargetFile) { 'Updated' } else { 'Created' }

    if (-not $script:DryRun) {
        Copy-Item -Path $SourceFile -Destination $TargetFile -Force
    }

    Write-Info "$action`: $rel"
    $script:Changes += [PSCustomObject]@{ Action = $action; File = $rel; Reason = '' }
}

function Install-Files {
    param([hashtable]$Conflicts)

    Write-Step "نسخ ملفات النظام..."

    # 1. CLAUDE.md — v3.3 is immutable orchestration: always refresh
    #    (per-project context lives in CLAUDE.local.md, which is protected separately)
    $srcClaude = Join-Path $SourcePath 'CLAUDE.md'
    $dstClaude = Join-Path $TargetPath 'CLAUDE.md'
    Copy-WithProtection -SourceFile $srcClaude -TargetFile $dstClaude -ProtectExisting $false

    # 1b. CLAUDE.local.md — per-project notes: ALWAYS protect if exists, seed template if missing
    $srcLocal = Join-Path $SourcePath 'CLAUDE.local.md'
    $dstLocal = Join-Path $TargetPath 'CLAUDE.local.md'
    if (Test-Path $srcLocal) {
        Copy-WithProtection -SourceFile $srcLocal -TargetFile $dstLocal -ProtectExisting $true
    }

    # 2. .claude/ folder — always refresh, with two exceptions:
    #    - project.json: protect if exists (user/bootstrap wrote real data)
    #    - .session-edits.log*: never copy (runtime artifacts)
    $srcClaudeDir = Join-Path $SourcePath '.claude'
    Get-ChildItem -Path $srcClaudeDir -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($srcClaudeDir.Length).TrimStart('\')
        if ($relativePath -like '.session-edits.log*') { return }
        $dstFile = Join-Path (Join-Path $TargetPath '.claude') $relativePath
        $protect = ($relativePath -eq 'project.json' -and (Test-Path $dstFile))
        Copy-WithProtection -SourceFile $_.FullName -TargetFile $dstFile -ProtectExisting $protect
    }

    # 3. memory/PROJECT_MAP.md — ALWAYS protect if has data
    $srcMap = Join-Path $SourcePath 'memory\PROJECT_MAP.md'
    $dstMap = Join-Path $TargetPath 'memory\PROJECT_MAP.md'
    Copy-WithProtection -SourceFile $srcMap -TargetFile $dstMap -ProtectExisting $Conflicts.HasData
}

# ==================== Permissions ====================

function Test-HooksInstalled {
    Write-Step "التحقق من ملفات الـ Hooks (Node)..."

    if ($script:DryRun) {
        Write-Info "(DryRun) تخطي فحص hooks — لم يُكتب شيء فعلياً"
        return
    }

    $hooksDir = Join-Path $TargetPath '.claude\hooks'
    if (-not (Test-Path $hooksDir)) {
        Write-Warn "مجلد hooks غير موجود — تخطي"
        return
    }

    $required = @('session-start.mjs', 'pre-bash.mjs', 'post-edit.mjs', 'stop-reminder.mjs')
    $missing = @()
    foreach ($h in $required) {
        if (-not (Test-Path (Join-Path $hooksDir $h))) { $missing += $h }
    }

    if ($missing.Count -gt 0) {
        Write-Warn ("ملفات hooks مفقودة: " + ($missing -join ', '))
    } else {
        Write-Info "كل الـ hooks (.mjs) موجودة — Node executor، لا chmod"
    }

    # Detect leftover legacy .sh hooks from v3.1 in the TARGET project — warn the user
    $legacy = Get-ChildItem -Path $hooksDir -Filter '*.sh' -ErrorAction SilentlyContinue
    if ($legacy) {
        Write-Warn "ملفات hooks قديمة (.sh) من v3.1 — احذفها:"
        $legacy | ForEach-Object { Write-Info "  Remove-Item '$($_.FullName)'" }
    }
}

# ==================== Gitignore ====================

function Update-Gitignore {
    Write-Step "تحديث .gitignore..."

    $gitignorePath = Join-Path $TargetPath '.gitignore'
    $gitDir = Join-Path $TargetPath '.git'

    if (-not (Test-Path $gitDir)) {
        Write-Info "ليس Git repo — تخطي .gitignore"
        return
    }

    $entriesToAdd = @(
        '# Principal Engineer System — internal tracking',
        '.claude/.session-edits.log',
        '.claude/.session-edits.log.old',
        'CLAUDE.local.md'
    )

    if (Test-Path $gitignorePath) {
        $current = Get-Content $gitignorePath -Raw
        if ($current -match [regex]::Escape('CLAUDE.local.md')) {
            Write-Info ".gitignore يحتوي الإدخالات المطلوبة"
            return
        }

        if (-not $script:DryRun) {
            Add-Content -Path $gitignorePath -Value "`n$($entriesToAdd -join "`n")"
        }
        Write-Info "أُضيفت إدخالات النظام لـ .gitignore"
    } else {
        if (-not $script:DryRun) {
            Set-Content -Path $gitignorePath -Value ($entriesToAdd -join "`n")
        }
        Write-Info "أُنشئ .gitignore جديد"
    }
}

# ==================== Customization ====================

function Suggest-Customization {
    Write-Step "اقتراحات التخصيص..."

    $projectName = Split-Path $TargetPath -Leaf
    Write-Host ""
    Write-Host "اسم المشروع المكتشف: " -NoNewline -ForegroundColor Gray
    Write-Host $projectName -ForegroundColor White
    Write-Host ""
    Write-Host "خطوة موصى بها بعد التثبيت:" -ForegroundColor Yellow
    Write-Host "  1. افتح Claude Code (VS Code → Ctrl+Esc أو CLI: " -NoNewline -ForegroundColor Gray
    Write-Host "claude" -NoNewline -ForegroundColor Cyan
    Write-Host ")" -ForegroundColor Gray
    Write-Host "  2. شغّل " -NoNewline -ForegroundColor Gray
    Write-Host "/bootstrap" -NoNewline -ForegroundColor Cyan
    Write-Host " — يقرأ المشروع + يمسح GitHub + يملأ PROJECT_MAP تلقائياً" -ForegroundColor Gray
    Write-Host "  3. عدّل " -NoNewline -ForegroundColor Gray
    Write-Host "CLAUDE.local.md" -NoNewline -ForegroundColor Cyan
    Write-Host " (التفضيلات الخاصة بـ $projectName — محمي عن الـ upgrades)" -ForegroundColor Gray
    Write-Host "  4. ابدأ بـ " -NoNewline -ForegroundColor Gray
    Write-Host "/plan <مهمتك>" -ForegroundColor Cyan
}

# ==================== Summary ====================

function Write-Summary {
    Write-Host ""
    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "ملخص العملية" -ForegroundColor White
    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray

    $created = ($script:Changes | Where-Object Action -eq 'Created').Count
    $updated = ($script:Changes | Where-Object Action -eq 'Updated').Count
    $skipped = ($script:Changes | Where-Object Action -eq 'Skipped').Count

    Write-Host "  ملفات جديدة:  " -NoNewline -ForegroundColor Gray
    Write-Host $created -ForegroundColor Green
    Write-Host "  ملفات مُحدّثة: " -NoNewline -ForegroundColor Gray
    Write-Host $updated -ForegroundColor Cyan
    Write-Host "  ملفات محمية:  " -NoNewline -ForegroundColor Gray
    Write-Host $skipped -ForegroundColor Yellow

    if ($script:Warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "تنبيهات:" -ForegroundColor Yellow
        $script:Warnings | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
    }

    if ($script:DryRun) {
        Write-Host ""
        Write-Host "═══ DRY RUN — لم يُكتب أي ملف فعلياً ═══" -ForegroundColor Magenta
    } else {
        Write-Host ""
        Write-OK "اكتمل التثبيت بنجاح في: $TargetPath"
    }
    Write-Host ""
}

# ==================== Main ====================

try {
    Write-Banner

    Write-Host "الوضع: " -NoNewline -ForegroundColor Gray
    Write-Host $Mode -ForegroundColor $(if ($Mode -eq 'DryRun') { 'Magenta' } else { 'White' })
    Write-Host ""

    Test-Prerequisites
    Write-Host ""

    $conflicts = Get-Conflicts
    Write-Host ""

    Resolve-InstallMode -Conflicts $conflicts

    Install-Files -Conflicts $conflicts
    Write-Host ""

    Test-HooksInstalled
    Write-Host ""

    Update-Gitignore
    Write-Host ""

    Suggest-Customization

    Write-Summary

    exit 0
}
catch {
    Write-Host ""
    Write-Err "فشل التثبيت: $($_.Exception.Message)"
    Write-Host ""
    if ($_.ScriptStackTrace) {
        Write-Host "تفاصيل تقنية:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    exit 1
}
