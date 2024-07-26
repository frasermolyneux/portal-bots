function Unregister-BotScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][object]$task
    )
    
    begin {
        Write-Host "Unregistering bot scheduled task: $($task.Name) from path $($task.Path)"
    }
    
    process {
        $task | Stop-ScheduledTask
        $task | Unregister-ScheduledTask
    }
    
    end {
        
    }
}