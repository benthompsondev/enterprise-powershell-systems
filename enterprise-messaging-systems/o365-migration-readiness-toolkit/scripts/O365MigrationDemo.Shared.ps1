$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Import-RequiredCsv {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string[]]$RequiredColumns
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required CSV was not found: $Path"
    }

    $rows = @(Import-Csv -LiteralPath $Path)
    if ($rows.Count -eq 0) {
        throw "Required CSV has no rows: $Path"
    }

    $columns = @($rows[0].PSObject.Properties.Name)
    foreach ($column in $RequiredColumns) {
        if ($columns -notcontains $column) {
            throw "CSV '$Path' is missing required column '$column'"
        }
    }

    return $rows
}

function Initialize-DemoOutputDirectory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Split-GroupList {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return @($Value -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function New-UserLookup {
    param([object[]]$Users)

    $lookup = @{}
    foreach ($user in $Users) {
        $key = $user.UserPrincipalName.Trim().ToLowerInvariant()
        if (-not $lookup.ContainsKey($key)) {
            $lookup[$key] = $user
        }
    }

    return $lookup
}

function New-LicenseLookup {
    param([object[]]$LicenseRows)

    $lookup = @{}
    foreach ($row in $LicenseRows) {
        $key = $row.UserPrincipalName.Trim().ToLowerInvariant()
        if (-not $lookup.ContainsKey($key)) {
            $lookup[$key] = $row
        }
    }

    return $lookup
}

function Get-LicenseGroupStatus {
    param([Parameter(Mandatory)][object]$LicenseRow)

    $groups = @(Split-GroupList -Value $LicenseRow.CurrentLicenseGroups)
    $licenseGroups = @($groups | Where-Object { $_ -like "LIC-*" })
    $hasRequiredGroup = $groups -contains $LicenseRow.RequiredLicenseGroup

    if ($licenseGroups.Count -gt 1) {
        return "DuplicateLicensePath"
    }

    if (-not $hasRequiredGroup) {
        return "MissingRequiredLicenseGroup"
    }

    return "Ready"
}

function Get-PublicFolderAction {
    param([Parameter(Mandatory)][object]$Folder)

    switch ($Folder.RecommendedDisposition) {
        "ConvertToSharedMailbox" {
            "Confirm owner, export content, create shared mailbox migration plan, then remove public folder permissions after cutover"
        }
        "ArchiveAndRemovePermissions" {
            "Archive folder content, export permission evidence, remove user permissions, and keep cleanup report"
        }
        default {
            "Review with folder owner before removing access or converting the folder"
        }
    }
}

function Get-MailboxRepairPlan {
    param([Parameter(Mandatory)][object]$Issue)

    switch ($Issue.IssueType) {
        "SoftDeletedMailbox" {
            "Review soft-deleted mailbox state, reconnect or restore mailbox, run sync, then recheck migration readiness"
        }
        "DisabledAccountWithMailbox" {
            "Confirm account status before migration. Do not re-enable automatically from a spreadsheet"
        }
        "DuplicateLicensePath" {
            "Confirm intended license, remove extra license-backed group, then rerun license review"
        }
        default {
            "Manual review required before migration action"
        }
    }
}
