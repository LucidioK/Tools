$v1v2kvt = @{
    's00293kvt0certegift'='s00293kvt0certegiftv2';
    's00293kvt0devegift' ='s00293kvt0devegiftv2';
    's00293kvt0testegift'='s00293kvt0loadegiftv2';
    's00293kvt0loadegift'='s00293kvt0tstegiftv2';
    's00293kvt1certegift'='s00293kvt1certegiftv2';
    's00293kvt1devegift' ='s00293kvt1devegiftv2';
    's00293kvt1loadegift'='s00293kvt1loadegiftv2';
    's00293kvt1testegift'='s00293kvt1tstegiftv2'};
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