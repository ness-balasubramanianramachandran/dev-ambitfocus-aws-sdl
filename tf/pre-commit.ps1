Write-Host "Running Terraform formatter..."
terraform fmt -recursive $PSScriptRoot

Write-Host
Write-Host "Generating documentation..."
terraform-docs -c $PSScriptRoot\DEV\.terraform-docs.yaml $PSScriptRoot\DEV
Get-ChildItem -Path $PSScriptRoot\modules\*.terraform-docs.yaml -Recurse | ForEach-Object {terraform-docs -c "$($_.FullName)" "$($_.Directory.FullName)"}