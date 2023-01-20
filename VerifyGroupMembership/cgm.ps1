# Connect to Exchange Online
Connect-ExchangeOnline

# Prompt user for keyword
$Keyword = Read-Host "Enter keyword to search for in group names"

# Set batch size
$BatchSize = 100

Write-Host "Retrieving distribution groups that contain the keyword in their name" -ForegroundColor Green

# Get distribution groups that contain the keyword in their name
$DistributionGroups = Get-DistributionGroup -Filter {Name -like "*$Keyword*"} -ResultSize $BatchSize

Write-Host "Retrieving mail-enabled security groups that contain the keyword in their name" -ForegroundColor Green

# Get mail-enabled security groups that contain the keyword in their name
$SecurityGroups = Get-Mailbox -Filter {Name -like "*$Keyword*"} -RecipientTypeDetails SecurityGroup -ResultSize $BatchSize

Write-Host "Retrieving Microsoft 365 groups that contain the keyword in their name" -ForegroundColor Green

# Get Microsoft 365 groups that contain the keyword in their name
$UnifiedGroups = Get-UnifiedGroup -Filter {Name -like "*$Keyword*"} -ResultSize $BatchSize

Write-Host "Creating an empty array to store the list of users" -ForegroundColor Green

# Create an empty array to store the list of users
$Users = @()

Write-Host "Looping through each group and checking the members" -ForegroundColor Green

# Loop through each group and check the members
foreach ($Group in $DistributionGroups + $SecurityGroups + $UnifiedGroups) {
    # Get the members of the group in batches
    for ($i = 0; $i -lt $Group.MemberCount; $i += $BatchSize) {
        $Members = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Members -Paging $i -ResultSize $BatchSize
        # Loop through each member and check if they are not in the group
        foreach ($Member in $Members) {
            if (!$Group.Members.Contains($Member.PrimarySmtpAddress)) {
                # Add the member to the list of users
                $Users += $Member
            }
        }
    }
}

$DefaultPath = "$PSScriptRoot\UsersNotInGroups.csv"

$SaveLocation = Read-Host "Do you want to save the csv in the directory the script is stored in? (Y/N)"

if ($SaveLocation -eq "Y") {
    $SaveLocation = $DefaultPath
} else {
    $SaveLocation = Read-Host "Please specify the location where you want to save the CSV file"
}

Write-Host "Exporting the list of users to a CSV file in batches" -ForegroundColor Green

# Export the list of users to a CSV file in batches
for ($i = 0; $i -lt $Users.Count; $i += $BatchSize) {
    $Users[$i..($i+$BatchSize-1)] | Export-Csv -Path $SaveLocation -NoTypeInformation -Append
}
