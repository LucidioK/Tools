param(
    [parameter(Mandatory=$false, Position=0)][string]$TextPattern = '*'
)

[string]$currentFolder = $PWD;
$currentFolder = $currentFolder.Replace('\', '/');
$sql = "select System.ItemPathDisplay FROM SYSTEMINDEX WHERE System.ITEMURL like 'file:$currentFolder/%' AND Contains('$TextPattern')";
$connector = new-object system.data.oledb.oledbdataadapter -argument $sql, "provider=search.collatordso;extended properties=’application=windows’;";
$dataset = new-object system.data.dataset 
$result=if ($connector.fill($dataset)) { $dataset.tables[0] }
return $result;
