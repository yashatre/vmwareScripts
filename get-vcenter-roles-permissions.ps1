$reportName = "C:\Users\yash.atre\Desktop\Scripts\Report-VC.xlsx"
Get-VIPermission |

Select-Object @{N='vCenter';E={$_.Uid.Split('@:')[1]}},

  Principal,Role,

   @{n='Entity';E={$_.Entity.Name}},

   @{N='Entity Type';E={$_.EntityId.Split('-')[0]}} |

Export-excel -Path $reportName -WorksheetName Roles


Get-VIRole | Select @{N='vCenter';E={$_.Uid.Split('@:')[1]}},

Name,

   @{N='PrivilegeList';E={[string]::Join([char]10,$_.PrivilegeList)}} |

Export-Excel -Path $reportName -WorksheetName Roles