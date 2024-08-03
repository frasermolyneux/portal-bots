function Register-BotScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][object]$server,
        [string]$installDirectory
    )
    
    begin {
        
    }
    
    process {
        Write-Host "Configuring bot scheduled task for server: '$($server.title)'"

        $action = New-ScheduledTaskAction -Execute "$installDirectory\b3.exe" -Argument "-c $installDirectory\conf\$($server.gameType)_$($server.gameServerId).ini" -WorkingDirectory $installDirectory
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
        $principal = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
        $settings = New-ScheduledTaskSettingsSet
        $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
        
        $registeredTask = Register-ScheduledTask "\Bots\$($server.title)_$($server.gameServerId)" -InputObject $task

        Write-Host "Registered bot scheduled task: '$($registeredTask.TaskName)' in path '$($registeredTask.TaskPath)'"
    }
    
    end {
        
    }
}