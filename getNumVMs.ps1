<#
###############################################################################
# Script: getNumVMs.ps1                                                       #
# ------------                                                                #
# Developer: Yashodhan Atre                                                   #
# ------------                                                                #
# Discription:                                                                #
# Script will display the number of VMs present on each host of the           #
# vCenter Server                                                              #
# ------------                                                                #
# Version: 1.0                                                                #
# ------------                                                                #
# Note:                                                                       #
# Users need to replace the brackets '<>' with a valid value.                 #
# ------------                                                                #
#                                                                             #
#                                                                             #
###############################################################################
#>

Get-VMHost | Select @{N="Cluster";E={Get-Cluster -VMHost $_}}, Name, @{N="NumVM";E={($_ | Get-VM).Count}} | Sort Cluster, Name | Export-Csv -NoTypeInformation <FilePath>