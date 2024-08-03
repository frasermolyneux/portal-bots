function Unregister-BotScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][object]$task
    )
    
    begin {
        
    }
    
    process {
        Write-Host "Unregistering bot scheduled task: '$($task.TaskName)' from path '$($task.TaskPath)'"
        $task | Unregister-ScheduledTask -Confirm:$false
    }
    
    end {
        
    }
}