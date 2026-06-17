[CmdletBinding()]
param(
    [string]$InputCsv = (Join-Path $PSScriptRoot "..\examples\directory-group-membership.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output"),
    [datetime]$Today = (Get-Date "2026-06-17")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw "Input CSV not found: $InputCsv"
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$members = Import-Csv -LiteralPath $InputCsv

$auditRows = foreach ($member in $members) {
    $lastLogon = [datetime]$member.LastLogonDate
    $enabled = [System.Convert]::ToBoolean($member.Enabled)
    $reviewFlags = New-Object System.Collections.Generic.List[string]

    if (-not $enabled) {
        $reviewFlags.Add("DisabledAccount")
    }

    if (($Today - $lastLogon).Days -ge 120) {
        $reviewFlags.Add("StaleLogon")
    }

    if ($member.AccountType -eq "Group") {
        $reviewFlags.Add("NestedGroup")
    }

    if ($member.AccountType -eq "Service") {
        $reviewFlags.Add("ServiceAccount")
    }

    [pscustomobject]@{
        GroupName      = $member.GroupName
        AccountName    = $member.SamAccountName
        DisplayName    = $member.DisplayName
        Department     = $member.Department
        Enabled        = $enabled
        AccountType    = $member.AccountType
        Manager        = $member.Manager
        LastLogonDate  = $member.LastLogonDate
        ReviewFlags    = ($reviewFlags -join ";")
        ReviewDecision = if ($reviewFlags.Count -eq 0) { "KeepAccess" } else { "ManagerReview" }
    }
}

$detailPath = Join-Path $OutputDirectory "security-group-audit-export.csv"
$auditRows | Export-Csv -LiteralPath $detailPath -NoTypeInformation

$summaryRows = $auditRows |
    Group-Object -Property GroupName |
    ForEach-Object {
        [pscustomobject]@{
            GroupName           = $_.Name
            TotalMembers        = $_.Count
            ManagerReviewNeeded = @($_.Group | Where-Object { $_.ReviewDecision -eq "ManagerReview" }).Count
            DisabledAccounts    = @($_.Group | Where-Object { $_.ReviewFlags -match "DisabledAccount" }).Count
            NestedGroups        = @($_.Group | Where-Object { $_.ReviewFlags -match "NestedGroup" }).Count
            ServiceAccounts     = @($_.Group | Where-Object { $_.ReviewFlags -match "ServiceAccount" }).Count
        }
    }

$summaryPath = Join-Path $OutputDirectory "security-group-audit-summary.csv"
$summaryRows | Export-Csv -LiteralPath $summaryPath -NoTypeInformation

Write-Output "Wrote security group audit export: $detailPath"
Write-Output "Wrote security group audit summary: $summaryPath"
