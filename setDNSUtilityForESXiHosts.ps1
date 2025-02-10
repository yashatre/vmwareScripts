<#
Script Name : setDNSUtilityForESXiHosts.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@digitalsense.com.au]
Usage		: 
This utility helps user to verify and set DNS servers on all or selected ESXi hosts in a vCenter Server. 

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
    Write-Host "1: Press '1' Get DNS Server set from all the ESXi Hosts"
    Write-Host "2: Press '2' Set DNS Servers for selected ESXi Host"
    Write-Host "3: Press '3' Set DNS Servers for all ESXi Hosts in a Cluster"
	Write-Host "4: Press '4' Set DNS Servers for All ESXi Host"
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

function showDNS {
	try{
		Get-VMHost | Select Name, @{N='DNS Server(s)';E={$_.Extensiondata.Config.Network.DnsConfig.Address -join ' , '}}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not add DNS to all the server in the cluster"
		throw $_.Exception.Message
		exit
	}
}

function setDNSonCluster {
	try{
		$clusterName = Read-Host "Enter Cluster Name"
		[string[]] $dnsServers = @()
		$dnsServers = Read-Host "Enter DNS Servers as comma seperated values in single quotes, Ex. `n'192.168.1.2','192.168.1.3' `nPlease enter values here: "
		$dnsServers = $dnsServers.Split(',')
		Get-Cluster -Name $clusterName | Get-VMHost | %{
			$esxcli = Get-EsxCli -VMHost $_ -V2
			$esxcli.network.ip.dns.server.list.Invoke() | select -ExpandProperty DNSServers | %{
				$sOldDns = @{
					server = $_
				}
				$esxcli.network.ip.dns.server.remove.Invoke($sOldDns)
			}
			$dnsServers | %{
				$sDns = @{
					server = $_
				}
				$esxcli.network.ip.dns.server.add.Invoke($sDns)
			}
		}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not add DNS to all the server in the cluster"
		throw $_.Exception.Message
		exit
	}
}

function setDNSonESXi {
	try{
		$esxiName = Read-Host "Enter ESXi Name "
		[string[]] $dnsServers = @()
		$dnsServers = Read-Host "Enter DNS Servers as comma seperated values in single quotes, Ex. `n'192.168.1.2','192.168.1.3' `nPlease enter values here: "
		$dnsServers = $dnsServers.Split(',')
		Get-VMHost -Name $esxiName | %{
			$esxcli = Get-EsxCli -VMHost $_ -V2
			$esxcli.network.ip.dns.server.list.Invoke() | select -ExpandProperty DNSServers | %{
				$sOldDns = @{
					server = $_
				}
				$esxcli.network.ip.dns.server.remove.Invoke($sOldDns)
			}
			$dnsServers | %{
				$sDns = @{
					server = $_
				}
				$esxcli.network.ip.dns.server.add.Invoke($sDns)
			}
		}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not add DNS to the server"
		throw $_.Exception.Message
		exit
	}
}

function setDNSonAllESXi {
	try{
		[string[]] $dnsServers = @()
		$dnsServers = Read-Host "Enter DNS Servers as comma seperated values in single quotes, Ex. `n'192.168.1.2','192.168.1.3' `nPlease enter values here: "
		$dnsServers = $dnsServers.Split(',')
		Get-VMHost | %{

			$esxcli = Get-EsxCli -VMHost $_ -V2
			$esxcli.network.ip.dns.server.list.Invoke() | select -ExpandProperty DNSServers | %{
				$sOldDns = @{
					server = $_
				}
				$esxcli.network.ip.dns.server.remove.Invoke($sOldDns)
			}
			$dnsServers | %{
				$sDns = @{
					server = $_
				}
			$esxcli.network.ip.dns.server.add.Invoke($sDns)
			}
		}
	}
	catch{
		Write-Host -foregroundColor Red -backgroundColor Black "`nCould not add DNS to the server"
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
				showDNS
			 } 
			 '2' {
				setDNSonESXi
				
			 } 
			 '3' {
				setDNSonCluster
			 } 
			 '4' {
				setDNSonAllESXi
			 } 
		 }
		 pause
	 }
	 until ($selection -eq '0')
	 
}

main
