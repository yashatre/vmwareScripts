Get-VM | Sort-Object -Property Name |

Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") |

Select -Property Name,

    @{N="Configured OS";E={$_.Config.GuestFullName}}, 

    @{N="Running OS";E={$_.Guest.GuestFullName}} |

Export-Csv report.csv -NoTypeInformation -UseCulture