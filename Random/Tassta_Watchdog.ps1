# Configuration
$logFilePath = "C:\temp\File.log"
#$serviceName = "Tbridge"
$serviceName = "Anydesk"
$smtpServer = "smtp.gmail.com"
$emailSmtpServerPort = "587"
$emailSmtpUser = ""
$emailSmtpPass = "pass"
$smtpFrom = ""
$smtpTo = ""

$mailSubjectSuccess = "T.bridge Service Successfully Restarted"
$mailSubjectFailure = "T.bridge Service Restart Not Successful. Action Needed"

# Function to send email
function Send-Email {
    param (
        [string]$Subject,
        [string]$Body
    )

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($emailSmtpUser, $emailSmtpPass)
    $message = New-Object Net.Mail.MailMessage($smtpFrom, $smtpTo)
    $message.Subject = $Subject
    $message.Body = $Body
    $smtp.Send($message)
}

# Function to restart T.bridge service
function Restart-ServiceAndWait {
    param (
        [string]$ServiceName,
        [int]$WaitTimeInSeconds
    )

    Restart-Service -Name $ServiceName
    Start-Sleep -Seconds $WaitTimeInSeconds
}

# Monitoring loop
while ($true) {
    # Check the log file for the specified string
    $logContent = Get-Content -Path $logFilePath -Raw
    if ($logContent -match "dkeep alive error") {
        # Send email about CNC reboot detected
        Send-Email -Subject "CNC Reboot Detected" -Body "Restarting Tbridge service"

        # Restart T.bridge service
        Restart-ServiceAndWait -ServiceName $serviceName -WaitTimeInSeconds 5

        # Check the status of T.bridge service
        $serviceStatus = Get-Service -Name $serviceName
        if ($serviceStatus.Status -eq 'Running') {
            # Send email if service is successfully restarted
            Send-Email -Subject $mailSubjectSuccess -Body "T.bridge service successfully restarted"
        } else {
            # Send email if service restart is not successful
            Send-Email -Subject $mailSubjectFailure -Body "T.bridge service restart not successful. Action needed"
        }

        # Wait for 10 seconds before continuing monitoring
        Start-Sleep -Seconds 10
    } else {
        # Wait for 10 seconds before checking the log file again
        Start-Sleep -Seconds 10
    }
}
