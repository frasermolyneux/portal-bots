function Unregister-BotScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][object]$task
    )
    
    begin {
        
    }
    
    process {
        Write-Host "Unregistering bot scheduled task: $($task.Name) from path $($task.Path)"
        $task | Stop-ScheduledTask
        $task | Unregister-ScheduledTask
    }
    
    end {
        
    }
}