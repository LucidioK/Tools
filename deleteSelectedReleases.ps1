param($releaseDefinitionName = 'pars.Infrastructure.Develop.Release')
if ($null -eq (get-command -Name 'Add-TeamAccount'))
{
    Save-Module -Name Team  -Path C:\temp\PowerShell;
    Install-Module -Name Team ;
    Import-Module Team
}

Add-TeamAccount -Account $global:settings.tfsAccount -PersonalAccessToken $global:settings.tfsAccessToken;
$releaseDefinition = (Get-ReleaseDefinition -ProjectName $global:settings.tfsProject) | Where-Object { $_.name -eq $releaseDefinitionName };
if ($null -eq $releaseDefinition)
{
    throw "Could not find release definition $releaseDefinitionName";
}

$releases = Get-Release -definitionId $releaseDefinition.id -ProjectName $global:settings.tfsProject;

$forSelection = @();
$releases | ForEach-Object { $forSelection += "$($_.id);$($_.name);$($_.status)"; };
$toDeletes = $forSelection | Out-GridView -OutputMode Multiple;

foreach ($toDelete in $toDeletes)
{
    $id = $toDelete.Split(';')[0];
    Write-Host "Deleting $toDelete" -ForegroundColor Green;
    Remove-Release -ProjectName $global:settings.tfsProject -Id $id -Force;
}

