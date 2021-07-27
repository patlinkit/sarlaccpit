param(
  [Parameter(Mandatory = $false)]
  [string]
  $ReportFile = "c:\aipoint\report.csv"
)

# This script creates a report based on members of all groups supplied by Azure...
# This script assumes you have already used Connect-AzureAD...

function Get-AzureADReport {
  begin {
    $groupTable = $null
    $groupTable = @{}

    $groupTable2 = $null
    $groupTable2 = @{}

    $infoGroup = Get-AzADGroup | Select-Object ObjectId, ObjectType, DisplayName

    # Create the report file...
    New-Item -Path $ReportFile -Force
  }
  process {
    foreach ($groupId in $infoGroup) {
      $groupTable.add(($groupId.ObjectId), ($groupId.Displayname))
    }
    foreach ($groupId in $infoGroup) {
      $groupTable2.add(($groupId.ObjectId), ($groupId.ObjectType))
    }
  }
  end {
    foreach ($key in $groupTable.keys) {
      try {
        "" | Out-File -FilePath $ReportFile -Append
        $newgroupline = '*-*-*-*-{0} ({1})-*-*-*-*' -f $groupTable[$key], $groupTable2[$key]
        Out-File -FilePath $ReportFile -InputObject $newgroupline -Append
        $memberships = Get-AzADGroupMember -ObjectId $key | Select-Object DisplayName, UserPrincipalName
        foreach ($membership in $memberships) {
          $newmembershipline = '{0},{1}' -f "$($membership.DisplayName)", "$($membership.UserPrincipalName)" 
          Out-File -FilePath $ReportFile -InputObject $newmembershipline -Append
        }
      }
      catch {
        Write-Host "[Whoops!] the script has ran into an error while generating the report! $_"
      }
    }
  }
}

function Main {
  Write-Host "$(Get-Date -format 'u') [Begin] The report will be generated here: $ReportFile"

  Get-AzureADReport

  Write-Host "$(Get-Date -format 'u') [End] The report has been saved here: $ReportFile"
}

Main