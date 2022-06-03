# $global:incidents = GetFromKustoSimplified.ps1 -ClusterUrl 'https://CLUSTER.windows.net' -Database 'DB' -Query (Get-Content 'C:\Temp\somequery.kql')
# $global:incidents = GetFromKustoSimplified.ps1 -ClusterUrl 'https://CLUSTER.windows.net' -Database 'DB' -Query 'Table | where Column == "value"' -DoNotCheckIfKustoCliIsInstalled
param(
    [parameter(Mandatory=$true , Position = 0)]
    [string]$ClusterUrl,
    [parameter(Mandatory=$true , Position = 1)]
    [string]$Database,
    [parameter(Mandatory=$true , Position = 2)]
    [string]$Query,
    [parameter(Mandatory=$false, Position = 3)]
    [switch]$DoNotCheckIfKustoCliIsInstalled,
    [parameter(Mandatory=$false, Position = 4)]
    [switch]$LeaveCsvFileAndReturnFilePath
)

if ($ClusterUrl -notmatch '^https://[a-z0-9\.]+$')
{
    $ClusterUrl = "https://$ClusterUrl";
}

if ($ClusterUrl -notmatch '^https://[a-zA-Z0-9\.]+\.windows\.net$')
{
    throw "Invalid ClusterUrl.";
}

$connectionString = "$ClusterUrl/$Database;Fed=true";

if (!($DoNotCheckIfKustoCliIsInstalled))
{
    InstallNugetPackageForExecutableIfNeededAndAddToPath.ps1 -ExecutableNameWithExtension 'Kusto.Cli.exe' -NugetPackageName 'Microsoft.Azure.Kusto.Tools' | Out-Null;
}

$Query = ('"' + $Query.Replace("`n"," ").Replace('"',"'") + '"');
$global:LatestGetFromKustoSimplifiedExecution = "$ClusterUrl $Database [$Query]";
$outputPath = [System.IO.Path]::GetTempFileName();
Kusto.Cli.Exe $connectionString -execute:"#save $outputPath"  -execute:$Query | Out-Null;
if ($LeaveCsvFileAndReturnFilePath)
{
    return $outputPath;
}
else 
{
    $result = Get-Content $outputPath | ConvertFrom-Csv;
    Remove-Item $outputPath -ErrorAction SilentlyContinue;
    return $result;
       
}
