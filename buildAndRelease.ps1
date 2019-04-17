param(
    [ValidateNotNullOrEmpty()][parameter(Mandatory=$false, Position=0)][string]$buildDefinitionName   = 'eGift.Infrastructure.Develop',
    [ValidateNotNullOrEmpty()][parameter(Mandatory=$false, Position=1)][string]$releaseDefinitionName = 'eGift.Infrastructure.Develop.Release',
    [ValidateNotNullOrEmpty()][parameter(Mandatory=$false, Position=2)][string]$artifactAlias         = 'eGift.Infrastructure.Develop',
    [ValidateNotNullOrEmpty()][parameter(Mandatory=$false, Position=3)][string[]]$Environments = ('certeast', 'deveast', 'loadeast', 'testeast')
    #[ValidateNotNullOrEmpty()][parameter(Mandatory=$false, Position=4)][string]$KeyVaultVariableName = 'keyVaultName'
)

$start = get-date;
function getBuild([int]$buildDefinitionId, [int]$buildNumber)
{
    $b = Get-Build -ProjectName $global:settings.tfsProject -BuildNumber $buildNumber -Definitions @($buildDefinitionId);
    if ($b -ne $null)
    {
        lk-ser $b;
    }
    else
    {
        write-host "Build with BuildDefinition $buildDefinitionId BuildNumber $buildNumber not found" -ForegroundColor Yellow;
    }
    return $b;
}

$bd = (get-builddefinition   -ProjectName $global:settings.tfsProject) | where { $_.name -eq $buildDefinitionName };
if ($bd -eq $null) { throw "Build $buildDefinitionName not found"; }

$rd = (Get-ReleaseDefinition -ProjectName $global:settings.tfsProject) | where { $_.name -eq $releaseDefinitionName };
if ($rd -eq $null) { throw "Release $releaseDefinitionName not found"; }

$b = Add-Build -ProjectName $global:settings.tfsProject -BuildDefinitionName $buildDefinitionName;

for ($s = (getBuild $bd.id $b.id); $s.Result -eq $null; $s = (getBuild $bd.id $b.id))
{
    Write-Host "Waiting for build $($b.id), currently with status $($s.Status)" -ForegroundColor Green;
    Start-Sleep -Seconds 3;
}

$afterBuild = get-date;
$buildElapsed = $afterBuild - $start;
Write-Host "$($buildElapsed.TotalSeconds) seconds to build." -ForegroundColor Green;
if ($s.Result -ne 'succeeded' -or $s.Status -ne 'completed')
{
    throw 'Build failed.';
}

$envs = [string]::Join(",", $Environments);
Write-Host "Starting release" -ForegroundColor Green;
LK-Tool-StartReleaseFromLatestBuild -ReleaseDefinitionName $releaseDefinitionName -environmentsToBeExecutedAsManual $envs 

