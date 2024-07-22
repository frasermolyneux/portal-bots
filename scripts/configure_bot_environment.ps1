param(
    [string]$sourceWorkingDirectory,
    [string]$environment,
    [string]$client_app_id,
    [string]$client_app_secret
)

Write-Host "Configuring '$($environment)' bot environment on $($env:COMPUTERNAME)"
Write-Host "Source working directory: $($sourceWorkingDirectory)"

# Read config from Terraform tfvars file
$config = Get-Content "$sourceWorkingDirectory\terraform\tfvars\$environment.tfvars" | ConvertFrom-StringData

# Loop through configuration and write out
foreach ($key in $config.Keys) {
    Write-Host "$key : $($config[$key])"
}

# Create install directory
$installDirectory = "C:\bots\$environment"

if ((Test-Path -Path $installDirectory) -ne $true) {
    New-Item -Path $installDirectory -ItemType Directory -Verbose
}