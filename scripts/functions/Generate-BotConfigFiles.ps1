function Generate-BotConfigFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][object]$server,
        [string]$environment,
        [string]$installDirectory,
        [string]$apimUrlBase,
        [string]$event_ingest_subscription_key,
        [string]$client_app_id,
        [string]$client_app_secret,
        [string]$application_audience,
        [string]$logsDirectory,
        [string]$mysql_connection_string
    )
    
    begin {

    }
    
    process {
        Write-Host "Generating bot config files for server: '$($server.title)'"
        
        $conf1 = Get-Content "$installDirectory\conf_templates\gameType_serverId.ini" -Raw
        $conf2 = Get-Content "$installDirectory\conf_templates\plugin_portal_gameType_serverId.ini" -Raw

        $parser = "unknown"
        switch ($server.gameType) {
            "CallOfDuty2" { $parser = "cod2" }
            "CallOfDuty4" { $parser = "cod4" }
            "CallOfDuty5" { $parser = "cod5" }
        }

        $tokenReplacements = @{
            "__ENVIRONMENT__"             = $environment
            "__SERVER_ID__"               = $server.gameServerId
            "__GAME_TYPE__"               = $server.gameType
            "__PARSER__"                  = $parser
            "__RCON_PASSWORD__"           = $server.rconPassword
            "__QUERY_PORT__"              = $server.queryPort
            "__IP_ADDRESS__"              = $server.hostname
            "__FTP_USERNAME__"            = $server.ftpUsername
            "__FTP_PASSWORD__"            = $server.ftpPassword
            "__FTP_HOSTNAME__"            = $server.ftpHostname
            "__FTP_PORT__"                = $server.ftpPort
            "__LIVE_LOG_FILE__"           = $server.liveLogFile
            "__APIM_URL_BASE__"           = $apimUrlBase
            "__TENANT_ID__"               = "e56a6947-bb9a-4a6e-846a-1f118d1c3a14"
            "__CLIENT_ID__"               = $client_app_id
            "__CLIENT_SECRET__"           = $client_app_secret
            "__API_SUBSCRIPTION_KEY__"    = $event_ingest_subscription_key
            "__SCOPE__"                   = "$application_audience/.default"
            "__PEM_FILE_PATH__"           = "$installDirectory\cacert.pem"
            "__LOGS_DIRECTORY__"          = $logsDirectory
            "__MYSQL_CONNECTION_STRING__" = $mysql_connection_string
            "__SPOOL_PATH__"              = (Join-Path (Join-Path $logsDirectory 'spool') "portal_$($server.gameType)_$($server.gameServerId).jsonl")
        }

        # Replace $conf1 using the $tokenReplacements hashtable
        foreach ($key in $tokenReplacements.Keys) {
            $value = $tokenReplacements[$key]

            $conf1 = $conf1 -replace $key, $value
            $conf2 = $conf2 -replace $key, $value
        }

        # Save the new config file
        $conf1 | Set-Content "$installDirectory\conf\$($server.gameType)_$($server.gameServerId).ini"
        $conf2 | Set-Content "$installDirectory\conf\plugin_portal_$($server.gameType)_$($server.gameServerId).ini"
    }
    
    end {
        
    }
}