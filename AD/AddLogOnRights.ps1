<#
Update:
Date
Author: Joe Nielson 
Name: 

Description: This script takes in a CSV list of accounts, and gives them log on permission for the
following servers:"

Currently the line to make the changes is commented out.

2016/06/15, BJH: Modified Set-ADUser to append to workstation list rather than replace list.
#>

$AccountList = Import-Csv -Path "pathtoCSV"

foreach ($Account in $AccountList)
{
   $Account.'Service Acct'
   $Filter = "SamAccountName -like '$($Account.'Service Acct')'"
   $ADAccount = Get-ADUser -Filter $Filter -Properties LogonWorkstations
   $CurrentWorkstationList = $ADAccount.LogonWorkstations
   $AdditionalWorkstationList = "listofservers"
   $CompleteWorkstationList = "{0},{1}" -f $CurrentWorkstationList, $AdditionalWorkstationList
   Set-ADUser -Identity $ADAccount -LogonWorkstations $CompleteWorkstationList -PassThru #-WhatIf
}