
$PESQ_Path = "C:\PESQ"
$PESQ_Out_File_Path = "C:\CLEAN\PESQ\CLEAN_PESQ_quotes.csv"
$PESQ_No_Quotes = "C:\CLEAN\PESQ\CLEAN_PESQ.csv" #"C:\Users\joen\Desktop\postgis\redrive_data\PESQ\CLEAN_PESQ.csv" #"C:\Users\Joe\Desktop\postgis\CLEAN_PESQ\CLEAN_PESQ.csv"
#$credential = Get-Credential
$PESQ_Files = Get-ChildItem -Path $PESQ_Path


Foreach ($PESQ_file in $PESQ_Files)
{ 

    $PESQ_Data += Get-Content -Path $PESQ_file.FullName | Select-Object -skip 1 |`
    ConvertFrom-Csv -Header "1","2","Latitude","Longitude","5","6","Event","8","9","10","11","12","13","14","LA","16","RSSI","18","19","20","21","22","23","24","25","26","27","28","29","30",`
    "31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69",`
    "70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106",`
    "107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138",`
    "139","140","141","142","143","144","145","146","147","148","149","150","151","152","153","154","155","156","157","158","159","160","161","162","163","164","165","166","167","168","169","170",`
    "171","172","173","174","175","176","177","178","179","180","181","182","183","184","185","186","187","188","189","190","191","192","193","194","195","196","197","198","199","200","201","202",`
    "203","204","205","206","207","208","209","210","211","212","213","214","215","216","217","218","219","220","221","222","223","224","225","226","227","228","229","230","231","232","233","234",`
    "235","236","237","238","239","240","241","242","243","pesq","245","246","247","248","249","Details" |`
    Select 'Latitude','Longitude','Event','LA','RSSI','pesq','Details'
}


$DL_PESQ_TO_RSSI = @{
-120	=	0
-119	=	1
-118	=	1
-117	=	1
-116	=	1
-115	=	1
-114	=	1
-113	=	1
-112	=	1
-111	=	1
-110	=	1
-109	=	1
-108	=	1
-107	=	2.2
-106	=	2.2
-105	=	2.2
-104	=	2.2
-103	=	2.2
-102	=	2.2
-101	=	2.2
-100	=	2.2
-99	=	2.2
-98	=	2.2
-97	=	2.2
-96	=	2.2
-95	=	2.2
-94	= 2.2
-93	=	2.2
-92	=	2.2
-91	=	2.2
-90	=	2.2
-89	=	2.2
-88	=	2.2
-87	=	2.2
-86	=	2.2
-85	=	2.2
-84	=	2.2
-83	=	2.2
-82	=	2.2
-81	=	2.2
-80	=	2.2

}
$UL_PESQ_TO_RSSI = @{
-120	=	0
-119	=	1
-118	=	1
-117	=	1
-116	=	1
-115	=	1
-114	=	1
-113	=	1
-112	=	1
-111	=	1
-110	=	1
-109	=	1
-108	=	1
-107	=	1
-106	=	1
-105	=	1
-104	=	1
-103	=	1
-102	=	1
-101	=	1
-100	=	2.2
-99	=	2.2
-98	=	2.2
-97	=	2.2
-96	=	2.2
-95	=	2.2
-94	=	2.2
-93	=	2.2
-92	=	2.2
-91	=	2.2
-90	=	2.2
-89	=	2.2
-88	=	2.2
-87	=	2.2
-86	=	2.2
-85	=	2.2
-84	=	2.2
-83	=	2.2
-82	=	2.2
-81	=	2.2
-80	=	2.2


}

$Cleaned_PESQ = @()
foreach ($row in $PESQ_Data)
{
    if (($row.'Event' -eq 'Down Link Speech Sample' -or $row.'Event' -eq 'Up Link Speech Sample'))
    {
        if (($row.'pesq' -ne 0) -and ($row.Details -ne 'Marked') -and ($row.pesq -ne '--')) #good data
        {
            Add-Member -InputObject $row -MemberType NoteProperty -Name 'pesq_no_mod' -Value $row.'pesq' -Force
            Add-Member -InputObject $row -MemberType NoteProperty -Name 'info' -Value '' -Force
            $Cleaned_PESQ += $row
        }
        elseif (($row.'pesq' -eq 0) -or ($row.details -eq 'WAV file missing') -or ($row.Details -like 'Marked') ) #marked sample or pesq = 0
        {
        Write-Output $row.Details
            Add-Member -InputObject $row -MemberType NoteProperty -Name 'pesq_no_mod' -Value '' -Force
            if ($row.'Event' -eq 'Down Link Speech Sample')
            {
               Add-Member -InputObject $row -MemberType NoteProperty -Name 'info' -Value 1 -Force
               Add-Member -InputObject $row -MemberType NoteProperty -Name 'pesq' -Value $DL_PESQ_TO_RSSI[[int]$row.RSSI] -Force
            }
            elseif ($row.'Event' -eq 'Up Link Speech Sample')
            {
               Add-Member -InputObject $row -MemberType NoteProperty -Name 'info' -Value 1 -Force
               Add-Member -InputObject $row -MemberType NoteProperty -Name 'pesq' -Value $UL_PESQ_TO_RSSI[[int]$row.RSSI] -Force
            }
            $Cleaned_PESQ += $row
        }
    }
}

$Cleaned_PESQ | Select Latitude,Longitude,Event,LA,pesq,pesq_no_mod,info | Export-Csv -Path $PESQ_Out_File_Path -NoTypeInformation


Import-Csv $PESQ_Out_File_Path | ConvertTo-CSV -NoTypeInformation | % { $_ -Replace '"', ""} | Out-File $PESQ_No_Quotes -fo -en ascii

$PESQ_Data = $null
$Cleaned_PESQ= $null