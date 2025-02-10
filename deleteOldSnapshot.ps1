<# ==================================================================
Title: 
Script Name : deleteOldSnapshot.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Description: List Snapshots older than x days and then email it as an attachment
Requirements: Windows Powershell with PowerCLI installed
Usage: .\Get_Snapshot_list.ps1
==================================================================== #>

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
    Write-Host "1: Press '1' Show ALL Old Snapshots"
    Write-Host "2: Press '2' Delete Snapshots"
}

function disconnectServer{
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

function showOldSnapshots{
	try{
		Get-VM  | Get-Snapshot | where { $_.Created -lt (Get-Date).AddDays(-10)} | select VM, Name, Created
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nUnable to display snapshots.`n`n"
		throw $_.Exception.Message
		exit
	}
}

function deleteSnapshots{
	try{
		Add-PSSnapin VMware.VimAutomation.Core -ErrorAction 'SilentlyContinue'
		Clear-Host
		
		[string[]] $_snapshotList= @()
		$_snapshotList = Read-Host "Enter comma seperated values, `Ex. snapshot1,snapshot2 `nEnter values here :" 
		$_snapshotList = $_snapshotList.Split(',')
		
		forEach ($snapshot in $_snapshotList){
			#Write-Host -f yellow "snapshot : "$snapshot"`n"
			Get-VM | Get-Snapshot | Where {$_.Name -match "$snapshot"} | Remove-Snapshot -Confirm:$false
			Clear-Host
			Write-Host -f green "Deleted : $snapshot`n"
		}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nUnable to delete the snapshot."
		throw $_.Exception.Message
		exit
	}
}

function main{
	disconnectServer
	connectServer
	
	do
	 {
		 Show-Menu
		 $selection = Read-Host "Please make a selection :"
		 switch ($selection)
		 {
			 '1' {
				showOldSnapshots
			 } 
			 '2' {
				deleteSnapshots
			 } 
		 }
		 pause
	 }
	 until ($selection -eq '0') 
	 
}
main
