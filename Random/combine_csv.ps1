# Define the path to the folder containing the CSV files
$folderPath = "C:\Historical\CE\New folder\ber"

# Get all CSV files in the folder
$csvFiles = Get-ChildItem $folderPath -Filter *.csv

# Sort the files so the first file's header is used
$csvFiles = $csvFiles | Sort-Object

# Define the output file path
$outputFilePath = "C:\Historical\CE\ber_combined_csv.csv"

# Open the output file for writing
$streamWriter = New-Object System.IO.StreamWriter($outputFilePath)

# Loop through each CSV file
foreach ($csvFile in $csvFiles) {
    # Open the CSV file for reading
    $streamReader = New-Object System.IO.StreamReader($csvFile.FullName)

    # If this is not the first file, skip the header row
    if ($csvFile -ne $csvFiles[0]) {
        $streamReader.ReadLine() | Out-Null
    }

    # Loop through each line in the CSV file
    while ($line = $streamReader.ReadLine()) {
        # Write the line to the output file
        $streamWriter.WriteLine($line)
    }

    # Close the CSV file
    $streamReader.Close()
}

# Close the output file
$streamWriter.Close()