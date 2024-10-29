<#
Update:
Date: 6/13/2016
Author: Joe Nielson 
Name: 

Description: This script will read in a CSV file, containing server names. And 
schedule a maitenance window for 20 minutes for each server. The CSV file must
have a header called "Server Name", and the names must be the FQDN. Also, this must
be ran on one of the management servers due to the SCOM snapin.

Let Joe Nielson know if there are any issues running the script.

Change the maintenance window duration with the "$minutes" variable.
The root management server variable "rootMS" also needs to be set accordingly.

#>

#>>>Set this properly as defined above:
$rootMS = "root"
#>>>Path to the CSV file which has the server names
$serverList = Import-Csv \\path\Joe\Scripts\SetMaintenanceMode\serverList.csv
#>>>Set the number of minutes to scheduled the maintenance window for
$minutes = '20'

#>>>Comment for the MM, this can be any text
$comment = "Maintenance Mode requested by app team"
#>>> reason See below link for other options:
#https://msdn.microsoft.com/en-us/library/microsoft.enterprisemanagement.monitoring.maintenancemodereason.aspx
$reason = "PlannedOther"

$location = get-location

Add-PSSnapin "Microsoft.EnterpriseManagement.OperationsManager.Client" -ErrorVariable errSnapin;
Set-Location "OperationsManagerMonitoring::" -ErrorVariable errSnapin;
new-managementGroupConnection -ConnectionString:$rootMS -ErrorVariable errSnapin;
set-location $rootMS -ErrorVariable errSnapin;

#>>>This will need to be changed if the windows computer object does not need
#>>>the maintenance window. (SQL, or IIS...etc)
$computerClass = get-monitoringclass -name:Microsoft.Windows.Computer

#Loop through the server list
ForEach ($server in $serverList){
    write-host $server
    $computerCriteria = "PrincipalName='" + $server.'Server Name' + "'"
    write-host $computerCriteria
    $computer = get-monitoringobject -monitoringclass:$computerClass -criteria:$computerCriteria
    write-host $computer
    $startTime = [System.DateTime]::Now
    $endTime = $startTime.AddMinutes($minutes)

    if($computer.InMaintenanceMode -eq $false)
    {
        "Putting " + $server.'Server Name' + " into maintenance mode"
  	    New-MaintenanceWindow -startTime:$startTime -endTime:$endTime -comment:$comment -Reason:$reason -monitoringObject:$computer	
    } 
}
Set-Location $location

