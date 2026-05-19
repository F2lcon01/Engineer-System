function Get-Greeting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateSet('Formal', 'Casual')]
        [string]$Style = 'Casual'
    )

    process {
        try {
            $greeting = if ($Style -eq 'Formal') { 'Good day' } else { 'Hello' }
            Write-Output "$greeting, $Name!"
        }
        catch {
            Write-Error "Greeting failed for '$Name': $($_.Exception.Message)"
            throw
        }
    }
}
