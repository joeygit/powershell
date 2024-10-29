$zabbixUrl = "http://172.25.1.131:8080/api_jsonrpc.php"
$zabbixUser = "Admin"
$zabbixPassword = "PASS"
$token = 'TOKEN'
$headers = @{Authorization = "Bearer $token"}

# Item Search Parameters
$hostname = "your_hostname"
$itemKey = "your_item_key" # e.g., "net.if.ip[eth0]"

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

    # Get Host ID
    $hostParams = @{
        jsonrpc = "2.0"
        method  = "host.get"
        params  = @{
            output = "extend"
            filter = @{
                host = $hostname
            }
        }
        id   = 2
    }
    $hostResponse = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body ($hostParams | ConvertTo-Json) -ContentType "application/json" -Headers $headers
     

$templates = Get-Templates
    $TETRAtemplates = $templates | Where-Object { $_.Name -like "*TETRA*" } | Select-Object -ExpandProperty Name #-Last 15
    foreach ($template in $TETRAtemplates)
    {
        Write-Host -ForegroundColor Yellow "checking items for: " $template

        $HostsResp = Get-TemplateHosts -TEMPLATENAME $template
        $hostid = $HostsResp.hosts[0].hostid
        #Write-Output $hostid
        if ($hostid) {
        # Get Item ID
        $itemParams = @{
            jsonrpc = "2.0"
            method  = "item.get"
            params  = @{
                output = "extend"
                hostids = $hostId

            }
            id   = 3
        }
        $itemResponse = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body ($itemParams | ConvertTo-Json) -ContentType "application/json" -Headers $headers

        if ($itemResponse.result) {
            foreach ($item in $itemResponse.result) {
                $interfaceId = $item.interfaceid

                # Get Interface IP
                $interfaceParams = @{
                    jsonrpc = "2.0"
                    method  = "hostinterface.get"
                    params  = @{
                        output = "extend"
                        interfaceids = $interfaceId
                    }
                    id   = 4
                }
                $interfaceResponse = Invoke-RestMethod -Uri $zabbixUrl -Method Post -Body ($interfaceParams | ConvertTo-Json) -ContentType "application/json" -Headers $headers

                if ($interfaceResponse.result) {
                    $interfaceIp = $interfaceResponse.result[0].ip
                    Write-Host $($item.name): $interfaceIp
                    if ($item.name -like '*Redundant*' -and $interfaceIp -ne '172.20.127.11')
                    {
                        Write-Host -ForegroundColor Red "Incorrect interface assigned: "$($item.name): $interfaceIp
                    }
                    elseif ($item.name -notlike '*Redundant*' -and $interfaceIp -ne '172.20.127.1')
                    {
                        Write-Host -ForegroundColor Red "Incorrect interface assigned: "$($item.name): $interfaceIp
                    }
                    #Write-Host "IP address for $($item.name): $interfaceIp"
                } else {
                    Write-Host "Failed to get interface IP for $($item.name)"
                }
            }
        } else 
        {
            Write-Host "No items found for the specified key ($itemKey)"
        }
    }
    else
    {
        Write-Host "Failed to get host ID for $hostname"
    }
    }

    


