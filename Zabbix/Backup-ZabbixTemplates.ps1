# Zabbix API credentials
#$zabbixUrl = "http://192.168.16.105:8080/api_jsonrpc.php"
$zabbixUrl = "http://172.25.1.131:8080/api_jsonrpc.php"
$zabbixUser = "Admin"
$zabbixPassword = "PASS"
$token = 'PASS'
$headers = @{Authorization = "Bearer $token"}
#$TEMPLATENAME = "TETRA - Acona Site Template"
# Define output directory
$outputDirectory = "C:\BayCloud\CooP Energy\ZabbixTemplates"

function Get-Templates{
    $templateParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "template.get"
        params = @{
            output = "extend"
        }
    }

    $templateJson = $templateParams | ConvertTo-Json

    $templateResp = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $templateJson -ContentType "application/json" -Headers $headers

    return $templateResp.result
}

function Export-Template{
    param(
        [string]$templateID
    )
    $templateParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "configuration.export"
        params = @{
            format = "json"
            prettyprint = $true
            options = @{
                templates = @(
                $templateID
                )
            }
        }
    }

    $templateJson = $templateParams | ConvertTo-Json -Depth 10

    $templateResp = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $templateJson -ContentType "application/json" -Headers $headers

    return $templateResp.result
}

$macroMap = @{}
$totalcount = 0
try {
    $templates = Get-Templates
    Write-Host $templates.Count
    $TETRAtemplates = $templates | Where-Object { $_.Name -like "*TETRA*" } | Select-Object Name, templateid #-Last 2
    foreach ($template in $TETRAtemplates)
    {
        #$templateName = $template.name
        Write-Host $template.templateid
        $fullTemplate = Export-Template($template.templateid)
        #Write-Host $fullTemplate
        #$templateJson = $fullTemplate | ConvertTo-Json -Depth 10

        $templateName = $template.name -replace '[\\/:*?"<>|]', '_' # Replace invalid characters in file name
        $templateFileName = "$outputDirectory\$templateName.json"

        $fullTemplate | Out-File -FilePath $templateFileName -Encoding UTF8
        Write-Host "Template " $template.Name " downloaded and saved as '$templateFileName'"
        $totalcount++
    }
    Write-Host "Total Templates saved: " $totalcount
}
catch {
    Write-Host "Error occurred: $_"
    exit 1
}
