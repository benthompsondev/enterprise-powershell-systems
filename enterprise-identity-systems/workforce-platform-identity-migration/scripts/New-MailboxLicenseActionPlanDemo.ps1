<#
.SYNOPSIS
Plans mailbox, license, and termination actions from an approved project CSV.

.DESCRIPTION
This sanitized demo keeps the later-stage workflow: after accounts are created or
re-enabled, a project team provides a list of users who need mailbox/license work
or termination cleanup. The public version writes plans instead of changing AD,
Exchange, or licensing systems.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ActionCsv,
    [Parameter(Mandatory)]
    [string]$MockDirectoryCsv,
    [string]$OutputDirectory = ".\output\mailbox-license-plan",
    [string[]]$DefaultLicenseGroups = @("LIC-Workforce-F3", "LIC-Mailbox-Enabled"),
    [string]$TerminatedOu = "OU=Terminated,OU=Users,DC=example,DC=local"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ActionCsv)) { throw "Action CSV not found: $ActionCsv" }
if (-not (Test-Path -LiteralPath $MockDirectoryCsv)) { throw "Mock directory CSV not found: $MockDirectoryCsv" }
if (-not (Test-Path -LiteralPath $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

$actions = Import-Csv -LiteralPath $ActionCsv
$directory = Import-Csv -LiteralPath $MockDirectoryCsv
$plan = New-Object System.Collections.Generic.List[object]

foreach ($row in $actions) {
    $sam = ([string]$row.SamAccountName).Trim()
    $user = $directory | Where-Object { $_.SamAccountName -eq $sam } | Select-Object -First 1
    $notes = New-Object System.Collections.Generic.List[string]
    $planned = New-Object System.Collections.Generic.List[string]

    if (-not $user) {
        $plan.Add([pscustomobject]@{
            SamAccountName = $sam
            DisplayName = $row.DisplayName
            RequestedAction = $row.RequestedAction
            PlannedActions = "Manual review"
            Status = "UserNotFound"
            Notes = "User was not found in mock directory data"
        })
        continue
    }

    switch -Regex ($row.RequestedAction) {
        "EnableMailbox|License" {
            if ([string]$user.MailboxEnabled -ne "True") {
                [void]$planned.Add("Enable remote mailbox or mailbox equivalent")
            } else {
                [void]$notes.Add("Mailbox already enabled")
            }
            if ([string]$user.LicenseAssigned -ne "True") {
                foreach ($group in $DefaultLicenseGroups) { [void]$planned.Add("Add license group: $group") }
            } else {
                [void]$notes.Add("License already assigned")
            }
            $status = "MailboxLicensePlanCreated"
        }
        "Terminate|Disable" {
            [void]$planned.Add("Disable account")
            [void]$planned.Add("Set termination tracking description")
            [void]$planned.Add("Move to $TerminatedOu")
            $status = "TerminationPlanCreated"
        }
        default {
            [void]$planned.Add("Manual review")
            $status = "ManualReview"
        }
    }

    $plan.Add([pscustomobject]@{
        SamAccountName = $sam
        DisplayName = $user.DisplayName
        RequestedAction = $row.RequestedAction
        PlannedActions = ($planned -join "; ")
        Status = $status
        Notes = ($notes -join "; ")
    })
}

$plan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "mailbox-license-action-plan.csv") -NoTypeInformation
$plan | Group-Object Status | ForEach-Object {
    [pscustomobject]@{ Status = $_.Name; Count = $_.Count }
} | Export-Csv -LiteralPath (Join-Path $OutputDirectory "mailbox-license-summary.csv") -NoTypeInformation

"Created mailbox/license action plan for $($plan.Count) row(s)." | Set-Content -LiteralPath (Join-Path $OutputDirectory "mailbox-license-run-log.txt")
