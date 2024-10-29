$zabbixUrl = "http://172.25.1.31:8080/api_jsonrpc.php"
$zabbixUser = "Admin"
$zabbixPassword = "PASS"
$token = 'TOKEN'
$headers = @{Authorization = "Bearer $token"}


# Date range for the past two weeks
$startDate = (Get-Date).AddDays(-14).ToUniversalTime()
$endDate = (Get-Date).AddDays(-12).ToUniversalTime()

# Convert to Unix timestamp
$startTimeUnix = [Math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End $startDate).TotalSeconds)
$endTimeUnix = [Math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End $endDate).TotalSeconds)


function Get-ZabProblems{
$problemParams = @{
        jsonrpc = "2.0"
        method  = "event.get"
        params  = @{
            output       = "extend"
            selectTags   = "extend"
            time_from    = $startTimeUnix
            time_till    = $endTimeUnix
            sortfield    = "clock"
            sortorder    = "DESC"
            limit        = 20000   # Adjust limit based on your requirements
        }
        auth = $authToken
        id   = 1
    }
    $problemResponse = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body ($problemParams | ConvertTo-Json) -ContentType "application/json" -Headers $headers
    return $problemResponse.result
}

$probs = Get-ZabProblems
$probs.count
$csv = "C:\Users\joen\Desktop\alerts2.csv"
foreach ($prob in $probs)
{
    $dateTime = (Get-Date "1970-01-01").AddSeconds($prob.clock)
    $info = [PSCustomObject]@{
        'name' = $prob.name
    'datetime' =$dateTime
    }

        # Add the new columns to the current row
    $info | Export-Csv -Path $csv -Append -NoTypeInformation

}