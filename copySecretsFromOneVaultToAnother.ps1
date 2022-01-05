$v1v2kvt = @{
    'uswkvt0certpars'='uswkvt0certparsv2';
    'uswkvt0devpars' ='uswkvt0devparsv2';
    'uswkvt0testpars'='uswkvt0loadparsv2';
    'uswkvt0loadpars'='uswkvt0tstparsv2';
    'uswkvt1certpars'='uswkvt1certparsv2';
    'uswkvt1devpars' ='uswkvt1devparsv2';
    'uswkvt1loadpars'='uswkvt1loadparsv2';
    'uswkvt1testpars'='uswkvt1tstparsv2'};
$secrets = @('domaineventsbprimaryconnectionstring', 'domaineventsbsecondaryconnectionstring', 'serviceBusConnectionString');

foreach ($v1kvt in $v1v2kvt.Keys)
{
    $v2kvt = $v1v2kvt[$v1kvt];
    foreach ($secret in $secrets)
    {
        Write-Host "Reading $secret from $v2kvt..." -ForegroundColor Green;
        $secretValue = (Get-AzureKeyVaultSecret -VaultName $v2kvt -Name $secret).SecretValue;
        if ($secretValue -ne $null)
        {
            Write-Host "Writing $secret into $v1kvt..."  -ForegroundColor Green;
            if ((Get-AzureKeyVaultSecret -VaultName $v2kvt -Name $secret) -ne $null)
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