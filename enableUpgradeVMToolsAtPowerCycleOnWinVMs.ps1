<#
Script Name : enableUpgradeVMToolsAtPowerCycleOnWinVMs.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Usage		: 
This utility turns on the feature to install a new version of the VMware tools when a Windows host reboots. 

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

## Define Workslows in the script as a menu
function Show-Menu
{
    param (
        [string]$Title = 'Select Your Option'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "0: Press '0' to QUIT!."
    Write-Host "1: Press '1' For ALL VMs in the Datacenter"
    Write-Host "2: Press '2' For ALL VMs in the Cluster"
    Write-Host "3: Press '3' For Selected VM/s"
}


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

function getWindowsVMList {
	try{
		#Get Windows Guest machines from vCenter server
		$WinVMList = Get-VM | %{Get-View $_.ID} | where {$_.Guest.GuestFamily -match "windowsGuest"}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not find the given guest OS..."
		throw $_.Exception.Message
		exit
	}
}

function setToolsUpgradePolicy($vmList) {
	try{

		#Create new Virtual Machince Config Spec
		$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

		#Write new config options to VMs
		foreach ($vm in $vmList){
			
			$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
			$vmConfigSpec.tools = New-Object VMware.Vim.ToolsConfigInfo
			$vmConfigSpec.tools.toolsUpgradePolicy = "upgradeAtPowerCycle"
			$vm.ExtensionData.ReconfigVM_Task($vmConfigSpec)
		}
		Write-Host -foregroundColor Green "New policy configured successfully!"
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not create the config spec or write config options..."
		throw $_.Exception.Message
		exit
	}

}

function setPolicyByDatacenter {
	try{
		$datacenterList = Get-Datacenter
		Write-Host "List Of Datacenters in this vCenter Server : "$datacenterList
		$datacenter = Read-Host "Please Enter name of datacenter want to select :"
		
		$datacenterVMList = Get-Datacenter $datacenter | getWindowsVMList
		setToolsUpgradePolicy($datacenterVMList)
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not execute the function..."
		throw $_.Exception.Message
		exit
	}
}

function setPolicyByCluster {
	try{
		$clusterList = Get-Cluster
		Write-Host "List Of clusters in this vCenter Server : "$clusterList
		$cluster = Read-Host "Please Enter name of cluster want to select :"
		
		$clusterVMList = Get-cluster $cluster | getWindowsVMList
		setToolsUpgradePolicy($clusterVMList)
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not execute the function..."
		throw $_.Exception.Message
		exit
	}
}

function setPolicyOnSelectedVMs {
	try{
		$vmName = Read-Host "Enter the VM Name or Regex (VMname*) value :"
		$vmList = Get-VM $vmName
		
		setToolsUpgradePolicy($vmList)
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not execute the function..."
		throw $_.Exception.Message
		exit
	}
}

function main {
	disconnectServer
	connectServer
	
	do
	 {
		 Show-Menu
		 $selection = Read-Host "Please make a selection :"
		 switch ($selection)
		 {
			 '1' {
				setPolicyByDatacenter
			 } 
			 '2' {
				setPolicyByCluster
			 } 
			 '3' {
				setPolicyOnSelectedVMs 
			 } 
		 }
		 pause
	 }
	 until ($selection -eq '0')
	 
}

main
