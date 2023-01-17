# Connect to Exchange Online using credentials that have global admin
Connect-ExchangeOnline 

# Prompt the user to enter the search keyword
$searchWord = Read-Host -Prompt "Enter the keyword to search for"
Write-Host "Searching for groups containing '$searchWord' in their name or description"

try {
    # Search for mail-enabled security groups that contain the search keyword in their name or description
    $secGroups = Get-DistributionGroup -Filter "(DisplayName -Like '*$searchWord*') -or (Description -Like '*$searchWord*')"
    Write-Host "Found $($secGroups.Count) mail-enabled security groups" -ForegroundColor Green
    # Search for Office 365 groups that contain the search keyword in their name or description
    $unifiedGroups = Get-UnifiedGroup -Filter "(DisplayName -Like '*$searchWord*') -or (Description -Like '*$searchWord*')"
    Write-Host "Found $($unifiedGroups.Count) Office 365 groups" -ForegroundColor Green
    Write-Host "Total of $($groups.Count) groups found" -ForegroundColor Green
}
catch {
    Write-Host "An error occurred while searching for groups: $_" -ForegroundColor Red
}

# Create a new list
$groups = New-Object System.Collections.Generic.List[psobject]

# Add the mail-enabled security groups to the list
$groups.AddRange($secGroups | Select-Object DisplayName,PrimarySmtpAddress)


# Add the Office 365 groups to the list
$groups.AddRange($unifiedGroups | Select-Object DisplayName,PrimarySmtpAddress)


# Prompt the user if they want to export the CSV file in the current directory
$scriptPath = Split-Path $script:MyInvocation.MyCommand.Path
$currentDirectory = $scriptPath
$exportChoice = Read-Host -Prompt "Do you want to export the CSV file in the current directory '$currentDirectory'? Y or N"

if ($exportChoice -eq "Y") {
    # Export the CSV file in the current directory
    $csvPath = $currentDirectory
} else {
    # Prompt the user to specify the directory where they want to export the CSV file
    $csvPath = Read-Host -Prompt "Enter the path where you want to export the CSV file:"
}

# Export the results to a CSV file
$groups | Select-Object -Property DisplayName,PrimarySmtpAddress | Export-Csv -Path "$csvPath\EmailGroups.csv" -NoTypeInformation

# Prompt the user to enter the email address of the owner
$userEmail = Read-Host -Prompt "Enter the email address of the owner"

# Iterate through each group in the CSV file and add the owner
foreach ($group in $groups) {
    try {
        Add-UnifiedGroupLinks -Identity $group.PrimarySmtpAddress -LinkType Members -Links $userEmail
        Write-Host "Successfully added $userEmail as member to $($group.PrimarySmtpAddress)" -ForegroundColor Green
        Add-UnifiedGroupLinks -Identity $group.PrimarySmtpAddress -LinkType Owners -Links $userEmail
        Write-Host "Successfully added $userEmail as owner to $($group.PrimarySmtpAddress)" -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred while adding $userEmail as owner and member to $($group.PrimarySmtpAddress): $_" -ForegroundColor Red
    }
}

# Prompt the user to restart the script or break it
$restart = Read-Host -Prompt "Restart script? Y or N"
if ($restart -eq "Y") {
  # Restart the script
  & $PSCommandPath
} else {
  # Break the script
  Write-Host "Script ended"
  break
}
