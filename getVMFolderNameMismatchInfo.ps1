<#
Script Name : getVMfolderNameMismatchInfo.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Usage		: 
This utility helps user to compare the name of the VM to the folder it is stored in, any mismatches will be output. 

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

function getMismatchInfo {
	try {
		# Full path of the file
		$file = 'C:\temp\MismatchInfo.csv'

		#If the file does not exist, create it.
		if (-not(Test-Path -Path $file -PathType Leaf)) {
			try {
				$null = New-Item -ItemType File -Path $file -Force -ErrorAction Stop
				Write-Host "The file [$file] has been created."
			}
			catch {
				throw $_.Exception.Message
				exit
			}
		}
		else {
			Write-Host "Found the $file, moving on next step..."
		}
		Clear-Content $file -Force
		$VMFolder = @()
		Foreach ($VM in (Get-VM |Get-View)){
			$Details = "" |Select-Object VM,Path
			$Folder = ((($VM.Summary.Config.VmPathName).Split(']')[1]).Split('/'))[0].TrimStart(' ')
			$Path = ($VM.Summary.Config.VmPathName).Split('/')[0]
			If ($VM.Name -ne $Folder){
				$Details.VM = $VM.Name
				$Details.Path = $Path
				$VMFolder += $Details
			}
		}
		$VMFolder |Export-Csv -NoTypeInformation $file
		
		$fileValue = [String]::IsNullOrWhiteSpace((Get-Content $file))
		#Write-Host "fileValue = "$fileValue
		if($fileValue -eq "True"){
			Write-Host -foregroundColor Red -backgroundColor White "Result file is empty, please debug the issue..."
		}
		else{
			Write-Host -foreGroundColor Green "Operation completed successfully! Please access [$file] file to see the results."
		}
	}
	catch {
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not find details, verify system logs for details."
		throw $_.Exception.Message
		exit
	}
}


function main{
	disconnectServer
	connectServer
	getMismatchInfo
	disconnectServer
}

main
