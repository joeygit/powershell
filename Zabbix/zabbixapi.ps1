# Zabbix API credentials
#$zabbixUrl = "http://192.168.16.105:8080/api_jsonrpc.php"
$zabbixUrl = "http://172.25.1.31:8080/api_jsonrpc.php"
$zabbixUser = "Admin"
$zabbixPassword = "zabbix"
$token = 'token'
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
    $TETRAtemplates = $templates | Where-Object { $_.Name -like "*TETRA*" } | Select-Object -ExpandProperty Name -Last 7
    foreach ($template in $TETRAtemplates)
    {
        Write-Host "Updating triggers for template: " $template
        $templateResp = Get-TemplateTriggers -TEMPLATENAME $template
        $trigCount = 0
        foreach ($trigger in $templateResp[0].triggers) {
        #Write-Host $trigger.triggerid
            #if ($trigger.triggerid -eq "114660" -or $trigger.triggerid -eq "114606" -or $trigger.triggerid -eq "88770" -or $trigger.triggerid -eq "81067") {
                $triggerInfo = Get-TriggerTags -triggerId $trigger.triggerid
                $tagKeyVals = @{}
            
                foreach ($result in $triggerInfo) {
                    foreach ($tag in $result.tags) {
                        $tagKeyVals[$tag.tag] = $tag.value
                    }
                }
                $itemsDict = @{}
                $itemsResp = Get-TemplateItems -TEMPLATENAME $template
            
                foreach ($item in $itemsResp[0].items) {
                    $itemsDict[$item.name] = $item.key_

                }
                $element = $tagKeyVals["Element"]
                $eventId = $tagKeyVals["Event ID"]
                if ($element -eq 'BSR')
                {
                    $itemKey = $itemsDict['BSR Event Traps']
                    $itemKeyRed = $itemsDict['BSR Event Traps - Redundant']
                }
                if ($element -eq 'AMU')
                {
                    $itemKey = $itemsDict['AMU Event Traps']
                    $itemKeyRed = $itemsDict['AMU Event Traps - Redundant']
                }
                if ($element -eq 'IO-PLC')
                {
                    $itemKey = $itemsDict['IO-PLC Event Traps']
                    $itemKeyRed = $itemsDict['IO-PLC Event Traps - Redundant']
                }
                if ($element -eq 'LSC')
                {
                    $itemKey = $itemsDict['LSC Event Traps']
                    $itemKeyRed = $itemsDict['LSC Event Traps - Redundant']
                }
                if ($element -eq 'Remote SNI')
                {
                    $itemKey = $itemsDict['Remote SNI Event Traps']
                    $itemKeyRed = $itemsDict['Remote SNI Event Traps - Redundant']
                }
                if ($element -eq 'Central SNI')
                {
                    $itemKey = $itemsDict['Central SNI Event Traps']
                    $itemKeyRed = $itemsDict['Central SNI Event Traps - Redundant']
                }
                if ($element -eq 'MBS')
                {
                    $itemKey = $itemsDict['MBS Event Traps']
                    $itemKeyRed = $itemsDict['MBS Event Traps - Redundant']
                }
                if ($element -eq 'Multicoupler')
                {
                    $itemKey = $itemsDict['Multicoupler Event Traps']
                    $itemKeyRed = $itemsDict['Multicoupler Event Traps - Redundant']
                }
                if ($element -eq 'ASC')
                {
                    $itemKey = $itemsDict['ASC Event Traps']
                    $itemKeyRed = $itemsDict['ASC Event Traps - Redundant']
                }
                if ($element -eq 'ISDN Gateway')
                {
                    $itemKey = $itemsDict['ISDN Gateway Event Traps']
                    $itemKeyRed = $itemsDict['ISDN Gateway Event Traps - Redundant']
                }
                if ($element -eq 'Main CNC')
                {
                    $itemKey = $itemsDict['Main CNC Event Traps']
                    $itemKeyRed = $itemsDict['Main CNC Event Traps - Redundant']
                }
                if ($element -eq 'Main NMS')
                {
                    $itemKey = $itemsDict['Main NMS Event Traps']
                    $itemKeyRed = $itemsDict['Main NMS Event Traps - Redundant']
                }
                if ($element -eq 'Redundant CNC')
                {
                    $itemKey = $itemsDict['Redundant CNC Event Traps']
                    $itemKeyRed = $itemsDict['Redundant CNC Event Traps - Redundant']
                }
                if ($element -eq 'Redundant NMS')
                {
                    $itemKey = $itemsDict['Redundant NMS Event Traps']
                    $itemKeyRed = $itemsDict['Redundant NMS Event Traps - Redundant']
                }
                if ($element -eq 'Firewall')
                {
                    $itemKey = $itemsDict['Firewall Event Traps']
                    $itemKeyRed = $itemsDict['Firewall Event Traps - Redundant']
                }
                if ($element -eq 'Power Supply')
                {
                    $itemKey = $itemsDict['Power Supply Event Traps']
                    $itemKeyRed = $itemsDict['Power Supply Event Traps - Redundant']
                }
                if ($element -eq 'Power Supply')
                {
                    $itemKey = $itemsDict['Power Supply Event Traps']
                    $itemKeyRed = $itemsDict['Power Supply Event Traps - Redundant']
                }
                if ($element -eq 'Voice Recorder')
                {
                    $itemKey = $itemsDict['Voice Recorder Event Traps']
                    $itemKeyRed = $itemsDict['Voice Recorder Event Traps - Redundant']
                }
                if ($element -eq 'VoIP Gateway')
                {
                    $itemKey = $itemsDict['VoIP Gateway Event Traps']
                    $itemKeyRed = $itemsDict['VoIP Gateway Event Traps - Redundant']
                }
                #$formattedStr = "`${$element}"
                #Write-Host $trigger.triggerid
                $triggerString = @"
(find(/$template/$itemKey,,"regexp","NEBULA-MIB::infrAuxInfo.0\s*type=4\s*value=STRING:\s*.*($eventId).*$")=1 and  
nodata(/$template/$itemKey,4m)=0) or
(find(/$template/$itemKeyRed,,"regexp","NEBULA-MIB::infrAuxInfo.0\s*type=4\s*value=STRING:\s*.*($eventId).*$")=1 and  
nodata(/$template/$itemKeyRed,4m)=0)
"@
                #Write-Output $triggerString
                Set-TriggerExpression -triggerId $trigger.triggerid -expression $triggerString
                Write-Host -ForegroundColor Green "Trigger Updated: "$element "EventID: " $eventId
                $totalcount++
                $trigCount++
                
            }
        #}Write-Host -ForegroundColor Cyan $template " triggers updated: " $trigCount
    }
    Write-Host "Total triggers updated: " $totalcount
}
catch {
    Write-Host "Error occurred while fetching trigger tags: $_"
    exit 1
}
