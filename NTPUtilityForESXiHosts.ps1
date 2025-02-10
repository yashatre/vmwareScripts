<#
Script Name : NTPUtilityForESXiHosts.ps1
Version		: 1.0 
Developer	: Yashodhan Atre
Usage		: 
This utility helps user to verify, set and remove NTP servers set on all the ESXi hosts in a vCenter Server Datacenter . 

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
    Write-Host "1: Press '1' Get NTP Server set form all the ESXi Hosts"
    Write-Host "2: Press '2' Set NTP Servers for all ESXi Hosts"
    Write-Host "3: Press '3' Delete NTP Servers form all ESXi Hosts"
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

function getNTPInfo {
	try{
		Get-Datacenter | Get-VMHost -PipelineVariable esx |
		ForEach-Object -Process {
			$currentNtp = Get-VMHostNtpServer -VMHost $esx
			Write-Host "NTP server for $esx : "$currentNtp
		}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not find ESXi servers."
		throw $_.Exception.Message
		exit
	}
}

function setNTPConfig {
	try{
		$targetNTP = Read-Host "Enter comma seperated values in single quotes, Ex. `n'0.au.pool.ntp.org','1.au.pool.ntp.org' `nPlease enter values here: "
		Get-Datacenter | Get-VMHost -PipelineVariable esx |
		ForEach-Object -Process {
			$currentNtp = Get-VMHostNtpServer -VMHost $esx
			if (Compare-Object -ReferenceObject $targetNTP -DifferenceObject $currentNtp){
				Write-Host -f Red "Host(s) does not have the given configuration for NTP"
				Remove-VMHostNtpServer -VMHost $esx -NtpServer $currentNtp -Confirm:$false -WhatIf
				Add-VMHostNtpServer -VMHost $esx -NtpServer $targetNTP -Confirm:$false -WhatIf
			}
			else{
				Write-Host -f green "NTP Servers are configured correctly on '$esx', NO change commited!"
			}
		}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not change NTP configuration."
		throw $_.Exception.Message
		exit
	}
}

function removeNTPConfig {
	try{
		Get-Datacenter | Get-VMHost -PipelineVariable esx |
		ForEach-Object -Process {
				Write-Host -f Red "Removing NTP Servers from all the hosts, this might take a while..."
				Remove-VMHostNtpServer -VMHost $esx -NtpServer $currentNtp -Confirm:$false -WhatIf
		}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not change NTP configuration."
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
				getNTPInfo
			 } 
			 '2' {
				setNTPConfig
			 } 
			 '3' {
				removeNTPConfig 
			 } 
		 }
		 pause
	 }
	 until ($selection -eq '0')
	 
}

main
