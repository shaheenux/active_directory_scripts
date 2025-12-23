
# 🛡️ Windows User Security Auditor
**A lightweight, non-destructive security auditing suite for Windows Environments.**

## 📖 Project Overview
This tool is designed to provide immediate visibility into the local user landscape of a Windows machine. By default, it operates in a **Read-Only** capacity, ensuring that system configurations remain untouched while gathering deep security metadata. The auditor provides both real-time console feedback and persistent CSV reports for compliance documentation.

## ✨ Features
- **Account Discovery:** Lists all local users, including hidden system accounts with security identifiers (SIDs)
- **Status Monitoring:** Clearly highlights Active vs. Disabled accounts with color-coded console output
- **Credential Lifecycle:** Tracks password age to identify stale credentials and potential security risks
- **Comprehensive Reporting:** Automatically exports to timestamped CSV files for audit trails
- **Zero Footprint:** No system modifications, no registry changes, no service installations

## 📂 File Structure
```text
.
├── UserAuditor.ps1              # Core auditing engine (PowerShell)
├── README.md                    # Complete project documentation
├── user_guide.txt               # Quick reference operational manual
├── sample_servers.txt           # Example target list (for reference)
└── Audit_Reports/               # Auto-generated repository for reports
    ├── UserAudit_20240115_1430.csv
    ├── UserAudit_20240116_0900.csv
    └── UserAudit_20240117_1600.csv
```

## 🚀 Installation & Deployment

### Prerequisites
- **Windows PowerShell 5.1** or higher (included with Windows 10/11 and Server 2016+)
- **Administrative privileges** (required to query local user security data)
- **PowerShell Execution Policy** adjustment (one-time setup)

### Step 1: Download and Extract
Create a dedicated directory for the auditor:
```powershell
mkdir C:\SecurityAudit
cd C:\SecurityAudit
# Place UserAuditor.ps1, README.md, and user_guide.txt in this directory
```

### Step 2: Configure Execution Policy (One-Time)
Run PowerShell as Administrator and set the execution policy for the current session:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```
*Note: This only affects the current PowerShell session and doesn't permanently change system policy.*

### Step 3: Run the Auditor
Execute the script to perform a security audit:
```powershell
.\UserAuditor.ps1
```

### Step 4: Schedule Regular Audits (Optional)
For continuous monitoring, create a scheduled task:
```powershell
# Create a scheduled task to run daily at 9 AM
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\SecurityAudit\UserAuditor.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -TaskName "DailyUserAudit" `
    -Action $Action -Trigger $Trigger -RunLevel Highest
```

## 🎯 Use Cases & Scenarios

### 1. Compliance Auditing
Meet regulatory requirements (HIPAA, PCI-DSS, SOX) by maintaining evidence of:
- Regular user account reviews
- Password policy adherence tracking
- Access control verification

### 2. Security Incident Response
During security investigations, quickly:
- Identify unauthorized local accounts
- Detect stale credentials that could be compromised
- Map user account timelines

### 3. System Migration Planning
When upgrading or migrating systems:
- Document all local accounts before migration
- Identify accounts that should be disabled vs migrated
- Clean up legacy service accounts

## 📊 Interpreting Results

### Key Metrics to Monitor
| Metric | Warning Threshold | Critical Threshold | Action Required |
|--------|-------------------|-------------------|-----------------|
| Password Age | > 90 days | > 180 days | Schedule password rotation |
| Disabled Accounts | Any | > 5 | Review for deletion |
| System Accounts | N/A | Any interactive logon | Restrict to service-only |
| Password Never Expires | Any non-service account | > 2 non-service accounts | Enforce expiration policy |

### Report Columns Explained
- **Name**: Local account username
- **Enabled**: Boolean (True/False) account status
- **Last_Logon**: Most recent authentication timestamp
- **Password_Age_Days**: Days since last password change
- **Password_Expires**: Boolean indicating if password has expiration
- **Account_Type**: Source (Local, Active Directory, Azure AD)

## 🛡️ Security Best Practices

### 1. Regular Audit Schedule
- **Daily**: Critical servers and domain controllers
- **Weekly**: All member servers and workstations
- **Monthly**: Full infrastructure review

### 2. Report Retention
- Maintain audit reports for **minimum 90 days**
- Archive quarterly reports for **7 years** for compliance
- Store reports in encrypted format if containing sensitive data

### 3. Follow-up Actions
Based on audit findings:
1. **Password Age > 90 days**: Initiate password reset procedures
2. **Disabled accounts > 30 days**: Consider permanent deletion
3. **Unknown/Unrecognized accounts**: Immediate investigation
4. **System accounts with recent logon**: Security review

## 🔄 Cross-Platform Considerations

### Running from Kali Linux
For penetration testers and security auditors:
```bash
# Install PowerShell on Kali
sudo apt update
sudo apt install -y powershell

# Connect to Windows target (WinRM must be enabled)
pwsh
Enter-PSSession -ComputerName TARGET_IP -Credential DOMAIN\User

# Run the auditor remotely
Invoke-Command -ComputerName TARGET_IP -FilePath ./UserAuditor.ps1
```

### Network Deployment
For enterprise-wide auditing:
```powershell
# Create target list
$computers = Get-Content .\network_servers.txt

# Execute audit across all targets
foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer `
        -FilePath .\UserAuditor.ps1 `
        -ErrorAction SilentlyContinue
}
```

## ⚠️ Limitations & Considerations

### Technical Limitations
- Requires local administrator privileges on target systems
- Cannot audit domain accounts (use `Get-ADUser` for Active Directory)
- Windows Server 2008 R2 or newer required for full functionality

### Security Considerations
- Audit reports may contain sensitive information - handle appropriately
- Ensure proper access controls on the audit script and reports
- Consider encrypting audit reports in transit and at rest

### Performance Impact
- Minimal CPU/memory usage during execution
- Network bandwidth negligible (local execution only)
- Disk I/O limited to CSV file creation (~1-10KB per audit)

## 🆘 Troubleshooting

### Common Issues
| Issue | Solution |
|-------|----------|
| "Execution Policy" error | Run `Set-ExecutionPolicy Bypass -Scope Process` |
| "Access Denied" error | Run PowerShell as Administrator |
| No output generated | Check if Audit_Reports folder exists |
| Missing user data | Verify running on Windows 8/Server 2012 or newer |

### Debug Mode
Enable verbose logging for troubleshooting:
```powershell
# Add to UserAuditor.ps1 before line 1
$VerbosePreference = "Continue"
```

## 📈 Advanced Usage Examples

### Custom Report Filtering
```powershell
# Import latest audit report
$report = Import-Csv (Get-ChildItem Audit_Reports\*.csv | Sort LastWriteTime -Desc | Select -First 1)

# Find high-risk accounts
$highRisk = $report | Where-Object {
    $_.Enabled -eq $true -and
    [int]$_.Password_Age_Days -gt 180 -and
    $_.Password_Expires -eq $false
}

# Export high-risk accounts
$highRisk | Export-Csv -Path "HighRiskAccounts.csv"
```

### Integration with SIEM Systems
```powershell
# Convert to JSON for Splunk/ELK ingestion
$report = Import-Csv "Audit_Reports\UserAudit_*.csv"
$report | ConvertTo-Json | Out-File "audit_data.json"

# Or send directly to syslog
$report | ForEach-Object {
    $message = "UserAudit: $($_.Name) | Age: $($_.Password_Age_Days) days"
    Send-SyslogMessage -Message $message -Severity Information
}
```

---

**Developed for efficiency. May your security be tight and your logs be clear.**
