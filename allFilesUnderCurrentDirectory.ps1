
$startTime = [System.DateTime]::Now;
&(join-path $PSScriptRoot 'AzureUtils.ps1');

$global:fileFinder.Initialize($PWD, 'F', '*.*');

return $global:fileFinder.Find();

