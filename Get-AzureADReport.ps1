<#
.SYNOPSIS

Gets all Azure Active Directory group memberships

.DESCRIPTION

The Get-AzureADReport.ps1 script exports all Azure Active Directory
group memberships to a single CSV

.PARAMETER ReportFilePath
Specifies the name and path for the CSV-based output file. By default,
Get-AzureADReport.ps1 generates a name from the date and time it runs, and
saves the output in the users Desktop directory.

.INPUTS

None. You cannot pipe objects to Get-AzureADReport.ps1.

.OUTPUTS

None. Get-AzureADReport.ps1 does not generate any output.

.EXAMPLE

PS> .\Get-AzureADReport.ps1

.EXAMPLE

PS> .\Get-AzureADReport.ps1 -ReportFilePath C:\Data\January.csv

#>
#Requires -Modules Az

param(
  [Parameter(Mandatory = $false)]
  [string]
  $ReportFilePath
)

function Get-AzureADReport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $ExportFilePath,

    [Parameter(Mandatory = $false, DontShow = $true)]
    [Int32]
    $DoP = 20 # Degree of Parallelism
  )
  try {
    $aadGroups = Get-AzADGroup
    $i = 0
    $count = $aadGroups.Count

    foreach ($group in $aadGroups) {
      while ( (Get-Job | Where-Object -Property State -eq "Running").Count -eq $DoP ) { <# Wait for instance count to be less than DoP #> }
      $completedJobs = Get-Job | Where-Object -Property State -eq "Completed"
      if ($completedJobs) {
        $completedJobs | ForEach-Object {
          $results = $_ | Receive-Job
          $results | Select-Object -Property GroupName, DisplayName, Id, Type, UserPrincipalName | Export-Csv -Path $ExportFilePath -Append -NoTypeInformation -Force
          $_ | Remove-Job
        }
      }

      $i++
      Write-Progress -Activity "($i/$count)" -Status "$($group.DisplayName)" -PercentComplete $(($i / $count) * 100)

      Start-Job -Name $group.DisplayName -ScriptBlock {
        $groupMembers = Get-AzADGroupMember -GroupObjectId $using:group.Id
        foreach ($member in $groupMembers) {
          $member | Add-Member -MemberType NoteProperty -Name GroupName -Value $using:group.DisplayName
          $member | Select-Object -Property GroupName, DisplayName, Id, Type, UserPrincipalName
        }
      } | Out-Null
    }
  
    While (Get-Job | Where-Object -Property State -eq "Running") { <# Wait For All Jobs To Complete #>> }
    $completedJobs = Get-Job | Where-Object -Property State -eq "Completed"
    if ($completedJobs) {
      $completedJobs | ForEach-Object {
        $results = $_ | Receive-Job
        $results | Select-Object -Property GroupName, DisplayName, Id, Type, UserPrincipalName | Export-Csv -Path $ExportFilePath -Append -NoTypeInformation -Force
        $_ | Remove-Job
      }
    }
  }
  catch {
    Write-Error $Error[0].Exception
  }
}

function Main {
  if ([string]::IsNullOrEmpty($ReportFilePath)) {
    $date = (Get-Date -Format o -AsUTC) -replace (":", ".")
    $ReportFilePath = ("$home{0}Desktop{0}AzureADReport-$date.csv") -f [IO.Path]::DirectorySeparatorChar
  }

  if ($null -eq (Get-AzContext)) {
    Connect-AzAccount
  }

  Write-Host "$(Get-Date -format 'u') [Begin] The report will be generated here: $ReportFilePath"
  Get-AzureADReport -ExportFilePath $ReportFilePath
  Write-Host "$(Get-Date -format 'u') [End] The report has been saved here: $ReportFilePath"
}

Main