<#
Script Name : FetchVMCreatedDeletedInfo.ps1
Version		: 1.0 
Developer	: Yashodhan Atre
Usage		: 
This utility helps user to fetch data/information regarding created or deleted VMs in vCenter Server. 
Utility is menu driven to facilitate users to select the kind of information they need to fetch from the system. 

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
    Write-Host "1: Press '1' List of VMs created"
    Write-Host "2: Press '2' List of VMs deleted"
    Write-Host "3: Press '3' List of VMs created in 'X' number of days"
    Write-Host "4: Press '4' List of VMs deleted in 'X' number of days"
    Write-Host "5: Press '5' Future Use"
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

		Write-Host -foregroundColor Green "[Done]"
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
		exit
	}
}


function lastVMCreated {
	$numOfVMs = Read-Host "How many VMs do you want to list ? [Enter a number between 1-100] :"
	if(($numOfVMs -lt 1) -and ($numOfVMs -gt 100)){
		Write-Host -foregroundcolor RED -backgroundcolor WHITE "Invalid Number!"
		break
	}
	else{
		Get-VIEvent -maxsamples 50000 | `
		where {$_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmBeingClonedEvent" -or $_.Gettype().Name -eq "VmBeingDeployedEvent"} | `
		Sort CreatedTime -Descending | `
		Select CreatedTime,UserName,FullformattedMessage -First $numOfVMs
	}
}

function lastVMDeleted {
	$numOfVMs = Read-Host "How many VMs do you want to list ? [Enter a number between 1-100] :"
	if(($numOfVMs -lt 1) -and ($numOfVMs -gt 100)){
		Write-Host -foregroundcolor RED -backgroundcolor WHITE "Invalid Number!"
		break
	}
	else{
		Get-VIEvent -maxsamples 50000 | `
		where {$_.Gettype().Name -eq "VmRemovedEvent"} | `
		Sort CreatedTime -Descending | `
		Select CreatedTime,UserName,FullformattedMessage -First $numOfVMs
	}
}

function vmCreatedInDays {
	$numOfDays = Read-Host "Number of days to look back ? [Enter a number between 1-90] :"
	if(($numOfVMs -lt 1) -and ($numOfVMs -gt 90)){
		Write-Host -foregroundcolor RED -backgroundcolor WHITE "Invalid Number Of Days Entered!"
		break
	}
	else{
		Get-VIEvent -maxsamples 50000 -Start (Get-Date).AddDays(-$numOfDays) | `
		where {$_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmBeingClonedEvent" -or $_.Gettype().Name -eq "VmBeingDeployedEvent"} | `
		Sort CreatedTime -Descending | `
		Select CreatedTime,UserName,FullformattedMessage
		
	}
}

function vmDeletedInDays {
	$numOfDays = Read-Host "Number of days to look back ? [Enter a number between 1-90] :"
	if(($numOfVMs -lt 1) -and ($numOfVMs -gt 90)){
		Write-Host -foregroundcolor RED -backgroundcolor WHITE "Invalid Number Of Days Entered!"
		break
	}
	else{
		Get-VIEvent -maxsamples 50000 -Start (Get-Date).AddDays(-$numOfDays) | `
		where {$_.Gettype().Name -eq "VmRemovedEvent"} | `
		Sort CreatedTime -Descending | `
		Select CreatedTime,UserName,FullformattedMessage
	}
}

disconnectServer
connectServer

do
 {
     Show-Menu
     $selection = Read-Host "Please make a selection :"
     switch ($selection)
     {
         '1' {
            lastVMCreated
         } 
		 '2' {
            lastVMDeleted
         } 
		 '3' {
            vmCreatedInDays
         } 
		 '4' {
            vmDeletedInDays
         } 
		 '5' {
            "Function does not exist yet!" 
         }
     }
     pause
 }
 until ($selection -eq '0')
