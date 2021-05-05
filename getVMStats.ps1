<#
###############################################################################
# Script: getVMStats.ps1                                                      #
# ------------                                                                #
# Developer: Yashodhan Atre                                                   #  
# ------------                                                                #
# Discription:                                                                #
# This script will give you a list of each of your vms,                       #
# it will tell you how many cpu’s, the amount of memory, average cpu usage    # 
# for x amount of days and the average memory usage for x amount of days      #
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


Get-VM | Where {$_.PowerState -eq "PoweredOn"} | Select Name, Host, NumCpu, MemoryMB, @{N="Cpu.UsageMhz.Average";E={[Math]::Round((($_ |Get-Stat -Stat cpu.usagemhz.average -Start (Get-Date).AddHours(-24)-IntervalMins 5 -MaxSamples (12) |Measure-Object Value -Average).Average),2)}}, @{N="Mem.Usage.Average";E={[Math]::Round((($_ |Get-Stat -Stat mem.usage.average -Start (Get-Date).AddHours(-24)-IntervalMins 5 -MaxSamples (12) |Measure-Object Value -Average).Average),2)}} ` | Export-Csv <FilePath>