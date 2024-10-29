param(
    [string]$computerName,
    [System.Threading.Mutex]$mutex,
    [string]$DateTime = "yyyy-MM-dd_HH-mm-ss"
)
$ExportPath = "\\path\Scripts\Hotfix_Check\Logs\Hotfix_Check_$DateTime.csv"

#test conn
    if (Test-Connection -ComputerName $computerName -Count 1 -Quiet)
    {
        #try
        try{
            $hotfixStatus = Invoke-command -ComputerName $computerName -Scriptblock {get-hotfix -Id "kb3000483"}
            if ($hotfixStatus)
            { 
                 $Output = [PSCustomObject]@{
                    ComputerName = $computerName
                    HotfixStatus = "installed"
                    }
            }
            else
            {
                $Output = [PSCustomObject]@{
                    ComputerName = $computerName
                    HotfixStatus = "not installed"
                    } 
            }

        <#   $Var = $true
        do {
        try {
            $Output | Export-Csv -Path $ExportPath -Append -NoTypeInformation   
            "Successfully wrote to file."
            $Var = $true
        }
        catch {
            "Unable to write to file."
            $Var = $false
            sleep -Seconds 2
        }
        } while ($Var -eq $false) #>
     }   
     Catch{
        Write-Warning "Caught: $_"
         "ERROR"
         }
         #catch
         <#$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
         $name = 'PendingFileRenameOperations'
         {Get-ItemProperty -Path $using:path -Name $using:name}
         $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computerName)      
        $regKey = $reg.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\AutoUpdate")      
        write-host $regkey
        if($regkey -ne $null){
	        Write-Output "Y"
            $computerName + " Y" >> $rebootStatus
	    }
        else{
	        Write-Output "N"
            $computerName + " N" >> $rebootStatus
        }#END IF #>
    }
    else{
        "Could not connect to: $computerName"
        $Output = [PSCustomObject]@{
                    ComputerName = $computerName
                    HotfixStatus = "Computer Offline"
                    } 
    }
$Output
if ($mutex.WaitOne()){
    "Writing to file"
    $Output | Export-Csv -Path $ExportPath -Append -NoTypeInformation
    $mutex.ReleaseMutex()
}
else {
    "waiting"
}