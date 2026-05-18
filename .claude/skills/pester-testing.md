---
name: pester-testing
description: Pester 5+ test patterns for PowerShell modules. Loaded automatically when writing or modifying .Tests.ps1 files, Pester tests, or PowerShell unit tests. Provides verified test structures, mocking patterns, and CI integration.
---

# Pester Testing Skill

This skill activates when working with Pester tests. Read this **before** writing any `.Tests.ps1` file.

## The Three Laws of Pester Testing

1. **Test the failure path first** — happy-path tests are easy and prove nothing
2. **Mock external dependencies** — tests must not depend on network, filesystem state, or other services
3. **One Describe, one feature** — don't bundle unrelated tests; reviewers must navigate quickly

## Minimum viable test file

```powershell
# Tests/Disable-Telemetry.Tests.ps1

BeforeAll {
    # Import the module under test
    $ModulePath = "$PSScriptRoot/../Disable-Telemetry.psm1"
    Import-Module $ModulePath -Force
}

Describe 'Get-TelemetryStatus' {

    Context 'When all telemetry services are running' {
        BeforeAll {
            Mock Get-Service { @{ Status = 'Running' } } -ModuleName Disable-Telemetry
        }

        It 'Returns true' {
            Get-TelemetryStatus | Should -BeTrue
        }
    }

    Context 'When a service is missing' {
        BeforeAll {
            Mock Get-Service { throw [Microsoft.PowerShell.Commands.ServiceCommandException]::new() } `
                -ModuleName Disable-Telemetry
        }

        It 'Returns false without throwing' {
            { Get-TelemetryStatus } | Should -Not -Throw
            Get-TelemetryStatus | Should -BeFalse
        }
    }

    Context 'When called without admin privileges' {
        BeforeAll {
            Mock Test-IsAdmin { $false } -ModuleName Disable-Telemetry
        }

        It 'Writes a clear error message' {
            $errorOutput = Get-TelemetryStatus -ErrorAction SilentlyContinue 2>&1
            $errorOutput | Should -Match 'requires administrator privileges'
        }
    }
}

AfterAll {
    Remove-Module Disable-Telemetry -Force -ErrorAction SilentlyContinue
}
```

## Mocking patterns by scenario

### Mock a cmdlet that returns objects

```powershell
Mock Get-Process { 
    @(
        [PSCustomObject]@{ Name = 'svchost'; Id = 100 },
        [PSCustomObject]@{ Name = 'explorer'; Id = 200 }
    ) 
} -ModuleName MyModule
```

### Mock with parameter filter (conditional mock)

```powershell
Mock Get-ItemProperty { @{ EnableActivityFeed = 1 } } -ParameterFilter {
    $Path -eq 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
} -ModuleName MyModule
```

### Mock that throws

```powershell
Mock Invoke-WebRequest { throw 'Network unreachable' } -ModuleName MyModule

It 'Falls back gracefully on network failure' {
    { Get-OnlineConfig } | Should -Not -Throw
    Get-OnlineConfig | Should -Be $null
}
```

## Coverage requirements (non-negotiable)

For every Public function:

| Test type | Required? | Why |
|-----------|-----------|-----|
| Happy path | Yes | Baseline functionality |
| At least one failure path | **Yes** | Failure handling is half the code |
| Edge case (null/empty/zero) | Yes | Bugs hide in edges |
| Parameter validation | Yes | `[ValidateNotNullOrEmpty()]` etc. should reject bad input |
| Pipeline support | If applicable | `ValueFromPipeline` must actually work |

## Running tests with proper output

```powershell
# Local development
Invoke-Pester -Path ./Tests -Output Detailed

# CI mode (produces NUnit XML for pipeline)
Invoke-Pester -Configuration @{
    Run = @{ Path = './Tests' }
    Output = @{ Verbosity = 'Normal' }
    TestResult = @{ 
        Enabled = $true
        OutputPath = 'test-results.xml'
        OutputFormat = 'NUnitXml'
    }
    CodeCoverage = @{
        Enabled = $true
        Path = './*.psm1'
        OutputPath = 'coverage.xml'
    }
}
```

## Common Pester mistakes

| Mistake | Fix |
|---------|-----|
| Testing implementation, not behavior | Test outputs and side effects, not internal calls |
| Missing `-ModuleName` on Mock | Mocks won't apply inside imported modules without it |
| Real network/disk calls in tests | All external deps must be mocked |
| Slow tests (>1s) | Profile and fix; slow tests get skipped over time |
| Tests that depend on each other | Each `It` block must be independent |
