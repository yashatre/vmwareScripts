# File used to store the encrypted string
$SecretFile = "data.conf"

$SecureString = ConvertTo-SecureString -String (Get-Content $SecretFile)
$Pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
$SecretContent = [Runtime.InteropServices.Marshal]::PtrToStringAuto($Pointer)

Write-output $SecretContent