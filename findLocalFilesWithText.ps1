param(
    [parameter(Mandatory=$true , Position=0)][string]$TextPattern = '*',
    [parameter(Mandatory=$false, Position=1)][string]$FileNamePattern = '*'
)

[string]$currentFolder = $PWD;
$FileNamePattern = $FileNamePattern.Replace('*', '%');

$currentFolder = $currentFolder.Replace('\', '/');
$sql           = "select System.ItemPathDisplay FROM SYSTEMINDEX WHERE System.ITEMURL like 'file:$currentFolder/$FileNamePattern' AND Contains('$TextPattern')";
$provider      = "provider=search.collatordso;extended properties=’application=windows’;";
$connector     = new-object system.data.oledb.oledbdataadapter -argument $sql, $provider;
$dataset       = new-object system.data.dataset 
$result        = if ($connector.fill($dataset)) { $dataset.tables[0] }

if ($null -ne $result)
{
    $filePaths = ($result)."System.ItemPathDisplay";
    foreach ($filePath in $filePaths) {
        Select-String -Path $filePath -Pattern $TextPattern;
    }
}
else
{
    return $null;
}
