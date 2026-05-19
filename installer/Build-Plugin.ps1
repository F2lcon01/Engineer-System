<#
.SYNOPSIS
    Generates the Claude Code plugin layout from the canonical .claude/ source.

.DESCRIPTION
    Engineer System keeps .claude/ as the canonical source of truth (it's what
    Claude Code reads when working on the source repo itself). The plugin
    distribution format requires components at the repo root (agents/, commands/,
    skills/, scripts/, hooks/hooks.json). This script syncs the two:

        .claude/agents/*.md       ->  agents/*.md
        .claude/commands/*.md     ->  commands/*.md
        .claude/skills/*.md       ->  skills/*.md
        .claude/hooks/*.mjs       ->  scripts/*.mjs (excluding __smoke-test.mjs)
        .claude/hooks/__*         ->  (kept dev-only, not shipped to plugin)
        hooks/hooks.json          ->  generated with ${CLAUDE_PLUGIN_ROOT} refs

    Run before commit if you've touched anything under .claude/. CI should call
    this in --check mode (planned for v3.5) to fail when paths drift.

.PARAMETER RepoRoot
    Engineer System repo root. Default: parent of this script's parent.

.PARAMETER Check
    Validate that plugin paths match .claude/ source without writing. Exit 1 on
    drift, 0 on match. For CI.

.EXAMPLE
    .\Build-Plugin.ps1
    Regenerate the plugin layout from .claude/.

.EXAMPLE
    .\Build-Plugin.ps1 -Check
    CI mode: verify plugin paths are in sync, exit 1 if not.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSCommandPath)),

    [Parameter()]
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

# Path map: source -> destination, excluding patterns
$syncMap = @(
    @{ Source = '.claude/agents';   Dest = 'agents';   Pattern = '*.md' }
    @{ Source = '.claude/commands'; Dest = 'commands'; Pattern = '*.md' }
    @{ Source = '.claude/skills';   Dest = 'skills';   Pattern = '*.md' }
    @{ Source = '.claude/hooks';    Dest = 'scripts';  Pattern = '*.mjs'; Exclude = '__smoke-test.mjs' }
)

$changes = 0
$drift   = @()

foreach ($entry in $syncMap) {
    $srcDir = Join-Path $RepoRoot $entry.Source
    $dstDir = Join-Path $RepoRoot $entry.Dest

    if (-not (Test-Path $srcDir)) {
        Write-Warning "Source missing: $($entry.Source)"
        continue
    }

    if (-not $Check -and -not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    $srcFiles = Get-ChildItem -Path $srcDir -Filter $entry.Pattern -File
    if ($entry.Exclude) {
        $srcFiles = $srcFiles | Where-Object { $_.Name -ne $entry.Exclude }
    }

    foreach ($file in $srcFiles) {
        $dstFile = Join-Path $dstDir $file.Name
        $needsUpdate = $false

        if (-not (Test-Path $dstFile)) {
            $needsUpdate = $true
        } else {
            $srcHash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
            $dstHash = (Get-FileHash $dstFile         -Algorithm SHA256).Hash
            if ($srcHash -ne $dstHash) { $needsUpdate = $true }
        }

        if ($needsUpdate) {
            $changes++
            $relDst = $dstFile.Substring($RepoRoot.Length).TrimStart('\','/').Replace('\','/')
            if ($Check) {
                $drift += $relDst
            } else {
                Copy-Item -Path $file.FullName -Destination $dstFile -Force
                Write-Host "  synced  $relDst" -ForegroundColor Green
            }
        }
    }

    # Detect orphans: files in destination that no longer exist in source
    if (Test-Path $dstDir) {
        $dstFiles = Get-ChildItem -Path $dstDir -Filter $entry.Pattern -File
        foreach ($dstFile in $dstFiles) {
            $srcFile = Join-Path $srcDir $dstFile.Name
            if (-not (Test-Path $srcFile)) {
                $changes++
                $relDst = $dstFile.FullName.Substring($RepoRoot.Length).TrimStart('\','/').Replace('\','/')
                if ($Check) {
                    $drift += "ORPHAN: $relDst"
                } else {
                    Remove-Item -Path $dstFile.FullName -Force
                    Write-Host "  removed $relDst (orphan)" -ForegroundColor Yellow
                }
            }
        }
    }
}

# Generate hooks/hooks.json
$hooksJsonPath = Join-Path $RepoRoot 'hooks\hooks.json'
$hooksJsonDir  = Split-Path $hooksJsonPath -Parent
if (-not $Check -and -not (Test-Path $hooksJsonDir)) {
    New-Item -ItemType Directory -Path $hooksJsonDir -Force | Out-Null
}

$hooksJsonContent = @'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/session-start.mjs\"" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/post-edit.mjs\"" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/pre-bash.mjs\"" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/stop-reminder.mjs\"" }
        ]
      }
    ]
  }
}
'@

if (Test-Path $hooksJsonPath) {
    $currentHooks = Get-Content $hooksJsonPath -Raw
    if ($currentHooks -ne $hooksJsonContent + "`r`n" -and $currentHooks -ne $hooksJsonContent) {
        $changes++
        if ($Check) {
            $drift += 'hooks/hooks.json'
        } else {
            Set-Content -Path $hooksJsonPath -Value $hooksJsonContent -NoNewline
            Write-Host "  synced  hooks/hooks.json" -ForegroundColor Green
        }
    }
} else {
    $changes++
    if ($Check) {
        $drift += 'hooks/hooks.json (missing)'
    } else {
        Set-Content -Path $hooksJsonPath -Value $hooksJsonContent -NoNewline
        Write-Host "  created hooks/hooks.json" -ForegroundColor Green
    }
}

# Report
Write-Host ""
if ($Check) {
    if ($drift.Count -eq 0) {
        Write-Host "Plugin layout in sync with .claude/" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Plugin layout drift detected (${($drift.Count)} item(s)):" -ForegroundColor Red
        $drift | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host ""
        Write-Host "Fix: run Build-Plugin.ps1 without -Check, then commit." -ForegroundColor Yellow
        exit 1
    }
} else {
    if ($changes -eq 0) {
        Write-Host "No changes - plugin layout already in sync." -ForegroundColor Gray
    } else {
        Write-Host "Plugin layout regenerated ($changes file(s) synced)." -ForegroundColor Cyan
    }
}
