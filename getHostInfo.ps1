<#
###############################################################################
# Script: getHostInfo.ps1                                            		  #
# ------------                                                                #
# Developer: Yashodhan Atre                                                   #  
# ------------                                                                #
# Discription:                                                                #
# This script will count and present the details of ESX hosts.                #
#                                                                             #
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

Get-VMHost |Sort Name |Get-View |
Select Name,
@{N="Type";E={$_.Hardware.SystemInfo.Vendor+ " " + $_.Hardware.SystemInfo.Model}},
@{N="CPU";E={"PROC:" + $_.Hardware.CpuInfo.NumCpuPackages + " CORES:" + $_.Hardware.CpuInfo.NumCpuCores + " MHZ: " + [math]::round($_.Hardware.CpuInfo.Hz / 1000000, 0)}},
@{N="MEM";E={"" + [math]::round($_.Hardware.MemorySize / 1GB, 0) + " GB"}} | Export-Csv C:\Users\yash.atre\Desktop\Scripts\hostinfo.csv