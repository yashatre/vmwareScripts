<#
Script Name : checkAndInstallVMwareModules.ps1
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
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script! Please re-run this script as an Administrator."
    Exit
}

# Define the necessary VMware and NSX modules
$requiredModules = @(
    "VMware.PowerCLI", 
    "VMware.VimAutomation.Core", 
    "VMware.VimAutomation.Common",
    "VMware.VimAutomation.Nsx", 
    "VMware.VimAutomation.Nsxt"
)

# Function to check and install required modules
function Check-And-Install-Modules {
    param (
        [string[]]$modules
    )
    foreach ($module in $modules) {
        Write-Progress -Activity "Checking Module" -Status "Checking if $module is installed"
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Module $module is not installed. Attempting to install..."
            Write-Progress -Activity "Installing Module" -Status "Installing $module"
            try {
                Install-Module -Name $module -Scope AllUsers -Force -ErrorAction Stop
                Write-Host "Module $module installed successfully."
            } catch {
                Write-Host "Failed to install $module. Please check the error message and ensure you have internet connectivity."
                return $false
            }
        } else {
            Write-Host "Module $module is already installed."
        }
    }
    return $true
}

# Function to prompt for vCenter connection
function Connect-To-vCenter {
    $vCenterServer = Read-Host "Enter the vCenter Server to connect to"
    $credential = Get-Credential -Message "Enter credentials for $vCenterServer"
    Write-Progress -Activity "Connecting to vCenter" -Status "Connecting to $vCenterServer"
    try {
        Connect-VIServer -Server $vCenterServer -Credential $credential -ErrorAction Stop
        Write-Host "Connected to $vCenterServer successfully."
    } catch {
        Write-Host "Failed to connect to $vCenterServer. Please check the credentials and network connectivity."
    }
}

# Main script execution
Write-Host "Checking and installing necessary VMware and NSX modules..."
if (Check-And-Install-Modules -modules $requiredModules) {
    $connect = Read-Host "Do you want to connect to a vCenter Server? (y/n)"
    if ($connect -eq "y") {
        Connect-To-vCenter
    } else {
        Write-Host "You chose not to connect to a vCenter Server."
    }
} else {
    Write-Host "Some modules could not be installed. Please check the error messages and try running the script as an administrator."
}

Write-Host "Script execution completed."
