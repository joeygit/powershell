# File patch to List of IP Addresses
$pingList = "C:\Users\tkmaxk1\Desktop\IP_list.txt"
# File patch for Host Name's to export
$HostNames = "C:\Users\tkmaxk1\Desktop\HostNames.txt"
if (Test-Path $HostNames){
Clear-content $HostNames}

$serverList = Get-Content $pingList
Foreach ($server in $serverList)
{
   try{
   $DNS = [System.Net.Dns]::GetHostEntry($server).HostName
   [System.Net.Dns]::GetHostEntry($server).Hostname
   Add-Content $HostNames $DNS 
   #write-host $DNS
   }
   catch [system.exception]
   {
    Add-Content $HostNames "No hostname for $server"
    write-host "No hostname for" $server
   } 
 }