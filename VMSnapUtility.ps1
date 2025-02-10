<#
Script Name : VMSnapUtility.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Usage		: 
This is a utility to automate features around VMware vCenter Snapshots. 
This is a menu driven utility and user can select the workflow according to the need. 

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
    Write-Host "1: Press '1' Connect to vCenter Server."
    Write-Host "2: Press '2' Disconnect all vCenter Server connections."
    Write-Host "3: Press '3' Create Snapshot."
    Write-Host "4: Press '4' Delete Snapshot."
    Write-Host "5: Press '5' Count Snapshot/s."
}

## Disconnect all viServer instances so we don't get duplicate results.

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

		Write-Host -foregroundColor Green "[Done]"

	}
}

## Attempt to connect to the vCenter Server
function connectServer($vCenterName){
	
	$vCenterServer = $vCenterName
	Write-Host -foreGroundColor Cyan "`nInitializing Services:"
	
	try{

		Write-Host "Connecting to vCenter $vcAddress..." -noNewLine

		$vcConnection = Connect-ViServer -server $vCenterServer

		Write-Host -foreGroundColor Green "[Done]"

	}

	catch{

		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not authenticate to vCenter"

		exit

	}
}
	
function createSnapshot($vm){

     try{

          Write-Host "Creating new snapshot for $vm"

          Get-VM $vm | New-Snapshot -name "$vm Backup" -description "Created with VMSnapUtility.ps1" -memory:$false -quiesce:$false -confirm:$false

          Write-Host -foregroundcolor "Green" "`nDone."

     }

     catch{

          Write-Host -foregroundcolor RED -backgroundcolor BLACK "Error creating new snapshot. See VCenter log for details."

     }

}

function removeSnapshot($vm){

     try{

          Write-Host "Previous snapshot detected, removing first..."

          Get-VM $vm | Get-Snapshot -name $snapshot | Remove-Snapshot -confirm:$false

          Write-Host -foregroundcolor "Green" "`nDone."

     }

     catch {

          Write-Host -foregroundcolor RED -backgroundcolor BLACK "Error deleting old snapshot. See VCenter log for details."

     break

     }

}

function getCreateSnapshot($vmName){
	$vmList = Get-VM $vmName

	forEach ($vm in $vmList) {

		$snapshot = Get-VM $vm | Get-Snapshot | Select-Object -expandProperty name

		if ($snapshot -eq "" -or $snapshot -eq $null){

			#No snapshots, create one at top level.

			createSnapshot($vm)

		}

		else {

			#Snapshot Exists, remove before continuing.

			removeSnapshot($vm)

			createSnapshot($vm)

		}

	}
}

function getDeleteSnapshot($vmName){
	$vmList = Get-VM $vmName

	forEach ($vm in $vmList) {

		$snapshot = Get-VM $vm | Get-Snapshot | Select-Object -expandProperty name

		if ($snapshot -eq "" -or $snapshot -eq $null){

			#No snapshots found, print the followng
			Write-Host "No snapshots detected..."
			
		}

		else {

			#Snapshot Exists, remove before continuing.

			removeSnapshot($vm)

		}

	}
}

do
 {
     Show-Menu
     $selection = Read-Host "Please make a selection :"
     switch ($selection)
     {
         '1' {
            connectServer('<vCenter Server FQDN>')
         } 
		 '2' {
            disconnectServer
         } 
		 '3' {
            getCreateSnapshot('<VMname-*>')
         } 
		 '4' {
            getDeleteSnapshot('<VMname-*')
         } 
		 '5' {
             'This functionality is NOT implemented yet!'
         }
     }
     pause
 }
 until ($selection -eq '0')
 
 
 