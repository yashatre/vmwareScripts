<# ==================================================================
Title: 
Script Name : EmailOldSnapshotInfo.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Description: List Snapshots older than x days and then email it as an attachment
Requirements: Windows Powershell with PowerCLI installed
Usage: .\EmailOldSnapshotInfo.ps1
==================================================================== #>
function findOldSnapshots
	Add-PSSnapin VMware.VimAutomation.Core
	 
	$viserver = Connect-VIServer "vCenter_Server_Name_or_IP" -user "userName" -password "your vCenter Password"
	$SnapshotReport = Get-VM  | Get-Snapshot | where { $_.Created -lt (Get-Date).AddDays(-10)} | `
	select VM, Name, @{N="Size in MB";E={[math]::round($_.SizeMB, 2)}}, Created | `
	ConvertTo-Html | Set-Content OldSnapshotReport.html
	$EmailFrom = "From_email_id"
	$EmailTo = "To_email_id"
	$CcTo = "CC_email_id"
	$subject = "List of snapshots older then 10 days"
	$body = "Please find the enclosed snpshot report in attachments: OldSnapshotReport.html"
	$smtp = "SMTP_server_address"
	$viserver; $SnapshotReport; Send-MailMessage -From $EmailFrom -To $EmailTo -Cc $CcTo -Subject $subject -Body $body -SmtpServer $SMTP -Attachments "OldSnapshotReport.html" -Priority "High"
	Remove-Item OldSnapshotReport.html
	Disconnect-VIServer "vCenter_Server_Name_or_IP" -Confirm:$false

function main {
	findOldSnapshots
}

main
