# File used to store the encrypted string
$SecretFile = "data.conf"

$SecretContent = get-content data.conf

# Save the password
ConvertTo-SecureString -String $SecretContent -AsPlainText -Force | ConvertFrom-SecureString | Out-File $SecretFile -Encoding UTF8
  
$SecretFile