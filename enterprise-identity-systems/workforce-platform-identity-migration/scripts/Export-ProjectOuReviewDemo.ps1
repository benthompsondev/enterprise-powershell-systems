<#
.SYNOPSIS
Reports on accounts currently in a project OU using mock directory data.

.DESCRIPTION
This mirrors follow-up scripts used after account creation/re-enable work:
export current project OU users, flag low-access disabled/terminated candidates,
and give the project team a cleaner CSV for review.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$MockDirectoryCsv,
    [string]$OutputDirectory = ".\output\ou-review",
    [string]$ProjectOuName = "WorkforcePlatform"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $MockDirectoryCsv)) { throw "Mock directory CSV not found: $MockDirectoryCsv" }
if (-not (Test-Path -LiteralPath $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

$directory = Import-Csv -LiteralPath $MockDirectoryCsv
$projectUsers = @($directory | Where-Object { $_.OU -match $ProjectOuName })

$review = foreach ($user in $projectUsers) {
    $groups = @([string]$user.Groups -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $recentLogon = 999
    [void][int]::TryParse([string]$user.LastLogonDaysAgo, [ref]$recentLogon)

    $risk = "NormalReview"
    $note = "Account is in project OU"
    if ([string]$user.Enabled -eq "False") {
        $risk = "DisabledInProjectOu"
        $note = "Disabled account still appears in project OU"
    } elseif ($recentLogon -le 30 -and [string]$user.TerminationMarker -eq "True") {
        $risk = "RecentLogonAfterTerminationMarker"
        $note = "Recently active account has a termination marker and needs review"
    } elseif ($groups.Count -le 2) {
        $risk = "LowGroupCountReview"
        $note = "Low group count can indicate an account that needs manual review"
    }

    [pscustomobject]@{
        SamAccountName      = $user.SamAccountName
        DisplayName         = $user.DisplayName
        Enabled             = $user.Enabled
        OU                  = $user.OU
        GroupCount          = $groups.Count
        MailboxEnabled      = $user.MailboxEnabled
        LicenseAssigned     = $user.LicenseAssigned
        LastLogonDaysAgo    = $user.LastLogonDaysAgo
        ReviewCategory      = $risk
        ReviewNote          = $note
    }
}

$review | Export-Csv -LiteralPath (Join-Path $OutputDirectory "project-ou-review.csv") -NoTypeInformation
$review | Group-Object ReviewCategory | ForEach-Object {
    [pscustomobject]@{ ReviewCategory = $_.Name; Count = $_.Count }
} | Export-Csv -LiteralPath (Join-Path $OutputDirectory "project-ou-review-summary.csv") -NoTypeInformation

"Reviewed $($review.Count) project OU account(s)." | Set-Content -LiteralPath (Join-Path $OutputDirectory "project-ou-review-run-log.txt")
