BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModuleRoot\SampleModule.psd1" -Force
}

Describe 'Get-Greeting' {

    Context 'Default (Casual) style' {
        It 'Returns "Hello, <name>!"' {
            Get-Greeting -Name 'World' | Should -Be 'Hello, World!'
        }
    }

    Context 'Formal style' {
        It 'Returns "Good day, <name>!"' {
            Get-Greeting -Name 'World' -Style 'Formal' | Should -Be 'Good day, World!'
        }
    }

    Context 'Invalid input' {
        It 'Throws on empty name' {
            { Get-Greeting -Name '' } | Should -Throw
        }
        It 'Rejects unknown style' {
            { Get-Greeting -Name 'X' -Style 'Wild' } | Should -Throw
        }
    }

    Context 'Pipeline support' {
        It 'Accepts pipeline input' {
            $result = 'Alice', 'Bob' | Get-Greeting
            $result.Count | Should -Be 2
            $result[0] | Should -Be 'Hello, Alice!'
        }
    }
}

AfterAll {
    Remove-Module SampleModule -Force -ErrorAction SilentlyContinue
}
