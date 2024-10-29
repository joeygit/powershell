
$DateTime = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

$ExportPath = "D:\Reports\healthCheck_$Datetime.csv"
$HTML_ExportPath = "D:\Reports\HTML_Report_$Datetime.html"

add-pssnapin "Microsoft.EnterpriseManagement.OperationsManager.Client"
$CPOpsMgr = "mainserver"
$STOpsMgr = "mainserver"
new-managementGroupConnection -ConnectionString:$CPOpsMgr
Set-Location "OperationsManagerMonitoring::"
Set-Location $CPOpsMgr
$filter = "(&(objectCategory=computer)(operatingSystem=Windows Server*))"
$CPDomain = New-Object System.DirectoryServices.DirectoryEntry
$CPADsearcher = New-Object System.DirectoryServices.DirectorySearcher
$CPADsearcher.SearchRoot = $CPDomain
$CPADsearcher.PageSize = 1000 #This limits the result to 1000 objects to display
$CPADsearcher.Filter = $filter
$CPADsearcher.SearchScope = "Subtree" #Search entire OU trees
$CPADsearcher.PropertiesToLoad.Add("dnshostname")
$CPADresults = $CPADsearcher.FindAll()

$STDomain = New-Object System.DirectoryServices.DirectoryEntry("LDAP://st.ad.kohls.com")
$STADsearcher = New-Object System.DirectoryServices.DirectorySearcher
$STADsearcher.SearchRoot = $STDomain
$STADsearcher.PageSize = 1000 #This limits the result to 1000 objects to display
$STADsearcher.Filter = $filter
$STADsearcher.SearchScope = "Subtree" #Search entire OU trees
$STADsearcher.PropertiesToLoad.Add("dnshostname")
$STADresults = $STADsearcher.FindAll()


#$listcomputers = $adcomputers | Where-Object {$scomagents -notcontains $_} 

foreach ($result in $CPADresults)
{
    $ADcomputers += $result.Properties.dnshostname
}

foreach ($STresult in $STADresults)
{
    $ADcomputers += $STresult.Properties.dnshostname
}

$WCC = get-monitoringclass -name "Microsoft.SystemCenter.Agent"
#2012 = Get-SCOMAgent
$CPSCOMagents = Get-MonitoringObject -monitoringclass:$WCC | where {$_.IsAvailable -eq $true} | select DisplayName
#change location to ST
new-managementGroupConnection -ConnectionString:$STOpsMgr
Set-Location "OperationsManagerMonitoring::"
Set-Location $STOpsMgr
$STSCOMagents = Get-MonitoringObject -monitoringclass:$WCC | where {$_.IsAvailable -eq $true} | select DisplayName

$scomagents = $STSCOMagents + $CPSCOMagents

# Create header for HTML Report
$Head = "<style>"
$Head +="BODY{background-color:#CCCCCC;font-family:Verdana,sans-serif; font-size: small;}"
$Head +="TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; width: 98%;}"
$Head +="TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#293956;color:white;padding: 5px; font-weight: bold;text-align:left;}"
$Head +="TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#F0F0F0; padding: 2px;}"
$Head +="</style>"

$AgentTable = New-Object System.Data.DataTable "$AvailableTable" 
$AgentTable.Columns.Add((New-Object System.Data.DataColumn Name,([string]))) #Name 
#$AgentTable.Columns.Add((New-Object System.Data.DataColumn HealthState,([string]))) 
$AgentTable.Columns.Add((New-Object System.Data.DataColumn Ping_Status,([string]))) #Pingable
$AgentTable.Columns.Add((New-Object System.Data.DataColumn Monitored,([string]))) #Monitored 
$Total_Not_Monitored = 0
$Total_Not_Pingable = 0
foreach ($ADServerObject in $ADComputers)
{ 
    $FoundObject = $null 
    $Monitored = $null 
    $FoundObject = 0 
    $FoundObject = $scomagents | ? {$_.DisplayName -contains $ADServerObject} 
    if ($FoundObject -eq $null)
    {
        Write-Host -ForegroundColor Red "Failure: $ADServerObject is not Monitored"
        $Monitored = "No" 
        $Total_Not_Monitored++ 
    }
    else 
    { 
        Write-Host -ForegroundColor Green "$ADServerObject Server is Monitored"
        $Monitored = "Yes"
    }
     
######Check ping
    if (Test-Connection -computername $ADServerObject -count 1 -errorAction SilentlyContinue)
    {
        Write-Host -ForegroundColor Green "$ADServerObject Server is pingable"
        $pingStatus = "Success"
    }
    else
    {
        Write-Host -ForegroundColor Red "Failure: $ADServerObject is not pingable"
        $pingStatus = "Not Pingable"
        $Total_Not_Pingable++
    }

    $NewRow = $AgentTable.NewRow() 
    $NewRow.Name = ($ADServerObject)
    #$NewRow.HealthState = ($Agent.HealthState).ToString() 
    $NewRow.Ping_Status = $pingStatus
    $NewRow.Monitored = $Monitored
    $AgentTable.Rows.Add($NewRow) 
    $CSVOutput = [PSCustomObject]@{
        Name = $ADServerObject
        Ping_Status = $pingStatus
        Monitored = $Monitored
    } 
    $CSVOutput | Export-Csv -Path $ExportPath -Append -NoTypeInformation
} 

$ReportOutput += "<h2>Total Servers Not Monitored in SCOM: $Total_Not_Monitored</h2>"
$ReportOutput += "<h2>Total Servers Not Pingable in AD: $Total_Not_Pingable</h2>"

$ReportOutput += $AgentTable | Sort-Object Monitored | Select Name,Ping_Status,Monitored  | ConvertTo-HTML -fragment 


$Body = ConvertTo-HTML -head $Head -body "$ReportOutput" 

$Body | Out-File $HTML_ExportPath 

$ReportOutput = $null
$ADcomputers = $null
$Head = $null
$Body = $null
$CSVOutput = $null
$CPSCOMagents  = $null
$STSCOMagents  = $null
$scomagents = $null
#servers that are not in scom
#$NotMonitoredServers = $adcomputers | Where-Object {$scomagents -notcontains $_} 

#servers that are not pinging
#$notPingable = $adcomputers | Where-Object {}