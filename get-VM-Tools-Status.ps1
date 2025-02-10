Get-VM | Sort-Object -Property Name | Select -Property Name,

    @{N="Tools Installed";E={$_.Guest.ToolsVersion -ne ""}},

    @{N="Tools Status";E={$_.ExtensionData.Guest.ToolsStatus}},

    @{N="Tools version";E={if($_.Guest.ToolsVersion -ne ""){$_.Guest.ToolsVersion}}} |

Export-Csv VMToolsReport.csv -NoTypeInformation -UseCulture