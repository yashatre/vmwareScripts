Get-VM | Select Name, @{N="Cluster";E={Get-Cluster -VM $_}}, `
@{N="ESX Host";E={Get-VMHost -VM $_}}, `
@{N="Datastore";E={Get-Datastore -VM $_}} | `
Export-Csv -Path .\VM_Cluster_Host_Datastore.csv -NoTypeInformation -UseCulture