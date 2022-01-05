
param($releaseDefinitionName = 'pars.Infrastructure.Develop.Release')
if ((get-command -Name 'Add-TeamAccount') -eq $null)
{
    Save-Module -Name Team  -Path C:\temp\PowerShell;
    Install-Module -Name Team ;
    Import-Module Team
}

Add-TeamAccount -Account $global:settings.tfsAccount -PersonalAccessToken $global:settings.tfsAccessToken;
$releaseDefinition = (Get-ReleaseDefinition -ProjectName $global:settings.tfsProject) | where { $_.name -eq $releaseDefinitionName };
if ($releaseDefinition -eq $null)
{
    throw "Could not find release definition $releaseDefinitionName";
}

$releases = Get-Release -definitionId $releaseDefinition.id -ProjectName $global:settings.tfsProject;
$now = get-date;
foreach ($release in $releases)
{
    $d = [DateTime]$release.createdOn;
    $delta = $now - $d;
    Write-Host "Inspecting $($release.name); from $($release.createdOn) ($($delta.TotalDays) days ago); status $($release.status)" -ForegroundColor Green;
    if ($delta.TotalDays -gt 1)
    {
        if ($release.status -eq 'active' -or $release.status -eq 'abandoned')
        {
            Write-Host "Deleting $($release.name)" -ForegroundColor Green;
            Remove-Release -ProjectName $global:settings.tfsProject -Id $release.id -Force;
        }
    }
}
