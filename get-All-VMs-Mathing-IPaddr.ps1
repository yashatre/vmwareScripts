$vmIP=”192.168.”

Get-VM * |where-object{$_.Guest.IPAddress -match $vmIP}|select Name, VMHost, PowerState,
	@{N=”IP Address”;E={@($_.guest.IPAddress[0])}} ,
	@{N=”OS”;E={$_.Guest.OSFullName}},
	@{N=”Hostname”;E={$_.Guest.HostName}}|ft