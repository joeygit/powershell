<#
.DESCRIPTION
   This PowerShell script monitors a log file (every 10 seconds) for a specific error message ("dkeep alive error").
    If the error is detected, it takes the following actions:
    - Sends an email alert stating "CNC disconnect has been detected."
    - Restarts the "tbridge" service
    - Renames the log file, appending the date of the last write time.
    - Sends a follow-up email stating whether the service restart was successful or not.
    - If there is no log file detected upon first start, it will wait for a log file to be created
    and continue checking every 5 minutes for it's existence.
    - This process will start up on the Tbridge server at every boot up. If any errors occur, it is set
    to terminate and send an email with the error.
.NOTES
   Version: 1.3
   Created on: 11/30/2023
   Created by: Joe Nielson
   Organization: Bay Electronics
   Filename: Tassta_LogFileMonitor.ps1
   The logfile being monitored is specified in the $logFilePath variable below.
   This process requires SMTP connectivity in order to send alert emails out.
   The SMTP settings are defined in the "Configuration Variables" section below
#>
#-----Configuration Variables------
#Tbridge logfile path that is being monitored
$logFilePath = "C:\Program Files (x86)\Bridge\Bridge-132\win64\tbridge.txt"
$logFileDir = "C:\Program Files (x86)\Bridge\Bridge-132\win64"
$oldLogFilePath = "C:\Program Files (x86)\Bridge\Bridge-132\win64\OldLogFiles"
$serviceName = "TASSTA Bridge 132"
$smtpServer = ""
$emailSmtpServerPort = "25"
$emailSmtpUser = ""
$emailSmtpPass = ""
$smtpFrom =""
$smtpTo = ""
$mailSubjectSuccess = "T.bridge Service Successfully Restarted"
$mailSubjectFailure = "T.bridge Service Restart Not Successful. Action Needed"
$ErrorActionPreference = 'Stop'
$loggingPath = "C:\Program Files (x86)\Bridge\Bridge-132\win64\LogFileMonitor_transcripts\transcript.log"
#variable for max file size
$maxFileSizeMB = 5
#----^-Configuration Variables---^---
$host.ui.RawUI.WindowTitle = "Tbridge Monitor"

if (Test-Path $loggingPath) {
        # Get the file extension
        $transcriptfile = Get-ChildItem $loggingPath
        $fileExtension = (Get-Item $loggingPath).Extension
         $logFileLastWrite = $transcriptfile.LastWriteTime.ToString("yyyy-MM-dd HH.mm.ss ddd")
        $newtranscriptName = $transcriptfile.BaseName + "_" + $logFileLastWrite + $transcriptfile.Extension
        #attempt to stop a transcript in case one is running (prevents  file rename)
                try{
            stop-transcript|out-null
        }
           catch [System.InvalidOperationException]{}
        Rename-Item -Path $loggingPath -NewName $newtranscriptName
        Write-Host "Transcript File renamed successfully. New file name: $newtranscriptName"

}

try{
Start-Transcript -Path $loggingPath -ErrorAction Stop
}
catch{
Start-Transcript -Path $loggingPath
}


# Test if log file exists. If not, wait and check every 5 minutes.
while (-not (Test-Path -Path $logFilePath)) {
    Write-Host -ForegroundColor Yellow "Log File not found. Waiting for 5 minutes..."
    Start-Sleep -Seconds 300  # 5 minutes
}

# Continue with the script
Write-Host -ForegroundColor Green "File found! Continue with the rest of the script."


# Function to send email
function Send-Email {
    param (
        [string]$Subject,
        [string]$Body
    )

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    #$smtp.EnableSsl = $true
    #$smtp.Credentials = New-Object System.Net.NetworkCredential($emailSmtpUser, $emailSmtpPass)
    $message = New-Object Net.Mail.MailMessage($smtpFrom, $smtpTo)
    $message.Subject = $Subject
    $message.Body = $Body
    $smtp.Send($message)
}

# Function to restart T.bridge service and rename log file and create new.
function Restart-ServiceAndWait {
    param (
        [string]$ServiceName,
        [int]$WaitTimeInSeconds
    )
    # Stop the Service
    Write-host -ForegroundColor Yellow "Waiting 30 seconds for CNC to stabilize..."
    Start-Sleep -Seconds 30
    Stop-Service -Name $ServiceName -Verbose
    # Rename the current log file and append the date
    Write-Host "Renaming current log file..."
    $logfile = Get-Item $logFilePath
    $logFileLastWrite = $logfile.LastWriteTime.ToString("yyyy-MM-dd HH.mm.ss ddd")
    $newLogName = $logfile.BaseName + "_" + $logFileLastWrite + $logfile.Extension
    Rename-Item -Path $logFilePath -NewName $newLogName
    $newlogFullPath = $logFileDir +"\" + $newLogName
    Move-Item -Path $newlogFullPath -Destination $oldLogFilePath -WhatIf
    Get-ChildItem -Path $newlogFullPath -Name $newLogName
    Write-Host "File renamed successfully. New file name: $newLogName"
    Start-Sleep -Seconds $WaitTimeInSeconds
    Write-Host -ForegroundColor Yellow "Restarting Tbridge Service..."
    Start-Service -Name $ServiceName -Verbose
}

# Monitoring loop
try{#Wrap in try/catch to grab any errors
    while ($true) {
        # Check the log file for the specified string
        $logContent = Get-Content -Path $logFilePath -Raw
        if ($logContent -like "*wsasend: An established connection was aborted by the software in your host machine.*" -or ` 
         $logContent -like "*wsarecv: A connection attempt failed because the connected party did not properly respond after a period of time*" -or `
         $logContent -like "*wsarecv: An existing connection was forcibly closed by the remote host*" ) {
            # Send email about CNC reboot detected
            Write-Host -ForegroundColor Red "CNC Disconnect Detected. Restarting Tbridge Service."
            Send-Email -Subject "CNC Reboot Detected" -Body "Restarting Tbridge service"

            # Restart T.bridge service
            Restart-ServiceAndWait -ServiceName $serviceName -WaitTimeInSeconds 5

            # Check the status of T.bridge service
            Write-Host "Checking T.bridge Service status..."
            $serviceStatus = Get-Service -Name $serviceName -Verbose
            if ($serviceStatus.Status -eq 'Running') {
                # Send email if service is successfully restarted
                Write-Host -ForegroundColor Green "Service: " $serviceStatus.Name " Status: " $serviceStatus.Status 
                Write-Host -ForegroundColor Green "T.bridge service successfully restarted."
                Write-Host -ForegroundColor Cyan "Continuing to monitor log file for errors..."
                Send-Email -Subject $mailSubjectSuccess -Body "T.bridge service successfully restarted"
            } else {
                # Send email if service restart is not successful
                Send-Email -Subject $mailSubjectFailure -Body "T.bridge service restart not successful. Action needed"
                Write-Host -ForegroundColor Red "Service: " $serviceStatus.Name " Status: " $serviceStatus.Status 
                Write-Host -ForegroundColor Red "ERROR: T.bridge service could not be started. Investigation needed."
            }

            # Wait for 10 seconds before continuing monitoring
            Start-Sleep -Seconds 10
        } else {
            # Wait for 10 seconds before checking the log file again
            Start-Sleep -Seconds 10
        }
    }

}#end Try

Catch
{
  $ErrorMessage = $_.Exception.Message
  Write-host -ForegroundColor Red $_.Exception
  Send-Email -Subject "Exception Caught On T.Bridge Tassta_LogFileMonitor process. Investigation needed" -Body $ErrorMessage
}
Stop-Transcript