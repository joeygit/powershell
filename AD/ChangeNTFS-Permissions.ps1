#Remove Inheritance from a folder
# "e$\remoteware\nodesys\rwcinit.exe"
# "e$\jboss\bin\jbosssvc.exe"



param(
    [string]$ComputerName,   
    [string]$DateTime = "yyyy-MM-dd_HH-mm-ss"
)
$computerName

$LogPath = "\\path\Joe\Scripts\SetNTFS-Permissions\LogFile_$DateTime.csv"
if (Test-Connection -ComputerName $computerName -Count 1 -Quiet)
{
    try{
        $NodeSysPath = "\\$computerName\e$\remoteware\nodesys"
        Disable-NTFSAccessInheritance $NodesysPath
        Remove-NTFSAccess -Path $NodesysPath -Account "NT Authority\Authenticated Users" -AccessRights Modify
        Add-NTFSAccess -Path $NodesysPath -Account "NT Authority\Authenticated Users" -AccessRights Read
        Get-Ntfsaccess $NodesysPath -Account "NT Authority\Authenticated Users"

        $BinPath = "\\$computerName\e$\jboss\bin"
        Disable-NTFSAccessInheritance $BinPath
        Remove-NTFSAccess -Path $BinPath -Account "NT Authority\Authenticated Users" -AccessRights Modify
        Add-NTFSAccess -Path $BinPath -Account "NT Authority\Authenticated Users" -AccessRights Read
        #Get-Ntfsaccess $BinPath -Account "NT Authority\Authenticated Users"
        write-host "Permissions Changed Successfully on: $computerName" -ForegroundColor Green
        $Output = [PSCustomObject]@{
                    ComputerName = $computerName
                    PermissionsStatus = "Permissions Changed Successfully"
                    }
        $Output | Export-Csv -Path $LogPath -Append -NoTypeInformation 
    }
    Catch{
    write-host "Error while changing permissions on: $computerName" -ForegroundColor Red
        Write-Warning "Caught: $_"
        $Output = [PSCustomObject]@{
            ComputerName = $computerName
            PermissionsStatus = "ERROR: $_"
            }
        $Output | Export-Csv -Path $LogPath -Append -NoTypeInformation
    }
}
else{
        write-host "Could not connect to: $computerName" -ForegroundColor Yellow
        $Output = [PSCustomObject]@{
                    ComputerName = $computerName
                    PermissionsStatus = "Computer Offline"
                    }
        $Output | Export-Csv -Path $LogPath -Append -NoTypeInformation 
    }
