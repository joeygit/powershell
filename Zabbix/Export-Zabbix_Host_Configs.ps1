# Zabbix API credentials
#$zabbixUrl = "http://192.168.16.105:8080/api_jsonrpc.php"
$zabbixUrl = "http://172.25.1.131:8080/api_jsonrpc.php"
$zabbixUser = "Admin"
$zabbixPassword = "pass"
$token = 'TOKEN'
$headers = @{Authorization = "Bearer $token"}
#$TEMPLATENAME = "TETRA - Acona Site Template"
# Define output directory
$outputDirectory = "C:\BayCloud\CooP Energy\ZabbixTemplates\HostConfigs"

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

function Get-TemplateHosts {
param (
        [string]$TEMPLATENAME
    )
    $templateParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "template.get"
        params = @{
            output = "extend"
            selectHosts = "extend"
            filter = @{
                name = $TEMPLATENAME
            }
        }
    }

    $templateJson = $templateParams | ConvertTo-Json

    $templateResp = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $templateJson -ContentType "application/json" -Headers $headers

    return $templateResp.result
}

function Export-HostConfig{
    param(
        [string]$hostID
    )
    $templateParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "configuration.export"
        params = @{
            format = "json"
            prettyprint = $true
            options = @{
                hosts = @(
                $hostID
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
        Write-Host $template.name
        $temphost = Get-TemplateHosts($template.name)
        $fullHostConfig = Export-HostConfig($temphost.hosts.hostid)
        #Write-Host $fullTemplate
        #$templateJson = $fullTemplate | ConvertTo-Json -Depth 10

        $templateName = $template.name -replace '[\\/:*?"<>|]', '_' # Replace invalid characters in file name
        $templateFileName = "$outputDirectory\$templateName-hostconfig.json"

        $fullHostConfig | Out-File -FilePath $templateFileName -Encoding UTF8
        Write-Host "Template " $template.Name " downloaded and saved as '$templateFileName'"
        $totalcount++
    }
    Write-Host "Total configs saved: " $totalcount
}
catch {
    Write-Host "Error occurred: $_"
    exit 1
}
