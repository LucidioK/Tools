

$data = @();
for ($i = 1; $i -le 1000; $i++)
{
    $ix           = $i.ToString('X').PadLeft(6, '0');
    $baseName     = "st$($ix)";
    $appRegName   = "$($baseName)ar";
    $appRegKeyName= "$($baseName)arpk";
    $resGrpName   = "$($baseName)rg";
    $appUri       = "https://$appRegName.azurewebsites.net";
    Write-Host "$appRegName $appRegKeyName $resGrpName" -ForegroundColor Green;
    $newApp       = get-azureadapplication -SearchString $appRegName;
    if ($null -eq $newApp)
    {
        $newApp       = new-azureadapplication -DisplayName $appRegName -IdentifierUris $appUri;
        $newAppKeyPwd = new-azureadapplicationpasswordcredential -ObjectId $newApp.ObjectId  -CustomKeyIdentifier $appRegKeyName -StartDate $startDate -EndDate $endDate;
    }
    $newRG        = get-azresourcegroup -Name $resGrpName -Location 'centralus' -ErrorAction SilentlyContinue;
    if ($null -eq $newRg)
    {
        $newRG        = new-azresourcegroup -Name $resGrpName -Location 'centralus';
    }
    $item = @{ Id = $i; titleId = $t; resourceGroupId = $newRG.ResourceId; applicationRegistrationId = $newApp.ObjectId; applicationRegistrationKey = $newAppKeyPwd.Value; applicationRegistrationKeyExpiration =  $newAppKeyPwd.EndDate };
    Write-Host ($item | ConvertTo-Json -Depth 8 -Compress) -ForegroundColor Green;
    $data += $item;
    $data | ConvertTo-Json -Depth 8 -Compress | out-file "c:\temp\arRg.json"
}