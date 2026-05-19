# SampleModule

A trivial PowerShell module used as a fixture for testing **Engineer System** end-to-end.

## What it does

Exports `Get-Greeting -Name <string> [-Style Formal|Casual]` returning a greeting string.

## Why it exists

To exercise the Engineer System's:

- `install-eng` (PowerShell module project layout)
- `/bootstrap` (manifest detection: `.psd1` → PowerShell)
- `ps-lead` agent (touches PowerShell-shaped code)
- `validator` (real Pester command via `.claude/project.json`)
- `pester-testing` skill (loaded when editing Tests/)

## Run the tests

```powershell
Invoke-Pester -Path .\Tests -Output Detailed
```
