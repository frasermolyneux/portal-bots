param(
    [string]$sourceWorkingDirectory,
    [string]$environment,
    [string]$client_app_id,
    [string]$client_app_secret,
    [string]$repository_subscription_key,
    [string]$event_ingest_subscription_key,
    [string]$event_ingest_application_audience,
    [string]$mysql_connection_string,
    [string]$api_management_gateway_url
)

Write-Host "Configuring '$($environment)' bot environment on $($env:COMPUTERNAME)"
Write-Host "Source working directory: $($sourceWorkingDirectory)"
Write-Host "Client App ID: '$client_app_id'"

# Load in the local functions
Get-ChildItem -Path "$($sourceWorkingDirectory)\scripts\functions" -Filter "*.ps1" -Recurse | ForEach-Object {
    Write-Host "Loading function file: $($_.Name)"
    . $_.FullName
}

# Read config from Terraform tfvars file
$config = Get-Content "$sourceWorkingDirectory\terraform\tfvars\$environment.tfvars.json" | ConvertFrom-Json

Write-Host "Config.Environment: $($config.environment)"
Write-Host "Config.Location: $($config.location)"
Write-Host "Config.Instance: $($config.instance)"

# Create install directory
$installDirectory = "C:\bots\$environment\app"
$logsDirectory = "C:\bots\$environment\logs"

$spoolDirectory = Join-Path $logsDirectory 'spool'

if ((Test-Path -Path $installDirectory) -ne $true) {
    New-Item -Path $installDirectory -ItemType Directory -Verbose
}

if ((Test-Path -Path $logsDirectory) -ne $true) {
    New-Item -Path $logsDirectory -ItemType Directory -Verbose
}

if ((Test-Path -Path $spoolDirectory) -ne $true) {
    New-Item -Path $spoolDirectory -ItemType Directory -Verbose
}

# Work out the APIM gateway base URL from arguments first, then tfvars fallbacks
if ([string]::IsNullOrWhiteSpace($api_management_gateway_url)) {
    if ($config.PSObject.Properties.Name -contains "api_management_gateway_url" -and -not [string]::IsNullOrWhiteSpace($config.api_management_gateway_url)) {
        $api_management_gateway_url = $config.api_management_gateway_url
    }
    elseif ($config.PSObject.Properties.Name -contains "api_management_name" -and -not [string]::IsNullOrWhiteSpace($config.api_management_name)) {
        $api_management_gateway_url = "https://$($config.api_management_name).azure-api.net"
    }
}

if ([string]::IsNullOrWhiteSpace($api_management_gateway_url)) {
    throw "API Management gateway URL is missing. Provide -api_management_gateway_url or set api_management_gateway_url/api_management_name in the environment tfvars."
}

$apimGatewayBase = $api_management_gateway_url.TrimEnd('/')
Write-Host "Using API Management gateway: $apimGatewayBase"

# Generate access token for the bot to access the repository api
$accessToken = Get-AccessToken -clientId $client_app_id -clientSecret $client_app_secret -scope "$($config.repository_api.application_audience)/.default"

# Get the game servers that are bot enabled
$repositoryUri = "$apimGatewayBase/repository/v1/game-servers"
$servers = Get-BotEnabledServers -uri "$repositoryUri" -accessToken "$accessToken" -subscriptionKey "$repository_subscription_key"

# Stop the currently running scheduled tasks
@(Get-ScheduledTask -TaskPath "\Bots\*") | Unregister-BotScheduledTask

Start-Sleep -Seconds 5

# Get any orphan b3.exe processes and kill them
Get-Process -Name "b3" -ErrorAction SilentlyContinue | Stop-Process -Force

# Delete the existing bot configuration from the install directory
Get-ChildItem -Path $installDirectory -Filter "*" | Remove-Item -Recurse -Force -ErrorAction Continue

# Copy the src files into the install directory
Copy-Item -Path "$sourceWorkingDirectory\src\*" -Destination $installDirectory -Recurse -Force

# Loop through the servers and configure the bot
$servers | Generate-BotConfigFiles -installDirectory $installDirectory `
    -environment $environment `
    -event_ingest_subscription_key $event_ingest_subscription_key `
    -apimUrlBase "$($apimGatewayBase)/event-ingest/v1" `
    -client_app_id $client_app_id `
    -client_app_secret $client_app_secret `
    -application_audience $event_ingest_application_audience `
    -logsDirectory $logsDirectory `
    -mysql_connection_string $mysql_connection_string

$servers | Register-BotScheduledTask -installDirectory $installDirectory

# Start the scheduled tasks
Get-ScheduledTask -TaskPath "\Bots\*" | Start-ScheduledTask