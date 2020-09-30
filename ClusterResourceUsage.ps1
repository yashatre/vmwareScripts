<#
.SYNOPSIS Getting Cluster usage/capacity data on CPU, Memory and Storage 
.NOTES Please add the vCenter server IP/credetails as per your environment
.NOTES Please change the values for '-User' per your environment.
.NOTES Developer : Yashodhan Atre
.NOTES Developer Email : yashatre.code@gmail.com
#>

$SecretFile = "data.conf"
$SecureString = ConvertTo-SecureString -String (Get-Content $SecretFile)
$Pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
$content = [Runtime.InteropServices.Marshal]::PtrToStringAuto($Pointer)


Connect-VIServer -Server 10.10.0.235 -User yash.atre@digitalsense.com.au -Password $content

$report = @()

Write-host "Report Generation is in Progress..."

foreach ($clusterName in Get-Cluster){

	$row = '' | select ClusterName, CPUCapacity, CPUused, CPUusedPercent, MemCapacity, MemUsed, MemUsedPercent, StorageCapacity, StorageUsed, StorageUsedPercent
  
	$cluster = Get-Cluster -name $clusterName
	$cluster_view = Get-View ($cluster)
	$resourceSummary = $cluster_view.GetResourceUsage()
	$row.ClusterName = $cluster_view.Name
	$row.CPUCapacity = $resourceSummary.CpuCapacityMHz
	$row.CPUused = $resourceSummary.CpuUsedMHz
	$row.CPUusedPercent = [math]::Round((($resourceSummary.CpuUsedMHz / $resourceSummary.CpuCapacityMHz) * 100),2).toString() +'%'
	$row.MemCapacity = $resourceSummary.MemCapacityMB
	$row.MemUsed = $resourceSummary.MemUsedMB
	$row.MemUsedPercent = [math]::Round((($resourceSummary.MemUsedMB / $resourceSummary.MemCapacityMB) * 100),2).toString() +'%'
	$row.StorageCapacity = $resourceSummary.StorageCapacityMB
	$row.StorageUsed = $resourceSummary.StorageUsedMB
	$row.StorageUsedPercent = [math]::Round((($resourceSummary.StorageUsedMB / $resourceSummary.StorageCapacityMB) * 100),2).toString() +'%'

	$report += $row
}
$report | Sort  ClusterName | Export-Csv -Path "Clusterstats.csv" #Please change the CSV file location as per your requirement

Write-host "Report Generation is completed, please chekc the CSV file"