$outFile = "C:\Users\user\Desktop\CP-admin_password_Last_Set.csv"
$Admins = Get-ADGroupMember -Identity 'Domain Admins' -Server serverName
foreach ($admin in $Admins){
     if ($admin.objectClass -eq "user")
     {
       [PSCustomObject]@{
         Name = $admin.Name
         Password_Last_Changed = ($admin | Get-AdUser -Properties PasswordLastSet).PasswordLastSet
         username = $User
         } | Export-Csv -Path $outFile -Append
     }
    }