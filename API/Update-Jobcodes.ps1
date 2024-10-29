$ticket_org = 'ORG'
$ticket_title = 'TITLE'
$ticket_title_trimmed = $ticket_title.subString(0, [System.Math]::Min(50, $ticket_title.Length))
$ticket_number = '90452'
$time_ticket_title = $ticket_title_trimmed + " - $ticket_number"
$get_jobcodes_url = "https://rest.tsheets.com/api/v1/jobcodes?name=$ticket_org"
$POST_jobcode_url = "https://rest.tsheets.com/api/v1/jobcodes"
$token = "TOKEN"

$headers = @{Authorization = "Bearer $token"}
    
$response = Invoke-RestMethod -Uri $get_jobcodes_url -Headers $headers -ContentType "application/json"
$jobcode = $response.results.jobcodes | Get-Member | Where {$_.MemberType -eq 'NoteProperty' } | select -Property Name
$jobcode = $jobcode.Name


if ($response -ne $null)
{
    $objBody = @(  
        @{
            "name" = $time_ticket_title
            "parent_id" = $jobcode
            "billable" = "yes"
            "assigned_to_all" = "yes"
        }
    )
    $objBody = [PSCustomObject]@{
    "data" = $objBody}
    $jsonBody = $objBody | ConvertTo-JSON
    $result = Invoke-RestMethod -Method POST -Uri $POST_jobcode_url -Headers $headers -ContentType "application/json" -Body $jsonBody
}
$time_ticket_title = $ticket_title