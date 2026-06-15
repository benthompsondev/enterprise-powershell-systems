[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$SourceCsv,

    [Parameter(Mandatory)]
    [string]$InputFolder,

    [Parameter()]
    [string]$EmailDomain = "example.local",

    [Parameter()]
    [string]$OutputName = "weak-password-converted.csv"
)

$ErrorActionPreference = "Stop"

$RequiredColumns = @(
    "Discovery Date",
    "User",
    "Secondary Name",
    "User Classification",
    "Password Last Change",
    "Privileged",
    "Org. Unit",
    "Department",
    "Watched",
    "Marked",
    "Stale",
    "Inactive",
    "Disabled",
    "Password Never Expires"
)

function Get-UsernameFromSecondaryName {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    $clean = $Value.Trim()
    if ($clean -match "\\") {
        return ($clean -split "\\")[-1]
    }

    return $clean
}

if ([System.IO.Path]::GetExtension($SourceCsv) -ne ".csv") {
    throw "Source file must be a CSV."
}

if (-not (Test-Path -LiteralPath $InputFolder)) {
    New-Item -ItemType Directory -Path $InputFolder -Force | Out-Null
}

$existingCsv = @(Get-ChildItem -LiteralPath $InputFolder -Filter *.csv -File -ErrorAction SilentlyContinue)
if ($existingCsv.Count -gt 0) {
    throw "Input folder already contains a CSV. Remove or archive the active file before starting a new cycle."
}

$rows = @(Import-Csv -LiteralPath $SourceCsv)
if ($rows.Count -eq 0) {
    throw "Source CSV contains no rows."
}

$missing = foreach ($column in $RequiredColumns) {
    if ($rows[0].PSObject.Properties.Name -notcontains $column) {
        $column
    }
}
if ($missing.Count -gt 0) {
    throw "Source CSV is missing required column(s): $($missing -join ', ')"
}

$converted = foreach ($row in $rows) {
    $sam = Get-UsernameFromSecondaryName -Value $row.'Secondary Name'
    $email = if ($sam) { "$sam@$EmailDomain" } else { "" }
    $enabled = if ($row.Disabled -match "^(?i:true|yes|1|y)$") { "False" } else { "True" }
    $accountType = if ($row.'User Classification') { $row.'User Classification' } else { "Standard" }

    [pscustomobject]@{
        DiscoveryDate     = $row.'Discovery Date'
        EmployeeId        = $row.User
        SamAccountName    = $sam
        UserPrincipalName = $email
        DisplayName       = $row.User
        PasswordLastSet   = $row.'Password Last Change'
        AccountEnabled    = $enabled
        AccountType       = $accountType
        Department        = $row.Department
        ManagerEmail      = "manager.$sam@$EmailDomain"
        ExemptionReason   = ""
        LastAction        = ""
        LastActionDate    = ""
    }
}

$outputPath = Join-Path $InputFolder $OutputName
$converted | Export-Csv -LiteralPath $outputPath -NoTypeInformation
Write-Output "Converted weak-password export written to $outputPath"
