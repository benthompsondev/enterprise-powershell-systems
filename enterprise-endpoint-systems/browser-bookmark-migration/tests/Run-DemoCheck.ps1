$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptPath = Join-Path $ProjectRoot "scripts\Invoke-BrowserBookmarkMigrationDemo.ps1"
$OutputDirectory = Join-Path $ProjectRoot "output-test"
$ProfileRoot = Join-Path $OutputDirectory "mock-profiles"
$BackupRoot = Join-Path $OutputDirectory "backups"
$RunOutput = Join-Path $OutputDirectory "run-output"

function New-MockBookmarkFile {
    param(
        [string]$Path,
        [object]$BookmarkJson
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $BookmarkJson | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function New-ChromeBookmarkFixture {
    return [pscustomobject]@{
        checksum = "fake-checksum"
        roots    = [pscustomobject]@{
            bookmark_bar = [pscustomobject]@{
                children      = @(
                    [pscustomobject]@{
                        date_added = "13300000000000000"
                        guid       = [guid]::NewGuid().ToString()
                        id         = "10"
                        name       = "Intranet Help"
                        type       = "url"
                        url        = "https://help.example.local"
                    },
                    [pscustomobject]@{
                        children      = @(
                            [pscustomobject]@{
                                date_added = "13300000000000000"
                                guid       = [guid]::NewGuid().ToString()
                                id         = "12"
                                name       = "Nested Support Guide"
                                type       = "url"
                                url        = "https://support.example.local/guide"
                            }
                        )
                        date_added    = "13300000000000000"
                        date_modified = "13300000000000000"
                        guid          = [guid]::NewGuid().ToString()
                        id            = "11"
                        name          = "Support"
                        type          = "folder"
                    }
                )
                date_added    = "13300000000000000"
                date_modified = "13300000000000000"
                guid          = [guid]::NewGuid().ToString()
                id            = "1"
                name          = "Bookmarks bar"
                type          = "folder"
            }
            other        = [pscustomobject]@{
                children      = @(
                    [pscustomobject]@{
                        date_added = "13300000000000000"
                        guid       = [guid]::NewGuid().ToString()
                        id         = "20"
                        name       = "Policy FAQ"
                        type       = "url"
                        url        = "https://policy.example.local/faq"
                    }
                )
                date_added    = "13300000000000000"
                date_modified = "13300000000000000"
                guid          = [guid]::NewGuid().ToString()
                id            = "2"
                name          = "Other bookmarks"
                type          = "folder"
            }
            synced       = [pscustomobject]@{
                children      = @()
                date_added    = "13300000000000000"
                date_modified = "0"
                guid          = [guid]::NewGuid().ToString()
                id            = "3"
                name          = "Mobile bookmarks"
                type          = "folder"
            }
        }
        version  = 1
    }
}

function New-EdgeBookmarkFixture {
    return [pscustomobject]@{
        checksum = "fake-edge-checksum"
        roots    = [pscustomobject]@{
            bookmark_bar = [pscustomobject]@{
                children      = @()
                date_added    = "13300000000000000"
                date_modified = "0"
                guid          = [guid]::NewGuid().ToString()
                id            = "1"
                name          = "Favorites bar"
                type          = "folder"
            }
            other        = [pscustomobject]@{
                children      = @(
                    [pscustomobject]@{
                        date_added = "13300000000000000"
                        guid       = [guid]::NewGuid().ToString()
                        id         = "4"
                        name       = "Existing Edge Favorite"
                        type       = "url"
                        url        = "https://edge.example.local/start"
                    }
                )
                date_added    = "13300000000000000"
                date_modified = "0"
                guid          = [guid]::NewGuid().ToString()
                id            = "2"
                name          = "Other favorites"
                type          = "folder"
            }
            synced       = [pscustomobject]@{
                children      = @()
                date_added    = "13300000000000000"
                date_modified = "0"
                guid          = [guid]::NewGuid().ToString()
                id            = "3"
                name          = "Mobile favorites"
                type          = "folder"
            }
        }
        version  = 1
    }
}

try {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }

    $profileA = Join-Path $ProfileRoot "demo.alex"
    $profileB = Join-Path $ProfileRoot "demo.no-chrome"

    New-MockBookmarkFile `
        -Path (Join-Path $profileA "AppData\Local\Google\Chrome\User Data\Default\Bookmarks") `
        -BookmarkJson (New-ChromeBookmarkFixture)

    New-MockBookmarkFile `
        -Path (Join-Path $profileA "AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks") `
        -BookmarkJson (New-EdgeBookmarkFixture)

    New-Item -ItemType Directory -Path $profileB -Force | Out-Null

    powershell -ExecutionPolicy Bypass -File $ScriptPath `
        -ProfileRootPath $ProfileRoot `
        -BackupRootPath $BackupRoot `
        -OutputDirectory $RunOutput

    foreach ($file in @("migration-report.csv", "run-log.txt")) {
        $path = Join-Path $RunOutput $file
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Expected output file was not created: $path"
        }
    }

    $backup = Get-ChildItem -LiteralPath (Join-Path $BackupRoot "demo.alex") -Filter "*.html" -File -ErrorAction Stop | Select-Object -First 1
    if ($null -eq $backup) {
        throw "Expected a timestamped HTML backup for demo.alex"
    }

    $backupHtml = Get-Content -LiteralPath $backup.FullName -Raw
    if ($backupHtml -notmatch "Backup Chrome Bookmarks" -or $backupHtml -notmatch "Nested Support Guide") {
        throw "Expected HTML backup to include the import folder and nested bookmark"
    }

    $edgePath = Join-Path $profileA "AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
    $edge = Get-Content -LiteralPath $edgePath -Raw | ConvertFrom-Json
    $otherNames = @($edge.roots.other.children | ForEach-Object { $_.name })

    if ($otherNames -notcontains "Existing Edge Favorite") {
        throw "Expected existing Edge favorite to be preserved"
    }

    if (-not ($otherNames -match "Chrome bookmarks from demo.alex")) {
        throw "Expected imported Chrome folder to be added under Edge Other favorites"
    }

    $importFolder = $edge.roots.other.children | Where-Object { $_.name -eq "Chrome bookmarks from demo.alex" } | Select-Object -First 1
    $importedText = $importFolder | ConvertTo-Json -Depth 100
    if ($importedText -notmatch "Nested Support Guide" -or $importedText -notmatch "Policy FAQ") {
        throw "Expected recursive Chrome bookmark content to be preserved in Edge"
    }

    $report = Import-Csv -LiteralPath (Join-Path $RunOutput "migration-report.csv")
    $migrated = $report | Where-Object { $_.ProfileName -eq "demo.alex" } | Select-Object -First 1
    if ($migrated.Status -ne "Migrated") {
        throw "Expected demo.alex to be migrated"
    }

    $skipped = $report | Where-Object { $_.ProfileName -eq "demo.no-chrome" } | Select-Object -First 1
    if ($skipped.Status -ne "Skipped" -or $skipped.Reason -ne "ChromeBookmarksNotFound") {
        throw "Expected demo.no-chrome to be skipped cleanly"
    }

    Write-Output "Demo check passed."
}
finally {
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }
}
