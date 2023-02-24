<powershell>
param (
    [string]$vault_download_url = "${VAULT_DOWNLOAD_URL}",
    [string]$vault_server = "${VAULT_SERVER}",
    [string]$vault_namespace = "${VAULT_NAMESPACE}",
    [string]$vault_role = "${VAULT_ROLE}",
    [string]$vault_kv = "${VAULT_KV}",
    [string]$ansibleUsername = "${ANSIBLE_USER}",
    [string]$dchost = "${DC_HOST}",
    [string]$ou = "${DC_FULLOUPATH}",
    [string]$domain = "${DC_DOMAIN}",
    [string]$hostname = "${VMNAME}"
    )
# Change the contents of this comment to force instance recreation: 15th of September 2022. 

# FIS Root CA is not in Trusted Root CAs prior to domain join. 
# In order to establish a TLS connection with Vault server, root CA in PEM format is required.

# Get the Vault server certificate:
$webRequest = [Net.WebRequest]::Create("https://$vault_server")
try { $webRequest.GetResponse() } catch {}
$cert = $webRequest.ServicePoint.Certificate

# Extract the root CA from chain:
$chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
$chain.build($cert)
$root_ca = $chain.ChainElements[2].Certificate

# Export the root CA to PEM file:
$bytes = $root_ca.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert) 
set-content -value $bytes -encoding byte -path "$pwd\root_ca.cer"
certutil -encode "$pwd\root_ca.cer" "$pwd\root_ca.pem" | Out-Null

# Set env vars:
$env:VAULT_CACERT = "$pwd\root_ca.pem"
$env:VAULT_ADDR = "https://$vault_server"
$env:VAULT_NAMESPACE = "$vault_namespace"
$Env:PATH += ";C:\temp\hashicorp-vault"

# Install vault.exe 
New-Item -ItemType Directory -Path "C:\temp\hashicorp-vault"
Invoke-WebRequest -Uri "$vault_download_url" -OutFile "C:\temp\vault.zip"
Expand-Archive -Force "C:\temp\vault.zip" -DestinationPath "C:\temp\hashicorp-vault"

# Authenticate and get credentials from Vault server: 
vault login -method=aws header_value="$vault_server" role="$vault_role"
$cred2adminUsername = vault kv get -mount="$vault_kv" -field=username domain-admin
$cred2adminPassword = vault kv get -mount="$vault_kv" -field=password domain-admin
$ansiblePassword = vault kv get -mount="$vault_kv" -field=value harness/ansible-remote-user

# Create local ansible user and join the computer to a domain:
$cred2 = New-Object PSCredential $cred2adminUsername, ($cred2adminPassword | ConvertTo-SecureString -AsPlainText -Force)
New-LocalUser -Name $ansibleUsername -Password ($ansiblePassword | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires -FullName "Ansible User" -Description  "Ansible Remote User"
Add-LocalGroupMember -Group "Administrators" -Member $ansibleUsername
Add-Computer -Server $dchost -DomainName $domain -NewName $hostname -OUPath $ou -Credential $cred2 -Force -PassThru -Verbose -Restart
</powershell>