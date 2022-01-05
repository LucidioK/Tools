param(
    [parameter(Mandatory=$true,  Position=0)][string]$TemplateFile,
    [parameter(Mandatory=$true,  Position=1)][string]$TemplateParametersFile,
    [parameter(Mandatory=$true,  Position=2)][string]$ResourceGroupName,
    [parameter(Mandatory=$false, Position=3)][string]$ResourceBeingDeployedName = $null,
    [parameter(Mandatory=$false, Position=5)][switch]$KeepDeployment            = $false,
    [parameter(Mandatory=$false, Position=6)][switch]$DeleteExistingResourcesFromResourceGroup = $false
) 

#example:
# .\TestARMTemplate.ps1 -TemplateFile C:\dsv\pars.infrastructure\ARMTemplates\keyVaultTemplate.json -TemplateParametersFile C:\dsv\pars.infrastructure\ARMTemplates\keyVaultTemplate.parameters.json -ResourceGroupName uswnrgp1loadparsv2kv -ResourceBeingDeployedName uswkvt1loadparsv2

function deleteExistingResourcesFromResourceGroup($resourceGroupName)
{
    $jobs = @();
    foreach ($r in (Get-AzureRmResource).Where({ $_.ResourceGroupName -eq $resourceGroupName } ))
    {
        $jobName = "Remove-AzureRmResource $($r.ResourceId)";
        $isItAlreadyRunning = ((get-job -State Running).where({ $_.Name -eq $jobName })) -eq $null;
        if (!($isItAlreadyRunning))
        {
            Write-Host "Removing $($r.Name)" -ForegroundColor Green;
            $job = Remove-AzureRmResource -ResourceId $r.ResourceId -Force -AsJob;
            $job.Name = $jobName;
            $jobs += $job;
        }
        else
        {
            Write-Host "$($r.Name) is already in delete job..." -ForegroundColor Yellow;
        }
    }
    if ($jobs.Count -gt 0)
    {
        Write-Host "Waiting for $($jobs.Count) jobs to finish..." -ForegroundColor Green;
        Wait-Job -Job $jobs -Timeout 30 -Force;
    }
}

$now = $((get-date).ToString('yyyyMMddhhmmss'));
$deploymentName = "deploy$now";
$newTemplateParametersFile = $null;
if ($ResourceBeingDeployedName)
{
    $r = Get-AzureRmResource -ResourceName $ResourceBeingDeployedName -ResourceGroupName $ResourceGroupName;
    if ($r -ne $null)
    {
       $newTemplateParametersFile = [System.IO.Path]::GetTempFileName();
       $newResourceName = "r" + $now +"r";
       (gc $TemplateParametersFile).Replace($ResourceBeingDeployedName, $newResourceName) | Out-File $newTemplateParametersFile;
       $TemplateParametersFile = $newTemplateParametersFile;
    }
}

if ($DeleteExistingResourcesFromResourceGroup)
{
    # Run deleteExistingResourcesFromResourceGroup twice to make sure resources are removed.
    deleteExistingResourcesFromResourceGroup $ResourceGroupName;
    deleteExistingResourcesFromResourceGroup $ResourceGroupName;

}

if ((Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "Resource group $ResourceGroupName does not exist, trying to create it. First, select the location for the resource group.." -ForegroundColor Green;
    $location = (get-azurermlocation).Location | sort | Out-GridView -OutputMode Single;
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction Stop;
}



Write-Host "Starting deployment" -ForegroundColor Green;
$global:lastDeployment = New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParametersFile -Mode Incremental -ErrorAction Stop -Debug -Force;

Write-Host $global:lastDeployment;

if (!($KeepDeployment))
{
    Remove-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $deploymentName;
}

if ($newTemplateParametersFile -ne $null)
{
    del $newTemplateParametersFile;
}

return $global:lastDeployment;
