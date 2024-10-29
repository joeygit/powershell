# Define the path to the CSV files
$csvPath = "C:\Historical\CE\"

# Define an empty ArrayList to store the custom objects
$export_data = New-Object System.Collections.ArrayList
$pesq_export_data = New-Object System.Collections.ArrayList
# Loop through each CSV file in the directory
Get-ChildItem -Path $csvPath -Filter *.csv | ForEach-Object {
    Write-Host "Processing file: $_.FullName"

    # Import the CSV file
    Import-Csv -Path $_.FullName |  select -skip 12000 -First 6000 | ForEach-Object {
        # Loop through each row in the chunk and output the Decimal values from the specified column
        foreach ($row in $_) {
            if ($row.BER_values -ne '[]') {
                $BER_pattern = "'([\d\.]+)'"
                $ber_matches = [regex]::Matches($row.BER_values, $BER_pattern)
                $ber = $ber_matches.Value -replace "'", ""
                $rssi_string = $row.BER_RSSI_values
                $trimmed_string = $rssi_string.SubString(1, $rssi_string.Length - 2)
                $rssi_ary = $trimmed_string.Split(', ')
                $rssi_ary = $rssi_ary -replace "'", ""
                $rssi_Ary = $rssi_ary | Where-Object { $_ -ne "" -and $_ -ne " " }
                #pesq rssi
                $pesq_rssi_string = $row.PESQ_RSSI_values
                $pesq_trimmed_string = $pesq_rssi_string.SubString(1, $pesq_rssi_string.Length - 2)
                $pesq_rssi_ary = $pesq_trimmed_string.Split(', ')
                $pesq_rssi_ary = $pesq_rssi_ary -replace "'", ""
                $pesq_rssi_Ary = $pesq_rssi_ary | Where-Object { $_ -ne "" -and $_ -ne " " }
                # Loop through each value in the BER array and add a new custom object to the ArrayList
                if ( $row.BER_count -ne 1)
                {
                    for ($j = 0; $j -lt $ber.Length; $j++) 
                    {
                        $export_data.Add([pscustomobject]@{
                            tileid = $row.id
                            LA = '999'
                            RSSI = $rssi_ary[$j]
                            BER = $ber[$j]
                            BER_NO_MOD = $ber_no_mod
                            INFO = $info
                        }) | Out-Null
                    
                    }
                }
                else
                {
                    $export_data.Add([pscustomobject]@{
                            tileid = $row.id
                            LA = '999'
                            RSSI = $rssi_ary[$rssi_Ary.Count - 1]
                            BER = $ber
                            BER_NO_MOD = $ber_no_mod
                            INFO = $info
                        }) | Out-Null
                }
                #pesq processing --- event, la, pesq numeric, pesq_no_mod numeric, info numeric
                $pesq_pattern = "'([\d\.]+)'"
                $pesqDL_matches = [regex]::Matches($row.PESQ_DL_Values, $pesq_pattern)
                $pesqDL = $pesqDL_matches.Value -replace "'", ""
                $pesqUL_matches = [regex]::Matches($row.PESQ_UL_Values, $pesq_pattern)
                $pesqUL = $pesqUL_matches.Value -replace "'", ""
                #Uplink
                if ($row.PESQ_UL_Values -ne '[]' -and $row.PESQ_UL_count -ne 1)
                {
                    for ($j = 0; $j -lt $pesqUL.Length; $j++) 
                    {
                        
                        if ($pesq_rssi_Ary[$j] -eq '-')
                        {
                            $pesqRSSI = '129'
                        }
                        else
                        {
                            $pesqRSSI = $pesq_rssi_Ary[$j]
                        }
                        $pesq_export_data.Add([pscustomobject]@{
                            tileid = $row.id
                            LA = '999'
                            Event = 'Up Link'
                            RSSI = $pesqRSSI
                            PESQ = $pesqUL[$j]
                            PESQ_NO_MOD = $ber_no_mod
                            INFO = $info
                        }) | Out-Null                  
                    }
                }
                elseif ($row.PESQ_UL_count -eq 1)
                {
                    if ($pesq_rssi_Ary[$j] -eq '-')
                    {
                        $pesqRSSI = '129'
                    }
                    else
                    {
                        $pesqRSSI = $pesq_rssi_Ary[$pesq_rssi_Ary.Count - 1]
                    }
                    $pesq_export_data.Add([pscustomobject]@{
                            tileid = $row.id
                            LA = '999'
                            Event = 'Up Link'
                            RSSI = $pesqRSSI
                            PESQ = $pesqUL
                            PESQ_NO_MOD = $ber_no_mod
                            INFO = $info
                        }) | Out-Null                  
                }
                #downlink
                if ($row.PESQ_DL_Values -ne '[]' -and $row.PESQ_DL_count -ne 1)
                {
                    for ($k = 0; $k -lt $pesqDL.Length; $k++) 
                    {
                        if ($pesq_rssi_Ary[$j] -eq '-')
                        {
                            $pesqRSSI = '129'
                        }
                        else
                        {
                            $pesqRSSI = $pesq_rssi_Ary[$j]
                        }
                        $pesq_export_data.Add([pscustomobject]@{
                            tileid = $row.id
                            LA = '999'
                            Event = 'Down Link'
                            RSSI = $pesqRSSI
                            PESQ = $pesqDL[$k]
                            PESQ_NO_MOD = $ber_no_mod
                            INFO = $info
                        }) | Out-Null                  
                    }
                }
                    elseif ($row.PESQ_DL_count -eq 1 -and $row.PESQ_DL_Values -ne '[]')
                {
                
                    if ($pesq_rssi_Ary[$j] -eq '-')
                    {
                        $pesqRSSI = '129'
                    }
                    else
                    {
                        $pesqRSSI = $pesq_rssi_Ary[$pesq_rssi_Ary.Count - 1]
                    }
                    $pesq_export_data.Add([pscustomobject]@{
                            tileid = $row.id
                            LA = '999'
                            Event = 'Up Link'
                            RSSI = $pesqRSSI
                            PESQ = $pesqDL
                            PESQ_NO_MOD = $ber_no_mod
                            INFO = $info
                        }) | Out-Null                  
                }
            }
        }
    }
}

# Export the data to a CSV file using the -Append parameter to add data to an existing file
$export_data | Export-Csv -Path "C:\Historical\CE\ber_total_data3.csv" -NoTypeInformation -Append
$pesq_export_data | Export-Csv -Path "C:\Historical\CE\pesq_total_data3.csv" -NoTypeInformation -Append
# Clear the ArrayList to free up memory
$export_data.Clear()
$pesq_export_data.Clear()