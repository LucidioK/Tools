param(
    [parameter(Mandatory=$true , Position = 0)]
    [object]$ValueToFind,
    [parameter(Mandatory=$true , Position = 1)]
    [string]$ClusterUrl,
    [parameter(Mandatory=$true , Position = 2)]
    [string]$Database,
    [string]$Operator = '==',
    [string]$TableNameIncludePattern = '.*',
    [string]$TableNameExcludePattern = '---X---',
    [string]$ColumnNameIncludePattern = '.*',
    [string]$ColumnNameExcludePattern = '---X---',
    [switch]$QueryEachColumnIndividually  
)

function countifPredicate($value, $fieldName, $operator)
{
    $fieldName = "['$fieldName']"
    $quote = if ($value.GetType().Name -eq 'String') { "'" } else {""};
    if ($ValueToFind.GetType().Name -eq 'Double' -and $Operator -eq '==')
    {
        $predicate = "abs($fieldName - $value) < 0.001";
    }
    else
    {
        $predicate = "$fieldName $Operator $quote$ValueToFind$quote";
    }

    return $predicate;
}

function summarizeField($value, $fieldName, $operator)
{
    $summarizeField = "Count$_ = countif($(countifPredicate $value $fieldName $operator ))";
    return $summarizeField;
}

if ($ValueToFind.GetType().Name -eq 'Guid' -or $ValueToFind.GetType().Name -eq 'DateTime')
{
    $ValueToFind = $ValueToFind.ToString();
}

$query = ".show database $Database schema  | where isnotempty(ColumnName) | distinct TableName,ColumnName,ColumnType | project TableName,ColumnName,ColumnType = replace_string(ColumnType, 'System.',''), Count = 0 | sort by TableName asc,ColumnName asc";
$schema =  GetFromKustoSimplified.ps1 -Query $query -ClusterUrl $ClusterUrl -Database $Database;
$ValueToFindType = $ValueToFind.GetType().Name;
$columns = $schema | 
    Where-Object { 
        $_.TableName  -match    $TableNameIncludePattern  -and
        $_.TableName  -notmatch $TableNameExcludePattern  -and
        $_.ColumnType -eq       $ValueToFindType          -and 
        $_.ColumnName -match    $ColumnNameIncludePattern -and 
        $_.ColumnName -notmatch $ColumnNameExcludePattern 
    };

$tableNames = $columns | ForEach-Object { $_.TableName } | Sort-Object -Unique;
$total = $tableNames.Count;
$counter = 0;
$foundColumns = @();

foreach ($tableName in $tableNames)
{
    $counter++
    Write-Progress -Activity "$counter / $total / $($foundColumns.Count) $tableName " -PercentComplete ($counter*100/$total);
    $columnNames = $columns | Where-Object { $_.TableName -eq $tableName } | ForEach-Object { $_.ColumnName } | Sort-Object -Unique;
    $summarizesList = @();
    if ($QueryEachColumnIndividually)
    {
        $summarizesList = $columnNames | ForEach-Object { (summarizeField $ValueToFind $_ $Operator) }
    }
    else
    {
        $summarizes = $columnNames | ForEach-Object { (summarizeField $ValueToFind $_ $Operator) };
        $summarizes = [string]::Join(',', $summarizes);
        $summarizesList += $summarizes;
    }
    foreach ($summarizes in $summarizesList)
    {
        $query      =  "$tableName | summarize $summarizes";
        $global:SearchValueInKustoAllColumnsAllTablesExecution = "$ClusterUrl $Database [$Query]";
        $result     = GetFromKustoSimplified.ps1 -Query $query -ClusterUrl $ClusterUrl -Database $Database -DoNotCheckIfKustoCliIsInstalled; #GetFromKusto.exe $query $ClusterUrl $Database | ConvertFrom-Json;
        foreach ($columnName in $columnNames)
        {
            $count = $result."Count$columnName"
            if ($count -gt 0)
            {
                $column = $columns | Where-Object { $_.TableName -eq $tableName -and $_.ColumnName -eq $columnName};
                $column.Count = $count;
                $foundColumns += $column;
            }
        }
    }
}

return $foundColumns;
<#
foreach ($column in $columns)
{
    $tableName  = $column.TableName;
    $columnName = $column.ColumnName;
    $counter++
    Write-Progress -Activity "$counter / $total $tableName $columnName " -PercentComplete ($counter*100/$total);
    $query      = "$tableName | where $columnName $Operator $quote$ValueToFind$quote | summarize Count=count()";
    $result     = GetFromKusto.exe $query $ClusterUrl $Database | ConvertFrom-Json;
    if ($result.Count -gt 0)
    {
        Write-Host "$tableName $columnName $($result.Count)" -ForegroundColor Green;
    }
    $column.Count = $result.Count;
};
return $columns;
#>
