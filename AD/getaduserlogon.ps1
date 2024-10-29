function Get-ADUserLastLogon([string]$userName, [string]$domain)
{
  if ($domain -eq "domain1" -OR $domain -eq "domain2")
  {
     $server = "domain1"
  }
  else
  {
     $server = "domain2"
  }

  $user = Get-ADUser $userName -Server $server | Get-ADObject -Properties lastLogontimeStamp 
  if($user.lastLogontimeStamp -gt $time) 
  {
    $time = $user.lastLogontimeStamp
  }
  if ($time -ne $null)
  {
    $dt = [DateTime]::FromFileTime($time)  
  }
  else
  {
   $dt = "Account last log on does not exist."
  }
  Write-Host $username "last logged on at:" $dt
}