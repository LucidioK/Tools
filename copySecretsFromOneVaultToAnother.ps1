$v1v2kvt = @{
    'uswkvt0_env_region'='uswkvt0_env_regionv2';
    'uswkvt1_env_region'='uswkvt1_env_regionv2';
};
$secrets = @('someprimaryconnectionstring', 'somesecondaryconnectionstring', 'ANOTHERConnectionString');

foreach ($v1kvt in $v1v2kvt.Keys)
{
    $v2kvt = $v1v2kvt[$v1kvt];
    foreach ($secret in $secrets)
    {
        Write-Host "Reading $secret from $v2kvt..." -ForegroundColor Green;
        $secretValue = (Get-AzureKeyVaultSecret -VaultName $v2kvt -Name $secret).SecretValue;
        if ($null -ne $secretValue)
        {
            Write-Host "Writing $secret into $v1kvt..."  -ForegroundColor Green;
            if ($null -ne (Get-AzureKeyVaultSecret -VaultName $v2kvt -Name $secret))
            {
                Remove-AzureKeyVaultSecret -VaultName $v1kvt -Name $secret -Force;
            }
            Set-AzureKeyVaultSecret -VaultName $v1kvt -Name $secret -SecretValue $secretValue;
        }
        else
        {
            Write-Host "$secret not found in $v2kvt..." -ForegroundColor Yellow;
        }
    }
}
Write-Host "Done." -ForegroundColor Green;