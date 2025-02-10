$report =@() 
Get-VM "*production*" | Get-View | %{ 
 $VMname = $_.Name 
 $_.Config.Hardware.Device | where {$_.DeviceInfo.Label -match "Network Adapter"} | %{
        $row = "" | Select VM, MAC, Type 
        $row.VM = $VMname 
        $row.MAC = $_.MacAddress 
        $row.Type = $_.AddressType 
        $report += $row 
  } 
  } 
$report 