# 2/23/2016 - Joseph Nielson 
# This script uses the .NET FileSystemWatcher class to monitor file events in folder(s). 
# The script can be set to a wildcard filter, and IncludeSubdirectories can be changed to $true. 
#
 
# This is the folder that will be monitored for file additions.
$folder = 'D:\' # Enter the root path you want to monitor.
# log file location
$log_file_path = 'D:\path\alert_log_file.txt'
#clear the log file each time the script starts up
if (Test-Path $log_file_path)
{
   Clear-Content $log_file_path
}
# We want to monitor the directory for ANY file that is placed there, valid or not.
$filter = '*.*'  # You can enter a wildcard filter here. 
 
# In the following line, you can change 'IncludeSubdirectories to $true if required.                           
$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $false;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 

# variables for smtp emailing
$From = "from"
$To = "toEmail" 
$smtpServer = "SNMP"

#Only watching for file creation, but deletes as well as changes can be monitored.
 
# Monitor the directory for new files created
# If anything is changed in the action block, then you need to run "Unregister-Event FileCreated",
# followed by running this script again to re-register for the events

try {
#check to see if the event Subscriber has already been created:
  if (!(Get-EventSubscriber -SourceIdentifier "FileCreated")){
  #Register the event subscription for creating files.
    Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action { 
      $name = $Event.SourceEventArgs.Name #System.String
      $changeType = $Event.SourceEventArgs.ChangeType 
      $timeStamp = $Event.TimeGenerated 
      Write-Host "The file '$name' was $changeType at $timeStamp" -fore green 
      Out-File -FilePath $log_file_path -Append -InputObject "The file '$name' was $changeType at $timeStamp"
      $sendEmail = $false

      # Checks if the file contains spaces 
      if ($name -match "\s")
      {
         $emailString += $name + " <b>contains spaces.<b/><br/>"+"`r`n"
         Write-host $emailString
         $sendEmail = $true
      }
      # Checks if the filename length is greater than 70.
      if ($name.Length -gt 70)
      {
         $emailString += $name + " <b>length is greater than 70 characters.<b/><br/>"+"`r`n"
         Write-host $emailString
         $sendEmail = $true
      }
      # Checks if the file is of type xls or xlsx
      if (-not($name -like "*xls" -or $name -like "*xlsx"))
      {
         $emailString += $name + " <b>is not of type xls or xlsx.<b/><br/>"+"`r`n"
         Write-host $emailString
         $sendEmail = $true
      }
      # Checks if the file is a shortcut.
      if ($name -like "*.lnk")
      {
         $emailString += $name + " <b>is a shortcut link.<b/><br/>"+"`r`n"
         Write-host $emailString
         $sendEmail = $true
      }
      if ($sendEmail)
      {
         write-host "Sending Email..."
         Send-MailMessage -From $From -To $To -Subject "K2MS986 Incorrect File format"`
                   -SmtpServer $smtpServer -BodyAsHtml -body $emailString
         $emailString = ""
      }
     }
  }#Endif

 # If a non-terminating error is thrown for starting the file watcher, need to check it here and throw an exception.
  if (!($?))
  {
    throw $error[0].Exception
  } 
}#end Try

Catch
{
  $ErrorMessage = $_.Exception.Message
  Write-host -ForegroundColor Red "!!!Exception Caught on file watch running MTK_PLU_validate.ps1...!!!"
  $emailString = "<p><b>!!!Exception Caught on filewatch running filewatch.ps1...!!!<b/></p>" + $ErrorMessage+`
                        "`r`n" +"Please Check to see if the File watcher is running on this server."
  Send-MailMessage -From $From -To $To -Subject "PLU validation Script Error"`
                   -SmtpServer $smtpServer -BodyAsHtml -body $emailString
  exit 1 
}


# To stop the monitoring, run the following command: 
# Unregister-Event FileCreated 

