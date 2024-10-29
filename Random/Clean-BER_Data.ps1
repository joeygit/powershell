$BER_Path =  "C:\BER\"
$BER_Out_File_Path = "C:\CLEAN\BER\CLEAN_BER_quotes.csv" 
$BER_NoQuotes ="C:\CLEAN\BER\CLEAN_BER.csv" 
#$database_BER_Path = "/gis/BER/CLEAN"
#$credential = Get-Credential

$BER_Files = Get-ChildItem -Path $BER_Path
$file_ct = 1
Foreach ($ber_file in $BER_Files)
{
   
    if ($file_ct = 1)
    {
        $BER_Data += Get-Content -Path $ber_file.FullName | Select-Object -Skip 3 | `
        ConvertFrom-Csv -Header DATE,TIME,LATITUDE,LONGITUDE,LA,MCN,RSSI,BER -Delimiter ',' | Select LATITUDE,LONGITUDE,LA,RSSI,BER
    }
    else
    {
        $BER_Data += Get-Content -Path $ber_file.FullName |Select-Object -Skip 4 | `
        ConvertFrom-Csv -Header DATE,TIME,LATITUDE,LONGITUDE,LA,MCN,RSSI,BER -Delimiter ',' | Select LATITUDE,LONGITUDE,LA,RSSI,BER
    }

    $file_ct++
}
#Add custom columns for no BER data

$BER_TO_RSSI = @{
-120	=	50.00
-119	=	23.32
-118	=	21.10
-117	=	18.93
-116	=	16.85
-115	=	14.90
-114	=	13.11
-113	=	11.48
-112	=	10.0000
-111	=	8.7000
-110	=	7.7500
-109	=	6.51
-108	=	5.6100
-107	=	4.8100
-106	=	4.0400
-105	=	3.7300
-104	=	3.3700
-103	=	2.8900
-102	=	2.7200
-101	=	2.3900
-100	=	2.1400
-99	=	1.8300
-98	=	1.5300
-97	=	1.3300
-96	=	1.1100
-95	=	0.9500
-94	=	0.7900
-93	=	0.7000
-92	=	0.6400
-91	=	0.5600
-90	=	0.4700
-89	=	0.4000
-88	=	0.3500
-87	=	0.3500
-86	=	0.3200
-85	=	0.2900
-84	=	0.2700
-83	=	0.2500
-82	=	0.2400
-81	=	0.2100
-80	=	0.2000
-79	=	0.1900
-78	=	0.1800
-77	=	0.1700
-76	=	0.1700
-75	=	0.1500
-74	=	0.1400
-73	=	0.1100
-72	=	0.1200
-71	=	0.1000
-70	=	0.1100
-69	=	0.1000
-68	=	0.0900
-67	=	0.0800
-66	=	0.0800
-65	=	0.0700
-64	=	0.0500
-63	=	0.0500
-62	=	0.0500
-61	=	0.0500
-60	=	0.0400
-59	=	0.0400
-58	=	0.0300
-57	=	0.0300
-56	=	0.0300
-55	=	0.0300
-54	=	0.0200
-53	=	0.0200
-52	=	0.0200
-51	=	0.0200
-50	=	0.0200
-49	=	0.0200
-48	=	0.0100
-47	=	0.0200
-46	=	0.0100
-45	=	0.0200
-44	=	0.0100
-43	=	0.0100
-42	=	0.0100
-41	=	0.0100
-40	=	0.0200
-39	=	0.0100
-38	=	0.0200
-37	=	0.0100
-36	=	0.0100
-35	=	0.0200
-34	=	0
-33	=	0.0200
-32	=	0.0100
-31	=	0
-30	=	0
-29	=	0
-28	=	0.0200
-27	=	0
-26	=	0
-25	=	0.0100
-24	=	0
-23	=	0

}

foreach ($row in $BER_Data)
{
   if ($row.BER -eq '-') #filter rows based on no BER
   {
    Add-Member -InputObject $row -MemberType NoteProperty -Name 'BER_NO_MOD' -Value '' -Force
    Add-Member -InputObject $row -MemberType NoteProperty -Name 'INFO' -Value '1' -Force
    #Add-Member -InputObject $row -MemberType NoteProperty -Name 'BER' -Value $BER_TO_RSSI[$row.RSSI] -Force
    $row.BER = $BER_TO_RSSI[[int]$row.RSSI]
   }
   else #BER exists so no need to add info = 1
   {
    Add-Member -InputObject $row -MemberType NoteProperty -Name 'BER_NO_MOD' -Value $row.BER -Force
    Add-Member -InputObject $row -MemberType NoteProperty -Name 'INFO' -Value '' -Force
   }
}


$BER_Data | Export-Csv -Path $BER_Out_File_Path -NoTypeInformation

Import-Csv $BER_Out_File_Path | ConvertTo-CSV -NoTypeInformation | % { $_ -Replace '"', ""} | Out-File $BER_NoQuotes -fo -en ascii
$BER_Data = $null

