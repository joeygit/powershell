function Invoke-MultiThreading {

    Param($Command = $(Read-Host "Enter the script file"), 
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]$ObjectList,
        $InputParam = $Null,
        $MaxThreads = 20,
        $SleepTimer = 200,
        $MaxResultTime = 120,
        [HashTable]$AddParam = @{},
        [Array]$AddSwitch = @()
    )

    Begin{
        $ISS = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $ISS, $Host)
        $RunspacePool.Open()
        
        If ($(Get-Command | Select-Object Name) -match $Command){
            $Code = $Null
        }Else{
            $OFS = "`r`n"
            $Code = [ScriptBlock]::Create($(Get-Content $Command))
            Remove-Variable OFS
        }
        $Jobs = @()
    }

    Process{
        Write-Progress -Activity "Preloading threads" -Status "Starting Job $($jobs.count)"
        ForEach ($Object in $ObjectList){
            If ($Code -eq $Null){
                $PowershellThread = [powershell]::Create().AddCommand($Command)
            }Else{
                $PowershellThread = [powershell]::Create().AddScript($Code)
            }
            If ($InputParam -ne $Null){
                $PowershellThread.AddParameter($InputParam, $Object.ToString()) | out-null
            }Else{
                $PowershellThread.AddArgument($Object.ToString()) | out-null
            }
            ForEach($Key in $AddParam.Keys){
                $PowershellThread.AddParameter($Key, $AddParam.$key) | out-null
            }
            ForEach($Switch in $AddSwitch){
                $Switch
                $PowershellThread.AddParameter($Switch) | out-null
            }
            $PowershellThread.RunspacePool = $RunspacePool
            $Handle = $PowershellThread.BeginInvoke()
            $Job = "" | Select-Object Handle, Thread, object
            $Job.Handle = $Handle
            $Job.Thread = $PowershellThread
            $Job.Object = $Object.ToString()
            $Jobs += $Job
        }
        
    }

    End{
        $ResultTimer = Get-Date
        While (@($Jobs | Where-Object {$_.Handle -ne $Null}).count -gt 0)  {
    
            $Remaining = "$($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False}).object)"
            If ($Remaining.Length -gt 60){
                $Remaining = $Remaining.Substring(0,60) + "..."
            }
            Write-Progress `
                -Activity "Waiting for Jobs - $($MaxThreads - $($RunspacePool.GetAvailableRunspaces())) of $MaxThreads threads running" `
                -PercentComplete (($Jobs.count - $($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False}).count)) / $Jobs.Count * 100) `
                -Status "$(@($($Jobs | Where-Object {$_.Handle.IsCompleted -eq $False})).count) remaining - $remaining" 

            ForEach ($Job in $($Jobs | Where-Object {$_.Handle.IsCompleted -eq $True})){
                $Job.Thread.EndInvoke($Job.Handle)
                $Job.Thread.Dispose()
                $Job.Thread = $Null
                $Job.Handle = $Null
                $ResultTimer = Get-Date
            }
            If (($(Get-Date) - $ResultTimer).totalseconds -gt $MaxResultTime){
                Write-Error "Child script appears to be frozen, try increasing MaxResultTime"
                Exit
            }
            Start-Sleep -Milliseconds $SleepTimer
        
        } 
        $RunspacePool.Close() | Out-Null
        $RunspacePool.Dispose() | Out-Null
    } 
}


cd "\\path\Joe\Scripts\SetNTFS-Permissions"

$DateTime = Get-Date -format "yyyy-MM-dd_HH-mm-ss"

#$computerList = get-content "\\path\Joe\Scripts\Hotfix_Check\computerList.txt"
$computerList = get-content "\\path\Joe\Scripts\SetNTFS-Permissions\computerList.txt"

New-Item "\\path\Joe\Scripts\SetNTFS-Permissions\LogFile_$DateTime.csv" -type file
#$mtx = New-Object System.Threading.Mutex($false, "TestMutex")
#with mutex, Dont forget the dispose below
#$computerList | Invoke-MultiThreading -Command "Hotfix_Check.ps1" -InputParam ComputerName -AddParam @{"mutex" = $mtx; "DateTime" = $DateTime} -MaxThreads 50

#without mutex
$computerList | Invoke-MultiThreading -Command "ChangeNTFS-Permissions.ps1" -InputParam ComputerName -AddParam @{"DateTime" = $DateTime} -MaxThreads 50


#$mtx.Dispose()
