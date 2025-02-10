## VMware vCenter and export path paramters
param(
    [parameter(Mandatory)]
    [String]$VCServer,
    [parameter(Mandatory)]
    [string]$ReportExport
    )
## Function to check for export directory and create directory if does not exist.
function CreateDirectory {
    $dlfolder = $ReportExport
    if (!(Test-Path -path $dlfolder)) {
    Write-Host $dlfolder "not found, creating it."
    New-Item $dlfolder -type directory
    }
    }
    CreateDirectory | Out-Null
## Import Vmware Powershell Module
Import-Module -Name VMware.VimAutomation.Core
## VCenter Connection
connect-VIServer $VCServer -ErrorAction SilentlyContinue -ErrorVariable ErrorProcess;
if($ErrorProcess){
    Write-Warning "Error connecting to vCenter Server $VCServer error message below"
    Write-Warning $Error[0].Exception.Message
    $Error[0].Exception.Message | Out-File $ReportExport\ConnectionError.txt
exit
    }
else
{
## Create Blank Array
$results = @()
## Get Permissions
$RolesPermissions = Get-VIPermission
foreach ($RolesPermission in $RolesPermissions)
{
Write-Host "checking Permmission $($RolesPermission.Principal)" -ForegroundColor Green
## Get Role
$Role = (Get-VIRole -Name $RolesPermission.Role)
## Set type
if ($RolesPermission.IsGroup -eq "True"){
$Object = "Group"
 }
Else{
$Object = "User"
    }
## Results Hash table
$props = @{
Account = $RolesPermission.Principal
Assigment = $RolesPermission.Entity
Role = $RolesPermission.Role
ObjectType = $Object
Propagate = $RolesPermission.Propagate
AssignedPrivilege = $Role.PrivilegeList -join ","
SystemRole = $Role.IsSystem
}
## Add Properties To Results Array
$results += New-Object psobject -Property $props
}
## Export Results To CSV file
$results | Select-Object Account,Assigment,Role,ObjectType,Propagate,SystemRole,AssignedPrivilege | 
Export-Csv $ReportExport\$VCServer-PermissionsExport.csv -NoTypeInformation
}