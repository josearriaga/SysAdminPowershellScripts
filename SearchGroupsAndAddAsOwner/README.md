
# Exchange Online Group Management Script

This script allows you to search for and manage mail-enabled security groups and Office 365 groups in Exchange Online. It has the following features:

Prompts the user to enter a keyword to search for.
Searches for both mail-enabled security groups and Office 365 groups that contain the keyword in their name or description.
Displays the number of groups found.
Prompts the user to export the results to a CSV file in a specified directory.
Exports the results to the specified file.
Prompts the user to enter the email address of an owner.
If confirmed, makes the user a manager and member of all the mail-enabled security groups found.
Adds the user as a member and owner of all the Office 365 groups found.

# Prerequisites

You must have a valid Exchange Online global admin account.
The script must be run on a machine with the Exchange Online PowerShell module installed.
The script must be run with an account that has been granted the necessary permissions in Exchange Online.

# How to use the script

Open a PowerShell window and connect to Exchange Online using the Connect-ExchangeOnline cmdlet.
Run the script by typing the path to the script file, for example: .\GroupManagement.ps1
Follow the prompts to search for groups, export the results to a CSV file, and manage the groups.
