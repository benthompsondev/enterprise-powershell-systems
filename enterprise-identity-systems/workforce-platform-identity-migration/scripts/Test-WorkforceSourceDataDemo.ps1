<#
.SYNOPSIS
Validates messy workforce migration CSV data against mock directory data.

.DESCRIPTION
This sanitized demo keeps the shape of the Workday-era validation scripts:
read a project CSV, match rows against directory users by stable identifiers first,
fall back to usernames/display names, flag duplicates or disabled accounts, and
write reviewable output before any account work is planned.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceCsv,
    [Parameter(Mandatory)]
    [string]$MockDirectoryCsv,
    [string]$OutputDirectory = ".\output\validation"
)

$ErrorActionPreference = "Stop"

function Test-Blank { param([object]$Value) [string]::IsNullOrWhiteSpace([string]$Value) }
function Normalize-Text { param([object]$Value) if (Test-Blank $Value) { "" } else { ([string]$Value).Trim() } }
function Normalize-Key { param([object]$Value) (Normalize-Text $Value).ToLowerInvariant() }
function Join-Values { param([string[]]$Values) ($Values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique) -join "; " }

function Find-DirectoryMatch {
    param([object]$Row, [object[]]$Directory)

    $warnings = New-Object System.Collections.Generic.List[string]
    $employeeId = Normalize-Key $Row.EmployeeId
    $licenseId = Normalize-Key $Row.ProfessionalLicenseId
    $sam = Normalize-Key $Row.SamAccountName
    $display = Normalize-Key $Row.DisplayName

    $checks = @(
        @{ Name = "EmployeeId"; Value = $employeeId; Property = "EmployeeId" }
        @{ Name = "ProfessionalLicenseId"; Value = $licenseId; Property = "ProfessionalLicenseId" }
        @{ Name = "SamAccountName"; Value = $sam; Property = "SamAccountName" }
        @{ Name = "DisplayName"; Value = $display; Property = "DisplayName" }
    )

    foreach ($check in $checks) {
        if ([string]::IsNullOrWhiteSpace($check.Value)) {
            [void]$warnings.Add("$($check.Name) is blank")
            continue
        }

        $matches = @($Directory | Where-Object { (Normalize-Key $_.($check.Property)) -eq $check.Value })
        if ($matches.Count -eq 1) {
            return [pscustomobject]@{
                Found = $true
                Ambiguous = $false
                MatchMethod = $check.Name
                User = $matches[0]
                Warnings = $warnings.ToArray()
            }
        }
        if ($matches.Count -gt 1) {
            [void]$warnings.Add("Multiple directory users matched by $($check.Name)")
            return [pscustomobject]@{
                Found = $false
                Ambiguous = $true
                MatchMethod = $check.Name
                User = $null
                Warnings = $warnings.ToArray()
            }
        }
    }

    return [pscustomobject]@{
        Found = $false
        Ambiguous = $false
        MatchMethod = "NoMatch"
        User = $null
        Warnings = $warnings.ToArray()
    }
}

if (-not (Test-Path -LiteralPath $SourceCsv)) { throw "Source CSV not found: $SourceCsv" }
if (-not (Test-Path -LiteralPath $MockDirectoryCsv)) { throw "Mock directory CSV not found: $MockDirectoryCsv" }
if (-not (Test-Path -LiteralPath $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

$sourceRows = Import-Csv -LiteralPath $SourceCsv
$directory = Import-Csv -LiteralPath $MockDirectoryCsv
$results = New-Object System.Collections.Generic.List[object]

$rowNumber = 0
foreach ($row in $sourceRows) {
    $rowNumber++
    $match = Find-DirectoryMatch -Row $row -Directory $directory
    $warnings = New-Object System.Collections.Generic.List[string]
    foreach ($warning in @($match.Warnings)) { [void]$warnings.Add($warning) }

    $requestedAction = Normalize-Text $row.RequestedAction
    $recommendedAction = "ManualReview"
    $matchedUser = $match.User
    $matchStatus = if ($match.Ambiguous) { "Ambiguous" } elseif ($match.Found) { "Found" } else { "NotFound" }

    if ($match.Ambiguous) {
        $recommendedAction = "ManualReview"
    } elseif (-not $match.Found) {
        $recommendedAction = if ($requestedAction -match "Create|New") { "CreateAccount" } else { "ReviewMissingDirectoryUser" }
    } elseif ([string]$matchedUser.Enabled -eq "False") {
        $recommendedAction = "ReenableAndMoveToProjectOu"
        [void]$warnings.Add("Existing disabled account matched. Business review may still be needed.")
    } elseif ($requestedAction -match "Terminate") {
        $recommendedAction = "TerminationReview"
    } else {
        $recommendedAction = "UpdateExistingAccount"
    }

    $results.Add([pscustomobject]@{
        RowNumber               = $rowNumber
        WorkerId                = Normalize-Text $row.WorkerId
        DisplayName             = Normalize-Text $row.DisplayName
        RequestedAction         = $requestedAction
        MatchStatus             = $matchStatus
        MatchMethod             = $match.MatchMethod
        MatchedSamAccountName   = if ($matchedUser) { $matchedUser.SamAccountName } else { "" }
        MatchedEnabled          = if ($matchedUser) { $matchedUser.Enabled } else { "" }
        MatchedOu               = if ($matchedUser) { $matchedUser.OU } else { "" }
        RecommendedAction       = $recommendedAction
        EmployeeId              = Normalize-Text $row.EmployeeId
        ProfessionalLicenseId   = Normalize-Text $row.ProfessionalLicenseId
        ManagerName             = Normalize-Text $row.ManagerName
        Title                   = Normalize-Text $row.Title
        Department              = Normalize-Text $row.Department
        WorkdayId               = Normalize-Text $row.WorkdayId
        Warnings                = Join-Values $warnings.ToArray()
    })
}

$results | Export-Csv -LiteralPath (Join-Path $OutputDirectory "validation-report.csv") -NoTypeInformation
$results | Group-Object RecommendedAction | ForEach-Object {
    [pscustomobject]@{ RecommendedAction = $_.Name; Count = $_.Count }
} | Export-Csv -LiteralPath (Join-Path $OutputDirectory "validation-summary.csv") -NoTypeInformation

"Validated $($results.Count) workforce source row(s)." | Set-Content -LiteralPath (Join-Path $OutputDirectory "validation-run-log.txt")
