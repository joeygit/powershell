# Zabbix API credentials
#$zabbixUrl = "http://192.168.16.105:8080/api_jsonrpc.php"
$zabbixUrl = "http://172.25.1.31:8080/api_jsonrpc.php"
$zabbixUser = "Admin"
$zabbixPassword = "PASS"
$token = 'TOKEN'
$headers = @{Authorization = "Bearer $token"}
#$TEMPLATENAME = "TETRA - Acona Site Template"


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

function Get-TemplateTriggers {
    param (
        [string]$TEMPLATENAME
    )
    $templateParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "template.get"
        params = @{
            output = "extend"
            selectTriggers = "extend"
            filter = @{
                name = $TEMPLATENAME
            }
        }
    }

    $templateJson = $templateParams | ConvertTo-Json

    $templateResp = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $templateJson -ContentType "application/json" -Headers $headers

    return $templateResp.result
}

function Get-TriggerTags {
    param (
        [string]$triggerId
    )

    $triggerParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "trigger.get"
        params = @{
            output = "extend"
            selectTags = "extend"
            filter = @{
                triggerid = $triggerId
            }
        }
    }

    $triggerJson = $triggerParams | ConvertTo-Json

    $triggerInfo = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $triggerJson -ContentType "application/json" -Headers $headers

    return $triggerInfo.result
}

function Get-TemplateItems {
param (
        [string]$TEMPLATENAME
    )
    $templateParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "template.get"
        params = @{
            output = "extend"
            selectItems = "extend"
            filter = @{
                name = $TEMPLATENAME
            }
        }
    }

    $templateJson = $templateParams | ConvertTo-Json

    $templateResp = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $templateJson -ContentType "application/json" -Headers $headers

    return $templateResp.result
}


function Set-TriggerExpression {
    param (
        [string]$triggerId,
        [string]$expression
    )

    $triggerParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "trigger.update"
        params = @{
           triggerid = $triggerId
           expression = $expression
        }
    }

    $triggerJson = $triggerParams | ConvertTo-Json

    $triggerInfo = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $triggerJson -ContentType "application/json" -Headers $headers

    return $triggerInfo.result
}

function Set-TriggerCorrelationMode {
    param (
        [string]$triggerId
    )

    $triggerParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "trigger.update"
        params = @{
           triggerid = $triggerId
           correlation_mode = 0
        }
    }

    $triggerJson = $triggerParams | ConvertTo-Json

    $triggerInfo = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $triggerJson -ContentType "application/json" -Headers $headers

    return $triggerInfo.result
}

function Set-ItemHistory {
    param (
        [string]$itemId,
        [string]$expression
    )

    $triggerParams = @{
        id = 1
        jsonrpc = "2.0"
        method = "item.update"
        params = @{
           itemid = $itemId
           history = '3d'
        }
    }

    $triggerJson = $triggerParams | ConvertTo-Json

    $triggerInfo = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body $triggerJson -ContentType "application/json" -Headers $headers

    return $triggerInfo.result
}

$macroMap = @{}
$totalcount = 0
try {
    $templates = Get-Templates
    $TETRAtemplates = $templates | Where-Object { $_.Name -like "*TETRA*" } | Select-Object -ExpandProperty Name #-Last 2
    foreach ($template in $TETRAtemplates)
    {
        Write-Host -ForegroundColor Yellow "Updating triggers for template: " $template
        $templateResp = Get-TemplateTriggers -TEMPLATENAME $template
        $trigCount = 0
        foreach ($trigger in $templateResp[0].triggers) {
        
        if ($trigger.correlation_mode -eq 1)
        {
            #Set-TriggerCorrelationMode -triggerId $trigger.triggerid
            $totalcount++
            Write-Host -ForegroundColor Red $trigger.description
            Write-Host $trigger.triggerid "trigger corr mode: " $trigger.correlation_mode
        }

    }
    Write-Host "Total triggers updated: " $totalcount
    }
}
catch {
    Write-Host "Error occurred while fetching trigger tags: $_"
    exit 1
}

