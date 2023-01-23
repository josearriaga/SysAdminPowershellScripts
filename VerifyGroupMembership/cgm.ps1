Connect-AzureAD

# Retrieve a specific user
$User = Get-AzureADUser -ObjectId "ENTER USER OBJECT ID HERE" 

# Prompt user for keyword
$Keyword = Read-Host "Enter keyword to search for in group names. WARNING: Must be a single word no spaces"
Write-Host "Keyword: $Keyword" -ForegroundColor Cyan

# Get all groups that match the keyword, this line looks for groups that startwith "Guidepost" and end with whatever was inputed for $Keyword. To change the startwith simply replace "Guidepost"
$Groups = Get-AzureADGroup -Top 6000 | Where-Object {$_.DisplayName -like "Guidepost*$Keyword"}

# Loop through each group

$NotInGroups = @()

foreach ($Group in $Groups) {
    Write-Host "Checking members of group: $($Group.displayName)" -ForegroundColor Magenta

    $Members = Get-AzureADGroupMember -All $true -ObjectId $Group.ObjectId | Where-Object {$_.UserType -eq 'member'}
    if ($Members) {
        if ($Members.UserPrincipalName -notcontains $User.UserPrincipalName) {
            $NotInGroups += $Group.displayName
        }
    }
}

If ($NotInGroups.Count -eq 0) {
    Write-Host "User is a Member of all the groups in the list" -ForegroundColor Green
} else {
    Write-Host "User not in groups:" -ForegroundColor Cyan
    Write-Host $NotInGroups -ForegroundColor Cyan
}


$DefaultPath = "$PSScriptRoot\UserNotInGroups.csv"

# Prompt user for save location
$SaveLocation = Read-Host "Do you want to save the csv in the directory the script is stored in? (Y/N)"

if ($SaveLocation -eq "Y") {
    $SaveLocation = $DefaultPath
} else {
    $SaveLocation = Read-Host "Please specify the full path where you want to save the CSV file"
}

Write-Host "Exporting the list of users not in groups to a CSV file" -ForegroundColor Green

# Export the list of users not in groups to a CSV file
try {
    $UsersNotInGroups | Select-Object UserPrincipalName, DisplayName Write-Host "List of users not in groups exported to $SaveLocation" -ForegroundColor Green
} catch {
    Write-Host "Error exporting list of users not in groups to $SaveLocation" -ForegroundColor Red
}
