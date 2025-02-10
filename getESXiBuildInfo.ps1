<#
Script Name : getESXiBuildInfo.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Usage		: 
This utility helps user to fetch data/information regarding uptime of each ESXi server present in the vCenter Server environment.

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

function getESXiBuildDetails {
	try {
		Get-View -ViewType HostSystem | select Name,@{N='Host Version & Build Number';E={$_.Config.Product.FullName}} | `
		Sort-Object -Property 'Host Version & Build Number' | format-table
	}
	catch {
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not connect to ESXi host."
		throw $_.Exception.Message
		exit
	}
}

function main{
	disconnectServer
	connectServer
	getESXiBuildDetails
}
main