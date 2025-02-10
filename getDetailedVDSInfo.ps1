<#
Script Name : getDetailedVDSInfo.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Usage		: 
This utility fetches details of all VDS (Virtual Distributed Switch) in the vCenter Server.
The inventory collected has information about VDS Name, Datacenter, Version, Numer Esx Hosts connected, 
ESXi Host Members, PortGroup Name, Number of Uplink Ports, Uplink PortGroup, Uplink Port Name, 
Number of Ports, MTU, Vendor, Contact Name, Contact Details, Link Discovery Protocol, 
Link Discovery Protocol Operation, vLan Configuration, Notes, Id, Folder, CreateTime, 
Health Check configuration, Over All Status, Multicast Filtering Mode, LACP api version, 
Network Resource Control version, vCenter server name.

To export information to CSV file use below command.
============
<Script Name> | Export-Csv <File Path> -NoTypeInformation
e.g. 
getDetailedVDSInfo.ps1 | Export-Csv C:\temp\vdsDetails.csv -NoTypeInformation
============
Code Disclaimer:
##########
The following is the disclaimer that applies to all scripts, functions, one-liners, etc. 
This disclaimer supersedes any disclaimer included in any script, function, one-liner, etc.
You running this script/function means you will not blame the author(s) if this breaks your 
stuff. This script/function is provided AS IS without warranty of any kind. Author(s) 
disclaim all implied warranties including, without limitation, any implied warranties of 
merchantability or of fitness for a particular purpose. The entire risk arising out of the 
use or performance of the sample scripts and documentation remains with you. In no event 
shall author(s) be held liable for any damages whatsoever (including, without limitation, 
damages for loss of business profits, business interruption, loss of business information, 
or other pecuniary loss) arising out of the use of or inability to use the script or documentation.
##########
#>

##Utility Function definitions
function disconnectServer(){
	Write-Host "Checking for unclosed vCenter Connections..." -noNewLine

	try{

		# We don't want a previous connection because it will cause duplicate entries later on.
		Disconnect-VIServer * -confirm:$false

		# Run it again just in case it missed one or there were already multiple connections. 
		Disconnect-VIServer * -confirm:$false
	}

	catch{

		# Nothing to do here since there were no servers to disconnect from.

		Write-Host -foregroundColor Green "[Done], VISever has been successfully disconnected!"
	}
}

## Attempt to connect to the vCenter Server
function connectServer {
	
	$vCenterServer = Read-Host "Enter vCenter Server FQDN :"
	Write-Host -foreGroundColor Cyan "`nInitializing Services:"
	
	try{
		Write-Host "Connecting to vCenter $vCenterServer..." -noNewLine

		$vcConnection = Connect-ViServer -server $vCenterServer

		Write-Host -foreGroundColor Green "[Done]"
	}

	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not authenticate to vCenter"
		throw $_.Exception.Message
		exit
	}
}

function getDVSwitchDetails {
	$vdSwitch = Get-VDSwitch
	foreach ($vds in $vdSwitch)
	{
		$esxiList = @()
		$esxiServers = $vds.ExtensionData.Summary.HostMember
		if ($null -ne $esxiServers)
		{
			foreach ($esxi in $esxiServers)
			{
				$esxiList += Get-VMHost -Id $esxi | Select-Object -ExpandProperty Name
			}
		}

		<#
		$vdPortGroupList = @()
		$vdPortGroups = $vds.ExtensionData.Portgroup
		foreach ($vdportgroup in $vdPortGroups)
		{
			$vdPortGroupList += Get-VDPortgroup -Id $vdportgroup | Select-Object -ExpandProperty Name
		}
		#>
		
		$healthCheckConf1 = $vdSwitch.ExtensionData.Config.HealthCheckConfig[0] | ForEach-Object {"{0}: Enabled={1}, Interval={2}" -f $_.gettype().Name, $_.Enable, $_.Interval}
		$healthCheckConf2 = $vdSwitch.ExtensionData.Config.HealthCheckConfig[1] | ForEach-Object {"{0}: Enabled={1}, Interval={2}" -f $_.gettype().Name, $_.Enable, $_.Interval}
		
			[PSCustomObject]@{
			vCenterServer = ([System.Uri]$vds.ExtensionData.Client.ServiceUrl).Host
			Datacenter = $vds.Datacenter
			VDSName = $vds.Name
			Version = $vds.Version
			NumHosts = $vds.ExtensionData.Summary.NumHosts
			HostMembers = $esxiList -join ', '
			NumUplinkPorts = $vds.NumUplinkPorts -join ', '
			PortGroupName = $vds.ExtensionData.Summary.PortgroupName 
			UplinkPortGroup = (Get-VDPortgroup -Id $vds.ExtensionData.Config.UplinkPortgroup).Name
			UplinkPortName = $vds.ExtensionData.Config.UplinkPortPolicy.UplinkPortName -join ', '
			#VDPortGroups = $vdPortGroupList -join ', '
			NumPorts = $vds.NumPorts
			Id = $vds.Id
			Mtu = $vds.Mtu
			VlanConfiguration = $vds.VlanConfiguration
			Folder = $vds.Folder
			CreateTime = $vds.ExtensionData.Config.CreateTime
			MulticastFilteringMode = $vds.ExtensionData.Config.MulticastFilteringMode
			LacpApiVersion = $vds.ExtensionData.Config.LacpApiVersion
			NetworkResourceControlVersion = $vds.ExtensionData.Config.NetworkResourceControlVersion
			LinkDiscoveryProtocol = $vds.LinkDiscoveryProtocol
			LinkDiscoveryProtocolOperation = $vds.LinkDiscoveryProtocolOperation
			healthCheckConf1 = $healthCheckConf1
			healthCheckConf2 = $healthCheckConf2
			OverallStatus = $vds.ExtensionData.OverallStatus
			Vendor = $vds.Vendor
			ContactName = $vds.Contactname
			ContactDetails = $vds.ContactDetails
			Notes = $vds.Notes #$vds.Uid.Split('@')[1].Split(':')[0]		
		}
		Write-Host "`r==============================================`r`n"
	}
}	

function main{
	disconnectServer
	connectServer
	getDVSwitchDetails
	disconnectServer
}

main
