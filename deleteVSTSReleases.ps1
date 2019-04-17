param(
	[parameter(Mandatory=$false, Position=0)][string]$ReleaseDefinitionName = "RELDEF",
    [parameter(Mandatory=$false, Position=1)][string]$AccountName = "ACCNAME",
	[parameter(Mandatory=$false, Position=2)][string]$Project     = "VSPROJ",
	[parameter(Mandatory=$false, Position=3)][string]$Token       = "VSTOKEN",
	[parameter(Mandatory=$false, Position=4)][string]$User        = "VSUSER"
)

Write-Host "Reading all $ReleaseDefinitionName for $AccountName's project $Project" -ForegroundColor Green;
$releaseDefinitionId = (Get-VstsReleaseDefinition -AccountName $AccountName -Project $Project -Token $Token -User $User).Where({ $_.Name -eq $ReleaseDefinitionName}).Id;
$allReleases = (Get-VstsRelease -AccountName $AccountName -Project $Project -Token $Token -User $User -DefinitionId $releaseDefinitionId -Top 4096)  | Select id,status,name,createdon | Sort-Object -Descending -Property id;
$selectedReleases = $allReleases | Out-GridView -OutputMode Multiple -Title "Select releases do be deleted:";

Add-TeamAccount -Account $AccountName -PersonalAccessToken $Token;

foreach ($selectedRelease in $selectedReleases)
{
    Write-Host "Deleting release $($selectedRelease.name)" -ForegroundColor Green;
    Remove-Release -Id $selectedRelease.Id -ProjectName $Project -Force;
}

