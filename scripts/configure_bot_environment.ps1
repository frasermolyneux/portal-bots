param(
    [string]$sourceWorkingDirectory,
    [string]$environment,
    [string]$client_app_id,
    [string]$client_app_secret,
    [string]$repository_subscription_key,
    [string]$event_ingest_subscription_key
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
$installDirectory = "C:\bots\$environment"

if ((Test-Path -Path $installDirectory) -ne $true) {
    New-Item -Path $installDirectory -ItemType Directory -Verbose
}

# Generate access token for the bot to access the repository api
$accessToken = Get-AccessToken -clientId $client_app_id -clientSecret $client_app_secret -scope "$($config.repository_api.application_audience)/.default"

# Get the game servers that are bot enabled
$uri = "https://$($config.api_management_name).azure-api.net/$($config.repository_api.apim_path_prefix)/game-servers/"
$servers = Get-BotEnabledServers -uri "$uri" -accessToken "$accessToken" -subscriptionKey "$repository_subscription_key"

# Stop the currently running scheduled tasks
Get-ScheduledTask -TaskName "\Bots\*" | Stop-ScheduledTask
Get-ScheduledTask -TaskName "\Bots\*" | Unregister-ScheduledTask

# Loop through the servers and configure the bot
$servers | ForEach-Object {
    $server = $_

    Write-Host "Configuring bot for server: $($server.title)"

    $action = New-ScheduledTaskAction -Execute "$installDirectory\b3.exe" -Argument "-c $installDirectory\conf\$($server.gameServerId).ini"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([System.TimeSpan]::MaxValue)
    $principal = "NT AUTHORITY\SYSTEM"
    $settings = New-ScheduledTaskSettingsSet
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
    Register-ScheduledTask "\Bots\$($server.gameServerId)" -InputObject $task
}


