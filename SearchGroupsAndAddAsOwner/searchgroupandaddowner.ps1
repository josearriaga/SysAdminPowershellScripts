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
    Write-Host "Total of $($secGroups.Count+$unifiedGroups.Count) groups found" -ForegroundColor Green
}
catch {
    Write-Host "An error occurred while searching for groups: $_" -ForegroundColor Red
}

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
$secGroups | Select-Object -Property DisplayName,PrimarySmtpAddress, @{Name="GroupType"; Expression={"Mail-Enabled Security Group"}} | Export-Csv -Path "$csvPath\EmailGroups.csv" -NoTypeInformation -Append
$unifiedGroups | Select-Object -Property DisplayName,PrimarySmtpAddress, @{Name="GroupType"; Expression={"Office 365 Group"}} | Export-Csv -Path "$csvPath\EmailGroups.csv" -NoTypeInformation -Append

# Prompt the user to enter the email address of the owner
$userEmail = Read-Host -Prompt "Enter the email address of the owner"

# Prompt the user to confirm the action of making the user a manager of the mail-enabled security groups
$confirmManager = Read-Host -Prompt "Are you sure you want to make $userEmail a manager of the mail-enabled security groups found? Y or N"
if ($confirmManager -eq "Y") {
    # Iterate through each mail-enabled security group and make the user a manager
    foreach ($secGroup in $secGroups) {
        try {
            # Make the user a manager of the mail-enabled security group
            Set-DistributionGroup -Identity $secGroup.PrimarySmtpAddress -ManagedBy $userEmail -BypassSecurityGroupManagerCheck
            Add-DistributionGroupMember -Identity $secGroup.PrimarySmtpAddress -Member $userEmail -BypassSecurityGroupManagerCheck
            Write-Host "Successfully made $userEmail a manager and member of $($secGroup.PrimarySmtpAddress)" -ForegroundColor Green
        }
        catch [Microsoft.Exchange.Configuration.Tasks.OperationRequiresGroupManagerException] {
            Write-Host "You don't have sufficient permissions to make $userEmail a manager of $($secGroup.PrimarySmtpAddress). This operation can only be performed by a manager of the group." -ForegroundColor DarkRed
        }
    }
} else {
    Write-Host "Aborted action of making $userEmail a manager of the mail-enabled security groups" -ForegroundColor Yellow
}


foreach ($unifiedGroup in $unifiedGroups) {
    try {
        # Add the user as a member and owner of the Office 365 group
        Add-UnifiedGroupLinks -Identity $unifiedGroup.PrimarySmtpAddress -LinkType Members -Links $userEmail
        Write-Host "Successfully added $userEmail as member to $($unifiedGroup.PrimarySmtpAddress)" -ForegroundColor Green
        Add-UnifiedGroupLinks -Identity $unifiedGroup.PrimarySmtpAddress -LinkType Owners -Links $userEmail
        Write-Host "Successfully added $userEmail as owner to $($unifiedGroup.PrimarySmtpAddress)" -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred while adding $userEmail as owner and member to $($unifiedGroup.PrimarySmtpAddress): $_" -ForegroundColor Red
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
