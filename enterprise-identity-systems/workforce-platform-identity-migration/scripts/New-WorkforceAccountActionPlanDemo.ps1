<#
.SYNOPSIS
Creates a reviewable account action plan from workforce validation output.

.DESCRIPTION
This public-safe demo replaces direct AD writes with a plan. It preserves the
real workflow shape: create new accounts, re-enable matched disabled accounts,
move accounts into a project OU, populate HR/workforce attributes, apply default
groups, and keep manual review items separate.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ValidationReportCsv,
    [string]$OutputDirectory = ".\output\account-plan",
    [string]$ProjectOu = "OU=WorkforcePlatform,OU=ProjectAccounts,DC=example,DC=local",
    [string[]]$DefaultGroups = @("APP-Workforce-Portal", "MFA-Required", "SEC-Project-Users")
)

$ErrorActionPreference = "Stop"

function Normalize-Text { param([object]$Value) if ([string]::IsNullOrWhiteSpace([string]$Value)) { "" } else { ([string]$Value).Trim() } }
function New-UsernameFromDisplayName {
    param([string]$DisplayName, [string[]]$ExistingNames)
    $parts = (Normalize-Text $DisplayName) -split "\s+" | Where-Object { $_ }
    if ($parts.Count -lt 2) { return "" }
    $base = ("{0}{1}" -f $parts[0].Substring(0,1), $parts[-1]).ToLowerInvariant() -replace "[^a-z0-9]", ""
    $candidate = $base
    $i = 2
    while ($ExistingNames -contains $candidate) {
        $candidate = "$base$i"
        $i++
    }
    return $candidate
}

if (-not (Test-Path -LiteralPath $ValidationReportCsv)) { throw "Validation report not found: $ValidationReportCsv" }
if (-not (Test-Path -LiteralPath $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

$rows = Import-Csv -LiteralPath $ValidationReportCsv
$existing = @($rows.MatchedSamAccountName | Where-Object { $_ })
$planRows = New-Object System.Collections.Generic.List[object]

foreach ($row in $rows) {
    $action = $row.RecommendedAction
    $targetSam = Normalize-Text $row.MatchedSamAccountName
    if (-not $targetSam -and $action -eq "CreateAccount") {
        $targetSam = New-UsernameFromDisplayName -DisplayName $row.DisplayName -ExistingNames $existing
        if ($targetSam) { $existing += $targetSam }
    }

    $directoryActions = New-Object System.Collections.Generic.List[string]
    $attributeActions = New-Object System.Collections.Generic.List[string]
    $groupActions = New-Object System.Collections.Generic.List[string]
    $reviewNotes = New-Object System.Collections.Generic.List[string]

    switch ($action) {
        "CreateAccount" {
            [void]$directoryActions.Add("Create account in project OU")
            [void]$directoryActions.Add("Set temporary password through approved secure process")
            [void]$directoryActions.Add("Require password change at next sign-in")
        }
        "ReenableAndMoveToProjectOu" {
            [void]$directoryActions.Add("Re-enable existing disabled account")
            [void]$directoryActions.Add("Move account to project OU")
            [void]$reviewNotes.Add("Disabled account matched from source data. Confirm business context before applying.")
        }
        "UpdateExistingAccount" {
            [void]$directoryActions.Add("Move or confirm account in project OU")
        }
        "TerminationReview" {
            [void]$directoryActions.Add("Do not modify until termination/re-enable decision is confirmed")
            [void]$reviewNotes.Add("Source row requested termination handling. Keep separate from create/re-enable flow.")
        }
        default {
            [void]$directoryActions.Add("Manual review")
            [void]$reviewNotes.Add("Validation did not produce a safe automatic action.")
        }
    }

    foreach ($field in @("EmployeeId", "ProfessionalLicenseId", "WorkdayId", "Title", "Department", "ManagerName")) {
        if (-not [string]::IsNullOrWhiteSpace([string]$row.$field)) {
            [void]$attributeActions.Add("Set or confirm $field")
        }
    }

    if ($action -in @("CreateAccount", "ReenableAndMoveToProjectOu", "UpdateExistingAccount")) {
        foreach ($group in $DefaultGroups) {
            [void]$groupActions.Add("Add or confirm group: $group")
        }
    }

    if ($row.Warnings) { [void]$reviewNotes.Add($row.Warnings) }

    $planRows.Add([pscustomobject]@{
        WorkerId          = $row.WorkerId
        DisplayName       = $row.DisplayName
        TargetSamAccount  = $targetSam
        SourceMatchStatus = $row.MatchStatus
        PlannedAction     = $action
        TargetOu          = $ProjectOu
        DirectoryActions  = ($directoryActions -join "; ")
        AttributeActions  = ($attributeActions -join "; ")
        GroupActions      = ($groupActions -join "; ")
        ReviewNotes       = ($reviewNotes -join "; ")
    })
}

$planRows | Export-Csv -LiteralPath (Join-Path $OutputDirectory "account-action-plan.csv") -NoTypeInformation
$planRows | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory "account-action-plan.json")
$planRows | Group-Object PlannedAction | ForEach-Object {
    [pscustomobject]@{ PlannedAction = $_.Name; Count = $_.Count }
} | Export-Csv -LiteralPath (Join-Path $OutputDirectory "account-action-summary.csv") -NoTypeInformation

"Created account action plan for $($planRows.Count) row(s)." | Set-Content -LiteralPath (Join-Path $OutputDirectory "account-plan-run-log.txt")
