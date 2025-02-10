<#
Script Name : uninstallVMwareModules.ps1
Version		: 1.0 
Developer	: Yashodhan Atre [yash.atre@team.aussiebroadband.com.au]
Usage		: Check for VMware PowerCLI packages and install
Scope		: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
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
# Ensure the script runs with administrative privileges
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script! Please re-run this script as an Administrator."
    Exit
}

# Import the VMware.PowerCLI module to ensure cmdlets are available
Import-Module VMware.PowerCLI

# List all installed VMware modules
$vmwareModules = Get-InstalledModule | Where-Object { $_.Name -like 'VMware*' }

# Uninstall each VMware module
foreach ($module in $vmwareModules) {
    Write-Host "Uninstalling module: $($module.Name)"
    Uninstall-Module -Name $module.Name -Force -AllVersions
}

Write-Host "All VMware modules have been uninstalled successfully."
