param(
    [parameter(Mandatory=$false,  Position=0)][string]$KeyVaultNameRegex = 'usw.*kvt.*pars.*',
    [parameter(Mandatory=$false,  Position=2)][string]$SecretName = 'serviceBusConnectionString',
    [ValidateSet('Delete', 'Rename')]
    [parameter(Mandatory=$false,  Position=3)][string]$Operation = 'Rename',
    [parameter(Mandatory=$false,  Position=4)][string]$NewName   = 'zzz-serviceBusConnectionString'
)

Write-Host "Retrieving all key vaults associated subcscription $($azureAccount.Context.Subscription.Name) that satisfies regex $KeyVaultNameRegex" -ForegroundColor Green;
$allKeyVaults = (Get-AzureRmKeyVault) | where { $_.VaultName -match $KeyVaultNameRegex };

foreach ($keyVault in $allKeyVaults)
{
    Write-Host "Trying to retrieve $SecretName from key vault $($keyVault.VaultName)" -ForegroundColor Green;
    $secret = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name $SecretName;
    if ($secret -ne $null)
    {
        Write-Host "Secret found... " -ForegroundColor Green -NoNewline;
        if ($Operation -eq 'Rename')
        {
            Write-Host "Copying to $newName... " -ForegroundColor Green -NoNewline;
            &(Join-Path $PSScriptRoot 'setKeyVaultValue.ps1') -VaultName $secret.VaultName -SecretName $newName -SecretValue $secret.SecretValue; 
        }
        Write-Host "Erasing $SecretName... " -ForegroundColor Green;
        Remove-AzureKeyVaultSecret -VaultName $secret.VaultName -SecretName $SecretName -Force;
    }
    else
    {
        Write-Host "Secret not found." -ForegroundColor Green;
    }
}



