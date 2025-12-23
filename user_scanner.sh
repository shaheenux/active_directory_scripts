# File: UserAuditor.ps1
# Description: Windows Local User Security Auditor (Default Read-Only Mode)

# 1. Setup Environment
$OutputFolder = "Audit_Reports"
if (!(Test-Path $OutputFolder)) { 
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null 
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$ReportPath = "$PSScriptRoot\$OutputFolder\UserAudit_$Timestamp.csv"

Write-Host "==============================================" -ForegroundColor Gray
Write-Host "   WINDOWS USER SECURITY AUDIT - STARTING     " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Gray

# 2. Gather Data via Get-LocalUser
$AuditData = Get-LocalUser | Select-Object Name, Enabled, `
    @{Name="Last_Logon"; Expression={$_.LastLogon}}, `
    @{Name="Password_Age_Days"; Expression={
        if ($_.PasswordLastSet) {
            (New-TimeSpan -Start $_.PasswordLastSet -End (Get-Date)).Days
        } else { "N/A" }
    }}, `
    @{Name="Password_Expires"; Expression={$_.PasswordExpires}}, `
    @{Name="Account_Type"; Expression={$_.PrincipalSource}}

# 3. Export to CSV
$AuditData | Export-Csv -Path $ReportPath -NoTypeInformation

# 4. Console Summary
foreach ($User in $AuditData) {
    $Status = if ($User.Enabled) { "ACTIVE" } else { "DISABLED" }
    $Color = if ($User.Enabled) { "Green" } else { "Red" }
    
    Write-Host "[*] Account: " -NoNewline
    Write-Host "$($User.Name.PadRight(15))" -ForegroundColor White -NoNewline
    Write-Host " | Status: " -NoNewline
    Write-Host "$($Status.PadRight(10))" -ForegroundColor $Color -NoNewline
    Write-Host " | Password Age: $($User.Password_Age_Days) Days"
}

Write-Host "==============================================" -ForegroundColor Gray
Write-Host "AUDIT COMPLETE. Report: $ReportPath" -ForegroundColor Cyan