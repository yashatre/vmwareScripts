#$reportName = "C:\Users\yash.atre\Desktop\Scripts\Uptime-Report.xlsx"
$date = get-date
Get-VMHost |Select Name, Parent, connectionstate, @{N="Last Boot (UTC)";E={$_.ExtensionData.Summary.Runtime.BootTime}}, 
@{N="Uptime (Days)"; E={New-Timespan -Start $_.ExtensionData.Summary.Runtime.BootTime -End $date | Select -ExpandProperty Days}} | ft -a
 
#Export-Excel -Path $reportName -WorksheetName Uptime