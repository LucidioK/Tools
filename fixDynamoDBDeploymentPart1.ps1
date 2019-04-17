param(
    [parameter(Mandatory=$true, position=0)][string]$profileName,
    [parameter(Mandatory=$true, position=1)][string]$region,
    [parameter(Mandatory=$true, position=2)][string[]]$tablesToRemove,
    [parameter(Mandatory=$true, position=3)][string]$cloudName,
    [parameter(Mandatory=$false, position=4)][switch]$doNotDeleteTables)

if (!(Test-Path 'Deployment\pf_cloud\dynamodb\dynamodb.template'))
{
    throw 'You must be in the root of a pf-main repository.';
}
$templateInTempPath = (join-path $env:TEMP 'dynamodb.template');
if (Test-Path $templateInTempPath)
{
    throw "$templateInTempPath already exists.";
}

if (!($doNotDeleteTables))
{
    foreach ($tableName in $tablesToRemove)
    {
        $tableName = "$cloudName-$tableName";
        $table = Get-DDBTable -TableName $tableName -ProfileName $profileName -Region $region;
        if ($table -eq $null)
        {
            throw "Table $table not found.";
        }
    }
}

copy 'Deployment\pf_cloud\dynamodb\dynamodb.template' $env:TEMP;
$template = gc 'Deployment\pf_cloud\dynamodb\dynamodb.template' | ConvertFrom-Json;

foreach ($tableName in $tablesToRemove)
{
    $template.Resources.PSObject.Properties.Remove($tableName);
    $tableName = "$cloudName-$tableName";
    if (!($doNotDeleteTables))
    {
        Remove-DDBTable -TableName $tableName -Force -ProfileName $profileName -Region $region;
    }
}

$template | ConvertTo-Json -Depth 32 | Out-File 'Deployment\pf_cloud\dynamodb\dynamodb.template'
git add 'Deployment/pf_cloud/dynamodb/dynamodb.template'
git commit -m "Removing tables $([string]::Join(",", $tablesToRemove)) to fix issues with dynamodb deployment."
git push
Write-Host "`n`n`nNow go to https://pf-jenkins.LK.com/view/all/job/update-cloud-data/ and Build with Parameters." -ForegroundColor Green; 
Write-Host "When the build finishes, run fixDynamoDBDeploymentPart2.ps1." -ForegroundColor Green; 