param(
  [Parameter(Mandatory = $false)]
  [string]
  $ReportFile = "c:\aipoint\report.csv"
)

# This script creates a report based on members of all groups supplied by Azure...
# This script assumes you have already used Connect-AzureAD...

function Get-AzureADReport {
  # First, lets get some group specifics...
  begin {
    # Set hashtables to null then define as empty...
    $groupTable = $null
    $groupTable = @{}

    $groupTable2 = $null
    $groupTable2 = @{}

    # Now we set our reference variable...
    $infoGroup = Get-AzADGroup | Select-Object ObjectId, ObjectType, DisplayName

    # Create the report file...
    New-Item -Path $ReportFile -Force
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
        "" | Out-File -FilePath $ReportFile -Append
        # Define the new group line...
        $newgroupline = '*-*-*-*-{0} ({1})-*-*-*-*' -f $groupTable[$key], $groupTable2[$key]
        # Add the new group line to the report...
        Out-File -FilePath $ReportFile -InputObject $newgroupline -Append
        # Define members' Display Names and User Principal Names...
        $memberships = Get-AzADGroupMember -ObjectId $key | Select-Object DisplayName, UserPrincipalName
        # For each line in memberships...
        foreach ($membership in $memberships) {
          # Define the new membership line...
          $newmembershipline = '{0},{1}' -f "$($membership.DisplayName)", "$($membership.UserPrincipalName)" 
          # Add the new  membership line to the report...
          Out-File -FilePath $ReportFile -InputObject $newmembershipline -Append
        }
      }
      # Just in case, lets make sure we catch any errors...
      catch {
        Write-Host "[Whoops!] the script has ran into an error while generating the report! $_"
      }
    }
  }
}

Write-Host "$(Get-Date -format 'u') [Begin] The report will be generated here: $ReportFile"

Get-AzureADReport

Write-Host "$(Get-Date -format 'u') [End] The report has been saved here: $ReportFile"