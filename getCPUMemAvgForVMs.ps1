<#
Script Name : getCPUMemAvgForVMs.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Usage		: 
This utility helps user to fetch data/information regarding VMs average usage of CPU (in MHz) and Memory(in %) over a given period of time/days.
Utility is menu driven to facilitate users to select the kind of information they need to fetch from the system. 

Known issues: due to a bug in powershell, sometimes selecting less then 10 VMs may return the error in the catch

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
    Write-Host "1: Press '1' For ALL VMs"
    Write-Host "2: Press '2' For Selected VMs"
    Write-Host "3: Press '3' Future Use"
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

function getAvgForAllVMs{
	$numOfDays = Read-Host "Enter number of days you want to go back to get the stats [Enter a value between 1 to 30]:"
	
	try {
		if(($numOfDays -lt 1) -or ($numOfDays -gt 30)) {
			Write-Host -foregroundcolor RED -backgroundcolor WHITE "Invalid Number Of Days Entered!"
			break
		}
		else {
			Clear-Content c:\Temp\stats.csv -Force
			Write-Host "Fetching the details and calculating the average for ALL VMs in the infrastructure, this might take a while..."
			
			Get-VM | Select Name, VMHost, NumCpu, MemoryMB, `
			@{N="Cpu.UsageMhz.Average";E={[Math]::Round((($_ |Get-Stat -Stat cpu.usagemhz.average `
			-Start (Get-Date).AddDays(-$numOfDays)-IntervalMins 5 -MaxSamples (30) |Measure-Object Value -Average).Average),2)}}, `
			@{N="Mem.Usage.Average";E={[Math]::Round((($_ |Get-Stat -Stat mem.usage.average `
			-Start (Get-Date).AddDays(-$numOfDays)-IntervalMins 5 -MaxSamples (30) |Measure-Object Value -Average).Average),2)}} | `
			Export-Csv c:\Temp\stats.csv
			
			$fileValue = [String]::IsNullOrWhiteSpace((Import-Csv c:\Temp\stats.csv))
			#Write-Host "$fileValue = "$fileValue
			if($fileValue -eq "True"){
				Write-Host -foregroundColor Red -backgroundColor White "Result file is empty, please debug the issue..."
			}
			else{
				Write-Host -foreGroundColor Green "Operation completed successfully! Please access [c:\Temp\stats.csv] file to see the results."
			}
		}
	}
	
	catch {
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not find the data, please verify vCenter Server Invetory Objects"
		exit
	}
}

function getAvgForSelectedVMs{
	$numOfDays = Read-Host "Enter number of days you want to go back to get the stats [Enter a value between 1 to 30]:"
	try {
		if(($numOfDays -lt 1) -or ($numOfDays -gt 30))	{
			Write-Host -foregroundcolor RED -backgroundcolor WHITE "Invalid Number Of Days Entered!"
			break
		}
		else {
			Clear-Content c:\Temp\stats.csv -Force
			$vmName = Read-Host "Enter the VM Name or Regex value to be searched : "
			$vmList = Get-VM $vmName
			forEach ($vm in $vmList) {
			Get-VM $vm | Select Name, VMHost, NumCpu, MemoryMB, `
			@{N="Cpu.UsageMhz.Average";E={[Math]::Round((($_ |Get-Stat -Stat cpu.usagemhz.average `
			-Start (Get-Date).AddDays(-$numOfDays)-IntervalMins 5 -MaxSamples (30) |Measure-Object Value -Average).Average),2)}}, `
			@{N="Mem.Usage.Average";E={[Math]::Round((($_ |Get-Stat -Stat mem.usage.average `
			-Start (Get-Date).AddDays(-$numOfDays)-IntervalMins 5 -MaxSamples (30) |Measure-Object Value -Average).Average),2)}} | ` 
			Export-Csv c:\Temp\stats.csv -Append
			}
		
			$fileValue = [String]::IsNullOrWhiteSpace((Import-Csv c:\Temp\stats.csv))
			#Write-Host "$fileValue = "$fileValue
			if($fileValue -eq "True"){
				Write-Host -foregroundColor Red -backgroundColor White "Result file is empty, please debug the issue..."
			}
			else{
				Write-Host -foreGroundColor Green "Operation completed successfully! Please access [c:\Temp\stats.csv] file to see the results."
			}
		}
	}
	catch {
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not find the data, please verify vCenter Server Invetory Objects"
		exit
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
            getAvgForAllVMs
         } 
		 '2' {
            getAvgForSelectedVMs
         } 
		 '3' {
            "Function does not exist yet!" 
         } 
     }
     pause
 }
 until ($selection -eq '0')
