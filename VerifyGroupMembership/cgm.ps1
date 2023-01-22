Connect-AzureAD

# Retrieve a list of all the recipients in your organization
Get-AzureADUser -All $true | select "UserPrincipalName" | ConvertTo-csv -NoTypeInformation | Out-File $PSScriptRoot\AllUsers.csv 
$AllUsers = " $PSScriptRoot\AllUsers.csv "

Start-Sleep -Seconds 20
Write-Host "AllUsers: $AllUsers" -ForegroundColor Cyan

# Prompt user for keyword
$Keyword = Read-Host "Enter keyword to search for in group names"
Write-Host "Keyword: $Keyword" -ForegroundColor Cyan

# Get all groups that match the keyword
$Groups = Get-AzureADGroup -SearchString "$Keyword"
Write-Host "Groups: $Groups" -ForegroundColor Cyan

# Loop through each group
foreach ($Group in $Groups) {
    Write-Host "Checking members of group: $($Group.displayName)" -ForegroundColor Magenta

    $Members = Get-AzureADGroupMember -All $true -ObjectId $Group.ObjectId | Where-Object {$_.UserType -eq 'member'}
    Write-Host "Members: $Members" -ForegroundColor Cyan
    if ($Members) {
        # Creating an empty array to store the list of users not in groups
        $UsersNotInGroups = @()
        # Loop through each user in the $AllUsers variable
        foreach ($User in $AllUsers) {
            if ($Members.UserPrincipalName -notcontains $User.UserPrincipalName) {
                $UsersNotInGroups += $User
            }
        }
    }
        If ($UsersNotInGroups.Count -eq 0) {
        Write-Host "No users were found that are not in group '$($Group.displayName)'"
    } else {
        Write-Host "Users not in group '$($Group.displayName)':" -ForegroundColor Cyan
        $UsersNotInGroups | Format-Table -Property UserPrincipalName, DisplayName
    }
}


$DefaultPath = "$PSScriptRoot\UsersNotInGroups.csv"

# Prompt user for save location
$SaveLocation = Read-Host "Do you want to save the csv in the directory the script is stored in? (Y/N)"

if ($SaveLocation -eq "Y") {
    $DefaultPath = (Join-Path $PSScriptRoot "UsersNotInGroups.csv")
    $SaveLocation = $DefaultPath
} else {
    $SaveLocation = Read-Host "Please specify the full path where you want to save the CSV file"
}

Write-Host "Exporting the list of users not in groups to a CSV file" -ForegroundColor Green

# Export the list of users not in groups to a CSV file
try {
    $UsersNotInGroups | Select-Object UserPrincipalName, DisplayName | Export-Csv -Path $SaveLocation -NoTypeInformation
}

catch {
    Write-Error "Error exporting the list of users to a CSV file: $($_.Exception.Message)"
}
