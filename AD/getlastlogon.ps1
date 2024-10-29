$accounts = Get-Content "C:\Users\Tkmaxk1\Desktop\accounts.txt"
foreach ($account in $accounts){

$PWstamp = Get-ADUser $account  -Server "st.ad.kohls.com" -properties PasswordLastSet | Select -Property PasswordLastset
write-host $account " " $PWstamp.PasswordLastset

}