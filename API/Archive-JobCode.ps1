$token = "TOKEN"
$headers = @{Authorization = "Bearer $token"}
    
$POST_jobcode_url = "https://rest.tsheets.com/api/v1/jobcodes"
$jobcode = '85472'
$jobcodes = Import-Csv -Path "C:\Users\joen\Desktop\closedjobs.csv"
$job = $jobcodes[2].Num
foreach ($job in $jobcodes){
    $jobcode = $job.Num
    $get_child_job_url = "https://rest.tsheets.com/api/v1/jobcodes?name=*$jobcode*"

    $child_job_response = Invoke-RestMethod -Uri $get_child_job_url -Headers $headers -ContentType "application/json"

    $child_id = $child_job_response.results.jobcodes | Get-Member | Where {$_.MemberType -eq 'NoteProperty' } | select -Property Name
    $child_id = $child_id.Name
    if ($child_job_response -ne $null)
    {
        $objBody = @(  
            @{
                "active" = "false"
                "id" = $child_id
            }
        )
        $objBody = [PSCustomObject]@{
        "data" = $objBody}
        $jsonBody = $objBody | ConvertTo-JSON
        $result = Invoke-RestMethod -Method PUT -Uri $POST_jobcode_url -Headers $headers -ContentType "application/json" -Body $jsonBody
        $result.results.jobcodes.1
    }
    else{
    Write-Host "Job ticket DNE - " $jobcode
    }

}

