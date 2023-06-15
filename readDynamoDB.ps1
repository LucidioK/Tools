param(
    [parameter(Mandatory=$true)] [string]$TableName,
    [parameter(Mandatory=$true)] [string]$ProfileName,
    [parameter(Mandatory=$false)][Hashtable]$FilterValues,
    [parameter(Mandatory=$false)][int]$MaxCount = 1000
)

class retrieveResult
{
    [int]      $Count
    [Object[]] $Records
    retrieveResult() {
        $this.Count   = 0;
        $this.Records = @();
    }

}

function toNumberIfNeeded([string]$value, [string]$type)
{
    $result = $value;
    if ($type -eq 'Numeric' -and $null -ne $value -and $value.GetType().Name -eq 'String')
    {
        $maxInt64 = [System.Int64]::MaxValue.ToString().PadLeft($value.Length);

        if ($value -match '^-?[0-9]{1,19}$' -and ($value.PadLeft($maxInt64.Length)) -le $maxInt64)
        {
            $result  = [System.Int64]::Parse($value);
        }
        elseif ($value -match '^-?[0-9]{20}$')
        {
            $result  = [System.UInt64]::Parse($value);
        }
        elseif ($value -match '^-?[0-9]*\.[0-9]+$|^-?[0-9]+\.[0-9]*$')
        {
            $result  = [System.Double]::Parse($value);
        }
    }
    return $result;
}

#function queryTableDocs([Amazon.DynamoDBv2.DocumentModel.Table]$dynamoDBTable, [Hashtable]$filterValues)
#{
#    $queryFilter              = [Amazon.DynamoDBv2.DocumentModel.QueryFilter]::new();
#    foreach ($filterAttributeName in $filterValues.Keys.GetEnumerator())
#    {
#        $filterAttributeValue = $filterValues[$filterAttributeName];
#        $filterOperator       = [Amazon.DynamoDBv2.DocumentModel.ScanOperator]::Equal;
#        if ($keys.Contains($filterAttributeName))
#        {
#            $filterOperator   = [Amazon.DynamoDBv2.DocumentModel.QueryOperator]::Equal;
#        }
#        $queryFilter.AddCondition($filterAttributeName, $filterOperator, $filterAttributeValue);
#    }    
#    $result = $dynamoDBTable.Query($queryFilter);
#    $retrieveResult = New-Object -TypeName retrieveResult;
#    $retrieveResult.Count = $result.Count;
#    $retrieveResult.Records = $result.GetRemaining();
#    return $retrieveResult;
#}

function scanTableDocs([Amazon.DynamoDBv2.DocumentModel.Table]$dynamoDBTable, [Hashtable]$filterValues, [int]$maxCount)
{
    $scanFilter  = [Amazon.DynamoDBv2.DocumentModel.ScanFilter]::new();
    if ($null -eq $filterValues) 
    {
        $filterValues = @{};
    }
    foreach ($filterAttributeName in $filterValues.Keys.GetEnumerator())
    {
        $filterAttributeValue = $filterValues[$filterAttributeName];
        $scanFilter.AddCondition($filterAttributeName, [Amazon.DynamoDBv2.DocumentModel.ScanOperator]::Equal, $filterAttributeValue);
    } 
    $scanConfig = [Amazon.DynamoDBv2.DocumentModel.ScanOperationConfig]::new();
    $scanConfig.Filter = $scanFilter;
    $scanConfig.Limit = $maxCount;
    $pleaseRepeat = $true;
    $retrieveResult = New-Object -TypeName retrieveResult;
    while ($pleaseRepeat)
    {
        $result = $dynamoDBTable.Scan($scanConfig);
        $retrieveResult.Count   += $result.Count;
        write-host "Read $($result.Count) documents, total $($retrieveResult.Count) until now..." -ForegroundColor Green;
        $retrieveResult.Records += $result.GetNextSet();
        if ($null -eq $result.NextKey -or $null -eq $result.PaginationToken -or $retrieveResult.Count -ge $maxCount)
        {
            $pleaseRepeat = $false;
        }
    }
    write-host "End of scan, read $($retrieveResult.Count) documents..." -ForegroundColor Green;
    return $retrieveResult;
}

#function getTableDocs([Amazon.DynamoDBv2.DocumentModel.Table]$dynamoDBTable, [Hashtable]$filterValues, [string]$hashKeyName)
#{
#    $tableDocs        = $null;
#    if ($filterValues -ne $null -and $filterValues.ContainsKey($hashKeyName))
#    {
#        $tableDocs = queryTableDocs $dynamoDBTable $filterValues;
#    }
#    else
#    {
#        $tableDocs = scanTableDocs $dynamoDBTable $filterValues;
#    }
#    return $tableDocs;
#}

function getTable([string]$tableName, [string]$profileName)
{
    $tableDefinition  = Get-DDBTable -TableName $tableName -ProfileName $profileName;
    $regionSystemName = $tableDefinition.TableArn.Split(':')[3];
    $regionEndpoint   = [Amazon.RegionEndpoint]::GetBySystemName($regionSystemName);
    $credential       = get-awscredential -ProfileName $profileName;
    $dbClient         = [Amazon.DynamoDBv2.AmazonDynamoDBClient]::new($credential, $regionEndpoint);
    $dynamoDBTable    = [Amazon.DynamoDBv2.DocumentModel.Table]::LoadTable($dbClient, $tableName);

    return $dynamoDBTable;
}

$dynamoDBTable    = getTable $TableName $ProfileName;

#$hashKeyName      = if ($dynamoDBTable.HashKeys -ne $null -and $dynamoDBTable.HashKeys.Count -gt 0) { $dynamoDBTable.HashKeys[0] };

$tableDocs        = scanTableDocs $dynamoDBTable $FilterValues $MaxCount;

$resultDocs       = @();
$i = 0;
$c = $tableDocs.Count;
foreach ($tableDoc in $tableDocs.Records)
{
    if ($i -gt 100 -and ($i % 100) -eq 0)
    {
        Write-Host "$i / $c" -ForegroundColor Green;
    }
    $i++;
    $item         = new-object -TypeName PSCustomObject;
    foreach ($key in $tableDoc.Keys)
    {
        $value    = $tableDoc[$key].Value;
        $type     = if ($null -eq $tableDoc[$key].Type) { "Binary" } else { $tableDoc[$key].Type.ToString(); }
        $value    = toNumberIfNeeded $value $type;
        Add-Member -InputObject $item -MemberType NoteProperty -Name $key -Value $value;
    }
    $resultDocs  += $item;
}
$retrieveResult = New-Object -TypeName retrieveResult;
$retrieveResult.Count = $resultDocs.Count;
$retrieveResult.Records = $resultDocs;
return $retrieveResult;
