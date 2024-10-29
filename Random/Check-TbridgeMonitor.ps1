

# Define process name and window title
$processName = "YourProcessName"
$windowTitle = "Tbridge Monitor"

# Check if the process is running
$runningProcess = Get-Process | Where-Object { $_.MainWindowTitle -eq $windowTitle }

if ($runningProcess) {
    # If the process is running, quit
    Write-Host "Process '$processName' with MainWindowTitle '$windowTitle' is already running. Exiting."
} else {
    # If the process is not running, send an email
    $smtpServer = ""
    $from = ""
    $to = ""
    $subject = "Tbridge Monitor Not Running"
    $body = "The Tbridge monitor process is not running. Log into the Tbridge server and restart."

function Send-Email {
    param (
        [string]$Subject,
        [string]$Body
    )

    $smtp = New-Object Net.Mail.SmtpClient($SmtpServer)
    #$smtp.EnableSsl = $true
    #$smtp.Credentials = New-Object System.Net.NetworkCredential($emailSmtpUser, $emailSmtpPass)
    $message = New-Object Net.Mail.MailMessage($From, $To)
    $message.Subject = $Subject
    $message.Body = $Body
    $smtp.Send($message)
}

    Send-Email -Subject $subject -Body $body

    Write-Host "Email sent: Process not running."
}
