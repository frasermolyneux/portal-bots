function Get-AccessToken {
    [CmdletBinding()]
    param (
        [string]$tenantId = 'e56a6947-bb9a-4a6e-846a-1f118d1c3a14',
        [string]$clientId,
        [string]$clientSecret,
        [string]$scope
    )
    
    begin {
        
    }
    
    process {
        $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
        $body = @{
            client_id     = $clientId
            scope         = $scope
            client_secret = $clientSecret
            grant_type    = "client_credentials"
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
        # Unpack Access Token
        $token = ($tokenRequest.Content | ConvertFrom-Json).access_token

        return $token
    }
    
    end {
        
    }
}