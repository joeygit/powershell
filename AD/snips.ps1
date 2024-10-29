Search-ADAccount -Server server -AccountExpired | where { $_.AccountExpirationDate -match "8/12/2016"} | Set-ADAccountExpiration -timespan 60.0:0 | Export-Csv d:\export\ST_ExpiredAccounts.csv -WhatIf

Search-ADAccount -Server server -AccountExpired | where { $_.AccountExpirationDate -match "8/20/2016"} | Export-Csv d:\export\CP2_postcheck_ExpiredAccounts.csv
Search-ADAccount -Server server -AccountExpired | where { $_.SamAccountName -match "tkmacqja"}

Search-ADAccount -AccountExpiring -TimeSpan 5.00:00:00 | where {$_.ObjectClass -eq 'user'}