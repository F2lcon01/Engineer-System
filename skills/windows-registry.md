---
name: windows-registry
description: Safe Windows Registry modification patterns. Loaded automatically when tasks involve Registry edits (HKLM, HKCU, .reg files, regedit). Provides verified patterns, rollback templates, and Microsoft Learn references.
---

# Windows Registry Skill

This skill activates automatically when working with Windows Registry. Read this **before** suggesting any Registry change.

## The Three Laws of Registry Modification

1. **Export before edit** — always create a `.reg` backup of the current state
2. **Test in VM first** — never test Registry changes on Physical hardware first
3. **Document the Microsoft source** — every change needs an authoritative URL

## Verified safe patterns

### Read a Registry value (PowerShell)

```powershell
# Use Get-ItemProperty (works on PS 5.1+)
$value = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' `
                          -Name 'EnableActivityFeed' `
                          -ErrorAction SilentlyContinue
if ($null -eq $value) {
    # Key doesn't exist — treat as default
}
```

### Set a Registry value (with rollback)

```powershell
function Set-RegistryValueSafe {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][ValidateSet('String','DWord','QWord','Binary','MultiString')]
        [string]$Type
    )

    # 1. Export current state to rollback file
    $rollbackDir = "$env:TEMP\registry-rollback"
    if (-not (Test-Path $rollbackDir)) { New-Item -ItemType Directory -Path $rollbackDir | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $rollbackFile = "$rollbackDir\$Name-$stamp.reg"

    # Convert PS path to reg.exe path
    $regPath = $Path -replace 'HKLM:', 'HKEY_LOCAL_MACHINE' -replace 'HKCU:', 'HKEY_CURRENT_USER'
    & reg.exe export $regPath $rollbackFile /y | Out-Null

    if ($PSCmdlet.ShouldProcess($Path, "Set $Name = $Value")) {
        # 2. Ensure key path exists
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        # 3. Set the value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-Verbose "Rollback file: $rollbackFile"
    }
}
```

### Rollback a Registry change

```powershell
# Apply the rollback .reg file
$rollbackFile = "$env:TEMP\registry-rollback\EnableActivityFeed-20260518-123045.reg"
& reg.exe import $rollbackFile
```

## Common dangerous patterns to avoid

| Pattern | Why dangerous |
|---------|---------------|
| `Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\...' -Recurse` | Wipes subkeys silently; no undo |
| Setting `HKLM:\...\Run` without verification | Persistent autoruns are malware-like |
| Editing `HKLM:\SYSTEM\CurrentControlSet\Services\` | Service config; one wrong edit = boot failure |
| Modifying `HKLM:\SOFTWARE\Microsoft\Cryptography\` | Affects machine SID; breaks domain join |

## Microsoft Learn references (verified)

- Group Policy Registry locations: https://learn.microsoft.com/windows/client-management/mdm/policy-csps-supported-by-group-policy
- Telemetry settings: https://learn.microsoft.com/windows/privacy/configure-windows-diagnostic-data-in-your-organization
- Service Registry layout: https://learn.microsoft.com/windows-hardware/drivers/install/registry-trees-and-keys

**When citing Microsoft as source, always include the URL above with the verification date.**

## VM vs Physical considerations

| Scenario | VM behavior | Physical behavior | Note |
|----------|-------------|-------------------|------|
| Hardware-detection keys | Generic IDs | Actual hardware IDs | Test both |
| Boot-time keys | VM-aware drivers | Real drivers | Some tweaks break only on Physical |
| Telemetry keys | Same | Same | Generally safe to extrapolate from VM |
| Performance keys | VM overhead skews results | True performance | Benchmark on Physical |
