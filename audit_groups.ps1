# This script creates a report based on members of all groups supplied by Azure...
# This script assumes you have already used Connect-AzureAD...

## TO DO: Define report file path, change as you wish... 
$reportFile = "c:\aipoint\report.csv"

function Get-AzureAADReport {
  # First, lets get some group specifics...
  begin {
    # Set hashtables to null then define as empty...
    $groupTable = $null
    $groupTable = @{}

    $groupTable2 = $null
    $groupTable2 = @{}

    # Now we set our reference variable...
    $infoGroup = Get-AzureADGroup -All $true | Select-Object ObjectId,ObjectType,DisplayName

    # Create the report file...
    New-Item -Path $reportFile -Force
  }
  # Now lets get those specifics into the hashtables...
  process {
    # Grabs Display Names, keyed to Object IDs
    foreach ($groupId in $infoGroup) {
      $groupTable.add(($groupId.ObjectId), ($groupId.Displayname))
    }
    # Grabs Object Types, keyed to Object IDs
    foreach ($groupId in $infoGroup) {
      $groupTable2.add(($groupId.ObjectId), ($groupId.ObjectType))
    }
  }
  # Now we generate the report itself...
  end {
    # For each Object ID in Group hashtable....
    foreach ($key in $groupTable.keys) {
      try {
        # Add a separator line to the report...
        "" | Out-File -FilePath $reportFile -Append
        # Define the new group line...
        $newgroupline = '*-*-*-*-{0} ({1})-*-*-*-*' -f $groupTable[$key], $groupTable2[$key]
        # Add the new group line to the report...
        Out-File -FilePath $reportFile -InputObject $newgroupline -Append
        # Define members' Display Names and User Principal Names...
        $memberships = Get-AzureADGroupMember -ObjectId $key | Select-Object DisplayName,UserPrincipalName
        # For each line in memberships...
        foreach ($membership in $memberships) {
          # Define the new membership line...
          $newmembershipline = '{0},{1}' -f "$($membership.DisplayName)","$($membership.UserPrincipalName)" 
          # Add the new  membership line to the report...
          Out-File -FilePath $reportFile -InputObject $newmembershipline -Append
        }
      }
      # Just in case, lets make sure we catch any errors...
      catch {
        Write-Host "[Whoops!] the script has ran into an error while generating the report! $_"
      }
    }
  }
}

Write-Host "$(Get-Date -format 'u') [Begin] The report will be generated here: $reportFile"

Get-AzureAADReport

Write-Host "$(Get-Date -format 'u') [End] The report has been saved here: $reportFile"