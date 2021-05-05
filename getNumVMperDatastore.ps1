<#
###############################################################################
# Script: getNumVMperDatastore.ps1                                            #
# ------------                                                                #
# Developer: Yashodhan Atre                                                   #  
# ------------                                                                #
# Discription:                                                                #
# This script will count and present the number of vms per datastore.         #
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


Get-Datastore | Select Name, @{N="NumVM";E={@($_ | Get-VM).Count}} | Sort Name | Export-Csv <FilePath>