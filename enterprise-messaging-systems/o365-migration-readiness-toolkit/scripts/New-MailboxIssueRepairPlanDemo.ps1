param(
    [string]$MailboxIssueQueueCsv = (Join-Path $PSScriptRoot "..\examples\mailbox-issue-queue.csv"),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\output\05-mailbox-repair")
)

. (Join-Path $PSScriptRoot "O365MigrationDemo.Shared.ps1")

Initialize-DemoOutputDirectory -Path $OutputDirectory

$mailboxIssues = Import-RequiredCsv -Path $MailboxIssueQueueCsv -RequiredColumns @(
    "UserPrincipalName", "IssueType", "CurrentState", "RequestedAction"
)

$repairPlan = foreach ($issue in $mailboxIssues) {
    [pscustomobject]@{
        UserPrincipalName = $issue.UserPrincipalName
        IssueType = $issue.IssueType
        CurrentState = $issue.CurrentState
        RequestedAction = $issue.RequestedAction
        RepairPlan = Get-MailboxRepairPlan -Issue $issue
        SafeToAutomate = if ($issue.IssueType -eq "DuplicateLicensePath") { "ReviewFirst" } else { "No" }
        WhyItMatters = switch ($issue.IssueType) {
            "SoftDeletedMailbox" { "Soft-deleted mailbox state can block or confuse migration until it is repaired" }
            "DisabledAccountWithMailbox" { "Disabled accounts need owner review before mailbox work continues" }
            "DuplicateLicensePath" { "Duplicate licensing can waste licenses and make reporting inaccurate" }
            default { "Unexpected mailbox state needs review before the next migration wave" }
        }
    }
}

$repairPlan | Export-Csv -LiteralPath (Join-Path $OutputDirectory "mailbox-issue-repair-plan.csv") -NoTypeInformation

Write-Output "Mailbox issue repair plan written to $OutputDirectory"
