param(
    [string]$PublicFolderInventoryCsv = (Join-Path $PSScriptRoot "..\examples\public-folder-inventory.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output\04-public-folders")
)

. (Join-Path $PSScriptRoot "O365MigrationDemo.Shared.ps1")

Initialize-DemoOutputDirectory -Path $OutputDirectory

$publicFolders = Import-RequiredCsv -Path $PublicFolderInventoryCsv -RequiredColumns @(
    "FolderPath", "Owner", "LastKnownUsage", "CurrentPermissionCount", "RecommendedDisposition"
)

$folderPlan = foreach ($folder in $publicFolders) {
    [pscustomobject]@{
        FolderPath = $folder.FolderPath
        Owner = $folder.Owner
        LastKnownUsage = $folder.LastKnownUsage
        CurrentPermissionCount = $folder.CurrentPermissionCount
        RecommendedDisposition = $folder.RecommendedDisposition
        CleanupStatus = if ($folder.RecommendedDisposition -eq "ReviewWithOwner") { "NeedsOwnerReview" } else { "Planned" }
        PermissionCleanupAction = Get-PublicFolderAction -Folder $folder
        EvidenceToKeep = "Permission export, owner decision, archive or conversion result"
    }
}

$folderPlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "public-folder-retirement-plan.csv") -NoTypeInformation

Write-Output "Public folder retirement plan written to $OutputDirectory"
