param(
    [Parameter(Mandatory = $true)][string]$sourceWorkingDirectory,
    [Parameter(Mandatory = $true)][string]$environment,
    [Parameter(Mandatory = $true)][string]$clientAppId,
    [Parameter(Mandatory = $true)][string]$clientAppSecret,
    [Parameter(Mandatory = $true)][string]$repositoryApplicationAudience,
    [Parameter(Mandatory = $true)][string]$eventIngestApplicationAudience,
    [Parameter(Mandatory = $true)][string]$mysqlConnectionString,
    [Parameter(Mandatory = $true)][string]$repositoryApiBaseUrl,
    [Parameter(Mandatory = $true)][string]$eventIngestApiBaseUrl
)

Write-Host "Configuring '$($environment)' bot environment on $($env:COMPUTERNAME)"
Write-Host "Source working directory: $($sourceWorkingDirectory)"
Write-Host "Client App ID: '$clientAppId'"

# Load in the local functions
Get-ChildItem -Path "$($sourceWorkingDirectory)\scripts\functions" -Filter "*.ps1" -Recurse | ForEach-Object {
    Write-Host "Loading function file: $($_.Name)"
    . $_.FullName
}

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

$repositoryBase = $repositoryApiBaseUrl.TrimEnd('/')
$eventIngestBase = $eventIngestApiBaseUrl.TrimEnd('/')
Write-Host "Repository API base: $repositoryBase"
Write-Host "Event Ingest API base: $eventIngestBase"

# Generate access token for the bot to access the repository api
$accessToken = Get-AccessToken -clientId $clientAppId -clientSecret $clientAppSecret -scope "$($repositoryApplicationAudience)/.default"

# Get the game servers that are bot enabled
$repositoryUri = "$repositoryBase/v1/game-servers"
$servers = Get-BotEnabledServers -uri "$repositoryUri" -accessToken "$accessToken"

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
    -apimUrlBase "$($eventIngestBase)/v1" `
    -client_app_id $clientAppId `
    -client_app_secret $clientAppSecret `
    -application_audience $eventIngestApplicationAudience `
    -logsDirectory $logsDirectory `
    -mysql_connection_string $mysqlConnectionString

$servers | Register-BotScheduledTask -installDirectory $installDirectory

# Start the scheduled tasks
Get-ScheduledTask -TaskPath "\Bots\*" | Start-ScheduledTask