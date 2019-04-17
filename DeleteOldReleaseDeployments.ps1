param([string]$resourceGroupName,[int]$daysKeepNewerThan = 65000, [int]$numberOfOldestDeploymentsToDeleteRegardless = 0, [bool]$deleteAllFailedDeployments = $false)

function olderThan($deployment, [int]$days)
{
    $now = Get-Date;
    $daysElapsed = ($now - $deployment.TimeStamp).Days;
    return ($daysElapsed -gt $days)
}


$deployments = get-azurermresourcegroupdeployment -ResourceGroupName $resourceGroupName  | Sort-Object -Descending -Property Timestamp;
$toDelete = @();

if ($deleteAllFailedDeployments)
{
    $toDelete = ($deployments).Where({ $_.ProvisioningState -eq 'Failed' });
}
else
{
    $positionToStartDeleting = 0;
    $limit = $deployments.Count - $numberOfOldestDeploymentsToDeleteRegardless;
    for ($positionToStartDeleting = 0; 
            $positionToStartDeleting -lt $limit -and !(olderThan $deployments[$positionToStartDeleting] $daysKeepNewerThan) -and $deployments[$positionToStartDeleting].ProvisioningState -eq 'Succeeded'; $positionToStartDeleting++){}
    $positionToStartDeleting += 5;
    for ($i = $positionToStartDeleting; $i -lt $deployments.Count; $i++)
    {
        $toDelete += $deployments[$i];
    }
}

foreach ($deployment in $toDelete)
{
    Write-Host "Removing $($deployment.DeploymentName) from $($deployment.TimeStamp)" -ForegroundColor Green;

    Start-Job { Remove-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deployment.DeploymentName; }  
}
