function Register-BotScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][object]$server,
        [string]$installDirectory
    )
    
    begin {
        
    }
    
    process {
        Write-Host "Configuring bot for server: $($server.title)"

        $action = New-ScheduledTaskAction -Execute "$installDirectory\b3.exe" -Argument "-c $installDirectory\conf\$($server.gameServerId).ini" -WorkingDirectory $installDirectory
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
        $principal = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
        $settings = New-ScheduledTaskSettingsSet
        $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
        
        $registeredTask = Register-ScheduledTask "\Bots\$($server.gameServerId)" -InputObject $task

        Write-Host $registeredTask
    }
    
    end {
        
    }
}