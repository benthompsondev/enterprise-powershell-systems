[CmdletBinding()]
param(
    [string]$InputCsv = (Join-Path $PSScriptRoot "..\examples\dhcp-reservation-requests.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output")
)

$ErrorActionPreference = "Stop"

function Convert-IpToUInt32 {
    param([string]$Address)

    $parsed = [System.Net.IPAddress]::Parse($Address)
    $bytes = $parsed.GetAddressBytes()
    [Array]::Reverse($bytes)
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Test-IpInRange {
    param(
        [string]$Address,
        [string]$StartAddress,
        [string]$EndAddress
    )

    $ip = Convert-IpToUInt32 -Address $Address
    $start = Convert-IpToUInt32 -Address $StartAddress
    $end = Convert-IpToUInt32 -Address $EndAddress

    return ($ip -ge $start -and $ip -le $end)
}

function Test-MacAddress {
    param([string]$MacAddress)

    return ($MacAddress -match '^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$')
}

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw "Input CSV not found: $InputCsv"
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

# Fake demo scopes. The real review used real scope data, which is intentionally not included here.
$scopes = @{
    ClinicDevices = [pscustomobject]@{ Start = "192.0.2.1"; End = "192.0.2.254" }
    LabDevices    = [pscustomobject]@{ Start = "198.51.100.1"; End = "198.51.100.254" }
}

$requests = Import-Csv -LiteralPath $InputCsv
$ipCounts = $requests | Group-Object -Property RequestedIp -AsHashTable -AsString

$reviewRows = foreach ($request in $requests) {
    $issues = New-Object System.Collections.Generic.List[string]

    if (-not $request.DeviceName) {
        $issues.Add("MissingDeviceName")
    }

    if (-not (Test-MacAddress -MacAddress $request.MacAddress)) {
        $issues.Add("InvalidMacAddress")
    }

    if (-not $scopes.ContainsKey($request.ScopeName)) {
        $issues.Add("UnknownScope")
    }
    else {
        try {
            $inRange = Test-IpInRange -Address $request.RequestedIp -StartAddress $scopes[$request.ScopeName].Start -EndAddress $scopes[$request.ScopeName].End
            if (-not $inRange) {
                $issues.Add("IpOutsideScope")
            }
        }
        catch {
            $issues.Add("InvalidIpAddress")
        }
    }

    if ($ipCounts[$request.RequestedIp].Count -gt 1) {
        $issues.Add("DuplicateRequestedIp")
    }

    $status = if ($issues.Count -eq 0) { "ReadyForReservation" } else { "NeedsReview" }

    [pscustomobject]@{
        RequestId       = $request.RequestId
        DeviceName      = $request.DeviceName
        ScopeName       = $request.ScopeName
        RequestedIp     = $request.RequestedIp
        SubmittedByTeam = $request.SubmittedByTeam
        ChangeTicket    = $request.ChangeTicket
        ReviewStatus    = $status
        ReviewIssues    = ($issues -join ";")
        ReviewerNote    = if ($issues.Count -eq 0) { "Request passed demo validation." } else { "Fix the listed issue before implementation." }
    }
}

$outputPath = Join-Path $OutputDirectory "dhcp-reservation-review.csv"
$reviewRows | Export-Csv -LiteralPath $outputPath -NoTypeInformation
Write-Output "Wrote DHCP reservation review: $outputPath"
