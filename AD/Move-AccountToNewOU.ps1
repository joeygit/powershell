################################################################# 
# This script will move bulk ad computer accounts into target OU 
# Specify the ou with the "$TargetOU" variable
# Put server list in the "$MoveList" variable path 
################################################################# 
 
#Importing AD Module 
Write-Host " Importing AD Module..... " 
import-module ActiveDirectory 
Write-Host " Importing Move List..... " 

# Reading list of computers from csv and loading into variable 
$MoveList = Import-Csv -Path "C:\Users\user\desktop\server_move_list.csv"
$OU_DN= ""
# defining Target Path 
$TargetOU = $OU_DN
if ((!($MoveList).count)){
    $countPC = 1
}
else{ 
    $countPC = ($movelist).count
}
Write-Host " Starting import computers ..." 
 
foreach ($Computer in $MoveList){     
    Write-Host " Moving Computer Account..."$Computer.'Server Name'  
    Get-ADComputer $Computer.'Server Name' | Move-ADObject -TargetPath $TargetOU
}

Write-Host " Completed Move List " 
 
Write-Host " $countPC  Computers have been moved "