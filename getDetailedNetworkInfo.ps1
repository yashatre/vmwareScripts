<#
###############################################################################
# Script: getDetailedNetworkInfo.ps1                                          #
# ------------                                                                #
# Developer: Yashodhan Atre                                                   #  
# ------------                                                                #
# Discription:                                                                #
# The following script will provide informarion about the following network   #
# Objects.                                                                    #
# Host, VSwitch, VSwitch Ports, VSwitch Ports in use, Physical Nic Name,      #
# Speed, MAC, Switch Device ID, Port ID, Observed Network ranges, VLAN’s      #
#                                                                             #
# ------------                                                                #
# Version: 1.0                                                                #
# ------------                                                                #
# Note:                                                                       #
# Users need to replace the brackets '<>' with a valid value.                 #
# ------------                                                                #
#                                                                             #
#                                                                             #
###############################################################################
#>
# Set the VI Server and Filename before running
Connect-VIServer vcenter.digitalsense.com.au
$filename = "C:\Users\yash.atre\Desktop\Scripts\DetailedNetworkInfo.csv"
 
Write "Gathering VMHost objects"
$vmhosts = Get-VMHost | Sort Name | Where-Object {$_.ConnectionState -eq "Connected"} | Get-View
$MyCol = @()
foreach ($vmhost in $vmhosts){
 $ESXHost = $vmhost.Name
 Write "Collating information for $ESXHost"
 $networkSystem = Get-view $vmhost.ConfigManager.NetworkSystem
 foreach($pnic in $networkSystem.NetworkConfig.Pnic){
     $pnicInfo = $networkSystem.QueryNetworkHint($pnic.Device)
     foreach($Hint in $pnicInfo){
         $NetworkInfo = "" | select-Object Host, vSwitch, vSwitchPorts, vSwitchPrtInUse, PNic, Speed, MAC, DeviceID, PortID, Observed, VLAN
         $NetworkInfo.Host = $vmhost.Name
       $NetworkInfo.vSwitch = Get-Virtualswitch -VMHost (Get-VMHost ($vmhost.Name)) | where {$_.Nic -eq ($Hint.Device)}
         $NetworkInfo.vSwitchPorts = $NetworkInfo.vSwitch.NumPorts
       $NetworkInfo.vSwitchPrtInUse = ($NetworkInfo.vSwitch.NumPorts - $NetworkInfo.vSwitch.NumPortsAvailable)
       $NetworkInfo.PNic = $Hint.Device
         $NetworkInfo.DeviceID = $Hint.connectedSwitchPort.DevId
         $NetworkInfo.PortID = $Hint.connectedSwitchPort.PortId
         $record = 0
         Do{
             If ($Hint.Device -eq $vmhost.Config.Network.Pnic[$record].Device){
                 $NetworkInfo.Speed = $vmhost.Config.Network.Pnic[$record].LinkSpeed.SpeedMb
                 $NetworkInfo.MAC = $vmhost.Config.Network.Pnic[$record].Mac
             }
             $record ++
         }
         Until ($record -eq ($vmhost.Config.Network.Pnic.Length))
         foreach ($obs in $Hint.Subnet){
             $NetworkInfo.Observed += $obs.IpSubnet + " "
             Foreach ($VLAN in $obs.VlanId){
                 If ($VLAN -eq $null){
                 }
                 Else{
                     $strVLAN = $VLAN.ToString()
                     $NetworkInfo.VLAN += $strVLAN + " "
                 }
             }
         }
         $MyCol += $NetworkInfo
     }
 }
}
$Mycol | Sort Host, PNic | Export-Csv $filename -NoTypeInformation