param(
    [string]$environment
)

Write-Host "Configuring '$($environment)' bot environment on $($env:COMPUTERNAME)"

$installDirectory = "C:\bots\$environment"

if (Test-Path -Path $installDirectory -not $true) {
    New-Item -Path $installDirectory -ItemType Directory -Verbose
}