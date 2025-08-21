function Get-BotEnabledServers {
    [CmdletBinding()]
    param (
        [string]$uri,
        [string]$accessToken,
        [string]$subscriptionKey
    )
    
    begin {
        
    }
    
    process {
        $params = @{
            Uri            = $uri + "?filter=BotEnabled&takeEntries=50&skipEntries=0"
            Authentication = "Bearer"
            Token          = $accessToken | ConvertTo-SecureString -AsPlainText -Force
            Headers        = @{
                "Ocp-Apim-Subscription-Key" = $subscriptionKey
            }
        }

        $response = Invoke-RestMethod @Params
        $servers = $response.data.items

        return $servers
    }
    
    end {
        
    }
}