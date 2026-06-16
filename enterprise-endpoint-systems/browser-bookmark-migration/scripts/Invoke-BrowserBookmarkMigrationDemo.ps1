<#
.SYNOPSIS
Migrates Chrome bookmarks into Microsoft Edge for local Windows user profiles.

.DESCRIPTION
This public-safe demo keeps the operational shape of a real endpoint migration script:
it discovers Windows profiles, backs up Chrome bookmarks as browser-importable HTML,
merges Chrome bookmarks into existing Edge favorites, and writes a reviewable run log.

The default paths match normal Chrome and Edge profile locations, but ProfileRootPath
and BackupRootPath are configurable so the script can run against fake demo profiles.

.PARAMETER ProfileRootPath
Root folder that contains user profile folders. Defaults to C:\Users.

.PARAMETER BackupRootPath
Folder where timestamped Chrome bookmark HTML backups are written.

.PARAMETER OutputDirectory
Folder for reports and logs.

.PARAMETER CloseBrowsers
Stops Chrome and Edge before reading or writing bookmark files. This is off by default
because it can disrupt users.

.PARAMETER RestartEdge
Starts Edge after the merge. This is off by default for safer demo runs.

.PARAMETER IncludeSystemProfiles
Includes system-style profiles that are skipped by default.

.EXAMPLE
.\Invoke-BrowserBookmarkMigrationDemo.ps1 -ProfileRootPath .\examples\mock-profiles -BackupRootPath .\output\backups -OutputDirectory .\output

.NOTES
This is a sanitized portfolio version. It uses fake paths and fake data in examples.
Do not put real user data, internal paths, or production bookmark exports in this repo.
#>

[CmdletBinding()]
param(
    [string]$ProfileRootPath = "C:\Users",
    [string]$BackupRootPath = "C:\Temp\ChromeBookmarkBackups",
    [string]$OutputDirectory = ".\output",
    [switch]$CloseBrowsers,
    [switch]$RestartEdge,
    [switch]$IncludeSystemProfiles
)

$ErrorActionPreference = "Stop"

$ChromeRelativeBookmarkPath = "AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
$EdgeRelativeBookmarkPath = "AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
$SystemProfileNames = @(
    "All Users",
    "Default",
    "Default User",
    "Public",
    "WDAGUtilityAccount"
)

function Write-RunLog {
    param(
        [string]$Message,
        [string]$Path
    )

    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Output $line
    Add-Content -LiteralPath $Path -Value $line
}

function Get-LocalUserProfile {
    param(
        [string]$RootPath,
        [switch]$IncludeSystem
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        throw "Profile root was not found: $RootPath"
    }

    Get-ChildItem -LiteralPath $RootPath -Directory -ErrorAction Stop |
        Where-Object {
            $IncludeSystem -or ($SystemProfileNames -notcontains $_.Name)
        } |
        Sort-Object Name
}

function Read-BookmarkJson {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Could not parse bookmark JSON at $Path. $($_.Exception.Message)"
    }
}

function ConvertTo-HtmlEncodedText {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) {
        return ""
    }

    [System.Net.WebUtility]::HtmlEncode($Value)
}

function Convert-BookmarkNodeToHtml {
    param(
        [object]$Node,
        [int]$Depth = 1
    )

    $indent = "    " * $Depth
    $lines = New-Object System.Collections.Generic.List[string]

    if ($Node.type -eq "url") {
        $name = ConvertTo-HtmlEncodedText $Node.name
        $url = ConvertTo-HtmlEncodedText $Node.url
        $lines.Add("$indent<DT><A HREF=`"$url`">$name</A>")
        return $lines
    }

    if ($Node.type -eq "folder") {
        $name = ConvertTo-HtmlEncodedText $Node.name
        $lines.Add("$indent<DT><H3>$name</H3>")
        $lines.Add("$indent<DL><p>")
        foreach ($child in @($Node.children)) {
            foreach ($line in Convert-BookmarkNodeToHtml -Node $child -Depth ($Depth + 1)) {
                $lines.Add($line)
            }
        }
        $lines.Add("$indent</DL><p>")
    }

    return $lines
}

function Export-ChromeBookmarksToHtml {
    param(
        [object]$ChromeBookmarks,
        [string]$OutputPath
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("<!DOCTYPE NETSCAPE-Bookmark-file-1>")
    $lines.Add("<META HTTP-EQUIV=`"Content-Type`" CONTENT=`"text/html; charset=UTF-8`">")
    $lines.Add("<TITLE>Bookmarks</TITLE>")
    $lines.Add("<H1>Bookmarks</H1>")
    $lines.Add("<DL><p>")
    $lines.Add("    <DT><H3>Backup Chrome Bookmarks</H3>")
    $lines.Add("    <DL><p>")

    foreach ($rootName in @("bookmark_bar", "other", "synced")) {
        $root = $ChromeBookmarks.roots.$rootName
        if ($null -ne $root) {
            foreach ($line in Convert-BookmarkNodeToHtml -Node $root -Depth 2) {
                $lines.Add($line)
            }
        }
    }

    $lines.Add("    </DL><p>")
    $lines.Add("</DL><p>")

    $parent = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8
}

function Get-MaxBookmarkId {
    param([object]$BookmarkJson)

    $max = 0

    function Visit-Node {
        param([object]$Node)

        if ($null -eq $Node) {
            return
        }

        $idValue = 0
        if ([int]::TryParse([string]$Node.id, [ref]$idValue)) {
            if ($idValue -gt $script:CurrentMaxBookmarkId) {
                $script:CurrentMaxBookmarkId = $idValue
            }
        }

        foreach ($child in @($Node.children)) {
            Visit-Node -Node $child
        }
    }

    $script:CurrentMaxBookmarkId = $max
    foreach ($rootName in @("bookmark_bar", "other", "synced")) {
        Visit-Node -Node $BookmarkJson.roots.$rootName
    }

    return $script:CurrentMaxBookmarkId
}

function New-BookmarkIdGenerator {
    param([int]$StartAt)

    $state = [pscustomobject]@{ NextId = $StartAt + 1 }
    return {
        $value = $state.NextId
        $state.NextId++
        [string]$value
    }.GetNewClosure()
}

function Copy-BookmarkNodeForEdge {
    param(
        [object]$Node,
        [scriptblock]$NextId
    )

    if ($Node.type -eq "url") {
        return [ordered]@{
            date_added = if ($Node.date_added) { $Node.date_added } else { "13300000000000000" }
            guid       = [guid]::NewGuid().ToString()
            id         = & $NextId
            name       = [string]$Node.name
            type       = "url"
            url        = [string]$Node.url
        }
    }

    $children = @()
    foreach ($child in @($Node.children)) {
        $children += Copy-BookmarkNodeForEdge -Node $child -NextId $NextId
    }

    return [ordered]@{
        children      = $children
        date_added    = if ($Node.date_added) { $Node.date_added } else { "13300000000000000" }
        date_modified = (Get-Date).ToFileTimeUtc().ToString()
        guid          = [guid]::NewGuid().ToString()
        id            = & $NextId
        name          = [string]$Node.name
        type          = "folder"
    }
}

function New-EmptyEdgeBookmarkJson {
    return [pscustomobject]@{
        checksum = ""
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
                children      = @()
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

function Merge-ChromeBookmarksIntoEdge {
    param(
        [object]$ChromeBookmarks,
        [object]$EdgeBookmarks,
        [string]$ProfileName
    )

    if ($null -eq $EdgeBookmarks) {
        $EdgeBookmarks = New-EmptyEdgeBookmarkJson
    }

    if ($null -eq $EdgeBookmarks.roots.other.children) {
        $EdgeBookmarks.roots.other.children = @()
    }

    $nextId = New-BookmarkIdGenerator -StartAt (Get-MaxBookmarkId -BookmarkJson $EdgeBookmarks)
    $importChildren = @()

    foreach ($rootName in @("bookmark_bar", "other", "synced")) {
        $root = $ChromeBookmarks.roots.$rootName
        if ($null -ne $root -and @($root.children).Count -gt 0) {
            $importChildren += Copy-BookmarkNodeForEdge -Node $root -NextId $nextId
        }
    }

    if ($importChildren.Count -eq 0) {
        return $EdgeBookmarks
    }

    $folderName = "Chrome bookmarks from $ProfileName"
    $importFolder = [ordered]@{
        children      = $importChildren
        date_added    = (Get-Date).ToFileTimeUtc().ToString()
        date_modified = (Get-Date).ToFileTimeUtc().ToString()
        guid          = [guid]::NewGuid().ToString()
        id            = & $nextId
        name          = $folderName
        type          = "folder"
    }

    $existingChildren = @($EdgeBookmarks.roots.other.children)
    $EdgeBookmarks.roots.other.children = @($existingChildren + @($importFolder))
    return $EdgeBookmarks
}

function Stop-BrowserProcessIfRequested {
    param(
        [switch]$Enabled,
        [string]$LogPath
    )

    if (-not $Enabled) {
        Write-RunLog -Path $LogPath -Message "Browser close step skipped. Use -CloseBrowsers when a managed deployment requires it."
        return
    }

    foreach ($name in @("chrome", "msedge")) {
        Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 2
    Write-RunLog -Path $LogPath -Message "Requested Chrome and Edge process stop before bookmark migration."
}

function Start-EdgeIfRequested {
    param(
        [switch]$Enabled,
        [string]$LogPath
    )

    if (-not $Enabled) {
        Write-RunLog -Path $LogPath -Message "Edge restart step skipped. Use -RestartEdge if you want Edge to reload favorites after migration."
        return
    }

    Start-Process "msedge.exe" -ErrorAction SilentlyContinue
    Write-RunLog -Path $LogPath -Message "Requested Microsoft Edge restart after bookmark migration."
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $BackupRootPath)) {
    New-Item -ItemType Directory -Path $BackupRootPath -Force | Out-Null
}

$RunLogPath = Join-Path $OutputDirectory "run-log.txt"
$ReportPath = Join-Path $OutputDirectory "migration-report.csv"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Set-Content -LiteralPath $RunLogPath -Value @("Browser bookmark migration run started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")") -Encoding UTF8
Stop-BrowserProcessIfRequested -Enabled:$CloseBrowsers -LogPath $RunLogPath

$reportRows = New-Object System.Collections.Generic.List[object]
$profiles = Get-LocalUserProfile -RootPath $ProfileRootPath -IncludeSystem:$IncludeSystemProfiles

foreach ($profile in $profiles) {
    $profileName = $profile.Name
    $chromePath = Join-Path $profile.FullName $ChromeRelativeBookmarkPath
    $edgePath = Join-Path $profile.FullName $EdgeRelativeBookmarkPath
    $profileBackupFolder = Join-Path $BackupRootPath $profileName
    $backupPath = Join-Path $profileBackupFolder "ChromeBookmarks-$profileName-$timestamp.html"

    Write-RunLog -Path $RunLogPath -Message "Processing profile: $profileName"

    try {
        $chromeBookmarks = Read-BookmarkJson -Path $chromePath
        if ($null -eq $chromeBookmarks) {
            Write-RunLog -Path $RunLogPath -Message "Skipping $profileName because Chrome bookmarks were not found."
            $reportRows.Add([pscustomobject]@{
                ProfileName      = $profileName
                Status           = "Skipped"
                Reason           = "ChromeBookmarksNotFound"
                BackupPath       = ""
                EdgeBookmarkPath = $edgePath
            })
            continue
        }

        Export-ChromeBookmarksToHtml -ChromeBookmarks $chromeBookmarks -OutputPath $backupPath
        Write-RunLog -Path $RunLogPath -Message "Chrome bookmark backup created for $profileName."

        $edgeBookmarks = Read-BookmarkJson -Path $edgePath
        $merged = Merge-ChromeBookmarksIntoEdge -ChromeBookmarks $chromeBookmarks -EdgeBookmarks $edgeBookmarks -ProfileName $profileName

        $edgeParent = Split-Path -Parent $edgePath
        if (-not (Test-Path -LiteralPath $edgeParent)) {
            New-Item -ItemType Directory -Path $edgeParent -Force | Out-Null
        }

        $merged | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $edgePath -Encoding UTF8
        Write-RunLog -Path $RunLogPath -Message "Merged Chrome bookmarks into Edge for $profileName."

        $reportRows.Add([pscustomobject]@{
            ProfileName      = $profileName
            Status           = "Migrated"
            Reason           = ""
            BackupPath       = $backupPath
            EdgeBookmarkPath = $edgePath
        })
    } catch {
        Write-RunLog -Path $RunLogPath -Message "Failed profile $profileName. $($_.Exception.Message)"
        $reportRows.Add([pscustomobject]@{
            ProfileName      = $profileName
            Status           = "Failed"
            Reason           = $_.Exception.Message
            BackupPath       = $backupPath
            EdgeBookmarkPath = $edgePath
        })
    }
}

$reportRows | Export-Csv -LiteralPath $ReportPath -NoTypeInformation
Start-EdgeIfRequested -Enabled:$RestartEdge -LogPath $RunLogPath
Write-RunLog -Path $RunLogPath -Message "Migration report written to $ReportPath"
