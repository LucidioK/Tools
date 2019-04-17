################################################################################
#
# The DynamoDBReader class provides methods to read documents from a DynamoDB table.
#
# Usage examples:
#
# # Create a reader for the Title table:
# $titleReader = [DynamoDBReader]::new('Title', 'LK-aws-prd')
#
# # To see the table's metadata, including indexes:
#  $titleReader.DynamoTable | ConvertTo-Json -Depth 16
#  {
#      "TableName":  "Title",
#      "Keys":  {
#                   "Id":  {
#                              "Type":  1,
#                              "IsHash":  true
#                          }
#               },
#      "GlobalSecondaryIndexes":  {
# . . .
#
# # read 1000 documents from the Title table:
# $d01 = $titleReader.Scan()
#
# # this will read 10 documents from the Title table:
# $d02 = $titleReader.Scan(10)
#
# # read 1000 documents, only fields Id and TitleName.
# $d03 = $titleReader.Scan(@('Id', 'TitleName'))
#
# # read 1000 documents where TitleName is 'My Game'.
# $d04 = $titleReader.Scan(@{ TitleName = 'My Game' })
#
# # read 10 documents where TitleName is 'My Game'.
# $d05 = $titleReader.Scan(@{ TitleName = 'My Game' }, 10)
#.
# # read 1000 documents where TitleName is 'My Game', only fields Id and TitleName
# $d06 = $titleReader.Scan(@{ TitleName = 'My Game' }, @('Id', 'TitleName'))
#
# # Query can only be executed on indexes:
# $d = $titleReader.Query(@{ TitleName = 'My Game'})
# Only DeveloperId,Id,PublisherId) are allowed for query.
#
# # read all documents where DeveloperId = 6149633163706506451, using an index that has DeveloperId.
# $d08 = $titleReader.Query(@{ DeveloperId = 6149633163706506451 })
#
# # read 2 documents where DeveloperId = 6149633163706506451, using an index that has DeveloperId.
# $d09 = $titleReader.Query(@{ DeveloperId = 6149633163706506451 }, 2)
#
# # read all documents where DeveloperId = 6149633163706506451, using an index that has DeveloperId, only fields Id and TitleName.
# $d10 = $titleReader.Query(@{ DeveloperId = 6149633163706506451 }, @('Id', 'TitleName'))
#
# # read 2 documents where DeveloperId = 6149633163706506451, using an index that has DeveloperId, only fields Id and TitleName.
# $d11 = $titleReader.Query(@{ DeveloperId = 6149633163706506451 }, 2, @('Id', 'TitleName'))
#
# # read title with id 41469.
# $d12 = $titleReader.GetItem(41469)
################################################################################

class DynamoDBReader
{

    [Amazon.DynamoDBv2.DocumentModel.Table]$DynamoTable

    DynamoDBReader([string]$tableName, [string]$profileName)
    {

        $tableDefinition  = Get-DDBTable -TableName $tableName -ProfileName $profileName;
        $regionSystemName = $tableDefinition.TableArn.Split(':')[3];
        $regionEndpoint   = [Amazon.RegionEndpoint]::GetBySystemName($regionSystemName);
        $credential       = get-awscredential -ProfileName $profileName;
        $dbClient         = [Amazon.DynamoDBv2.AmazonDynamoDBClient]::new($credential, $regionEndpoint);
        $this.DynamoTable = [Amazon.DynamoDBv2.DocumentModel.Table]::LoadTable($dbClient, $tableName);
    }

    [PSCustomObject[]] Scan()
    {
        return $this.Scan($null, 1000, $null);
    }

    [PSCustomObject[]] Scan([int]$MaxCount = 1000)
    {
        return $this.Scan($null, $MaxCount, $null);
    }

    [PSCustomObject[]] Scan([string[]]$AttributesToGet)
    {
        return $this.Scan($null, 1000, $AttributesToGet);
    }

    [PSCustomObject[]] Scan([int]$MaxCount = 1000, [string[]]$AttributesToGet = $null)
    {
        return $this.Scan($null, $MaxCount, $AttributesToGet);
    }

    [PSCustomObject[]] Scan([Hashtable]$filterValues, [int]$MaxCount, [string[]]$AttributesToGet)
    {
        $records = @();
        write-host "Running scan (slowest)..." -ForegroundColor Green;
        $config = $this.getConfig($filterValues, $attributesToGet, $maxCount, $true);
        $pleaseRepeat = $true;
        while ($pleaseRepeat)
        {
            $result = $this.DynamoTable.Scan($config);
            write-host "Read $($result.Count) documents, total $($records.Count) until now..." -ForegroundColor Green;
            $records += $result.GetNextSet();
            if ($result.Count -eq 0 -or $result.NextKey -eq $null -or $result.PaginationToken -eq $null -or $records.Count -ge $maxCount)
            {
                $pleaseRepeat = $false;
            }
            else
            {
                $config.PaginationToken = $result.PaginationToken;
            }
        }
        write-host "End of scan, read $($records.Count) documents..." -ForegroundColor Green;
        $records += $null;
        return ($this.awsDocListToCustomObjList($records, $MaxCount));
    }

    [PSCustomObject[]] Query([Hashtable]$filterValues)
    {
        return $this.Query($filterValues, 1000, $null);
    }

    [PSCustomObject[]] Query([Hashtable]$filterValues, [int]$MaxCount)
    {
        return $this.Query($filterValues, $MaxCount, $null);
    }

    [PSCustomObject[]] Query([Hashtable]$filterValues, [string[]]$AttributesToGet)
    {
        return $this.Query($filterValues, 1000, $AttributesToGet);
    }

    [PSCustomObject[]] Query([Hashtable]$filterValues, [int]$MaxCount, [string[]]$AttributesToGet)
    {
        $config   = $this.getConfig($filterValues, $attributesToGet, $maxCount, $false);
        $result   = $this.DynamoTable.Query($config);
        $records  = $result.GetNextSet();
        $records += $null;
        return ($this.awsDocListToCustomObjList($records, $MaxCount));
    }

    [PSCustomObject] GetItem([Object]$key)
    {
        $document = $this.DynamoTable.GetItem($key);
        return ($this.awsDocToCustomObj($document));
    }

    hidden [Object] guaranteeList([Object]$o)
    {
        if ($o.GetType().FullName -ne 'System.Object[]')
        {
            return @($o);
        }
        return $o;
    }

    hidden  [Object] toNumberIfNeeded([string]$value, [string]$type) 
    {
        $result = $value;
        if ($type.StartsWith('N') -and $value -ne $null -and $value.GetType().Name -eq 'String')
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

    hidden  [Bool] shouldUseQuery([Hashtable]$filterValues) 
    {
        if ($filterValues -ne $null)
        {
            $hashKeyNames = @();
            foreach ($key in ($this.DynamoTable.Keys.Keys | select))
            {
                if ($this.DynamoTable.Keys[$key].IsHash)
                {
                    $hashKeyNames += $key;
                }
            }
            $allFilterAttributesAreHashKeys = $true;
            foreach ($key in ($filterValues.Keys | select))
            {
                $allFilterAttributesAreHashKeys = $allFilterAttributesAreHashKeys -and $hashKeyNames.Contains($key);
            }
            return $hashKeyNames.Contains
        }
        return $false;
    }

    hidden [Bool] isNotEmpty($l)
    {
        return ($l -ne $null -and $l.Length -gt 0);
    }

    hidden [Amazon.DynamoDBv2.DocumentModel.Expression] getExpression([string]$filterExpression)
    {
        $expression                 = [Amazon.DynamoDBv2.DocumentModel.Expression]::new();
        $expression.ExpressionStatement = $filterExpression;
        $fe = $filterExpression;
        while ($fe -match "([A-Za-z0-9_\.]+) *(=|<|<=|>=|>) *('.+?'|[0-9]+)")
        {
            $subExpr   = $Matches[0];
            $fieldName = $Matches[1];
            $operator  = $Matches[2];
            $value     = $Matches[3];
            $valueExp  = [Amazon.DynamoDBv2.DocumentModel.Primitive]::new($value.Replace("'",""), !($value.StartsWith("'")));
            $valueRep  = ":$fieldName";
            $expression.ExpressionAttributeValues[$valueRep] = $valueExp;
            $filterExpression = $filterExpression.Replace($value, $valueRep);
            $fe        = $fe.Replace($subExpr, "");
        }
        $expression.ExpressionStatement = $filterExpression;
        return $expression;
    }

    hidden [Amazon.DynamoDBv2.DocumentModel.QueryOperationConfig] insertMissingConditionsIfNeeded([Amazon.DynamoDBv2.DocumentModel.QueryOperationConfig]$config)
    {
        $fieldsAlreadyInUse = $this.guaranteeList((($config.Filter.ToConditions()).Keys | select));
        $fieldsAlreadyInUse += $null;
        foreach ($indexName in ($this.DynamoTable.GlobalSecondaryIndexes.Keys | select))
        {
            $fieldNamesInIndex = $this.guaranteeList(($this.DynamoTable.GlobalSecondaryIndexes[$indexName].KeySchema).AttributeName);
            $extraFields       = $this.guaranteeList(($fieldNamesInIndex | where { !($fieldsAlreadyInUse.Contains($_)) }));
            if ($extraFields.Count -eq 1 -and $this.DynamoTable.HashKeys.Contains($extraFields[0]))
            {
                $t = ($this.DynamoTable.Attributes | where { $_.AttributeName -eq $extraFields[0] }).AttributeType;
                $v = if ($t -eq [Amazon.DynamoDBv2.ScalarAttributeType]::N) { 0 } else { "" };
                $config.Filter.AddCondition($extraFields[0], [Amazon.DynamoDBv2.DocumentModel.QueryOperator]::GreaterThan, $v);
                $config.IndexName = $indexName;
                break;
            }
        }
        return $config;
    }


    hidden  [Object] getConfig([Hashtable]$filterValues, [string[]]$attributesToGet, [int]$maxCount, [Bool]$isScanOperation = $true)
    {
        if ($isScanOperation) 
        { 
            $config                   = [Amazon.DynamoDBv2.DocumentModel.ScanOperationConfig]::new();
            $filter                   = [Amazon.DynamoDBv2.DocumentModel.ScanFilter]::new();
            $operator                 = [Amazon.DynamoDBv2.DocumentModel.ScanOperator]::Equal;
        } 
        else 
        { 
            $config                   = [Amazon.DynamoDBv2.DocumentModel.QueryOperationConfig]::new();
            $filter                   = [Amazon.DynamoDBv2.DocumentModel.QueryFilter]::new();
            $operator                 = [Amazon.DynamoDBv2.DocumentModel.QueryOperator]::Equal;
        }

        if ($filterValues -ne $null) 
        {
            if ($isScanOperation) 
            {
                foreach ($filterAttributeName in ($filterValues.Keys | select))
                {
                    $filterAttributeValue = $filterValues[$filterAttributeName];
                    $filter.AddCondition($filterAttributeName, $operator, $filterAttributeValue);
                } 
                $config.ConsistentRead    = $true;
                $config.Filter            = $filter;
            }
            else
            {
                foreach ($filterAttributeName in ($filterValues.Keys | select))
                {
                    $attribute = $this.DynamoTable.Attributes | where { $_.AttributeName -eq $filterAttributeName };
                    if ($attribute -eq $null)
                    {
                        throw "Only $([string]::Join(',', ($this.DynamoTable.Attributes).AttributeName))) are allowed for query.";
                    }
                    $filterAttributeValue = $this.toNumberIfNeeded($filterValues[$filterAttributeName], $attribute.AttributeType);
                    $filter.AddCondition($filterAttributeName, $operator, $filterAttributeValue);
                } 
                $config.Filter            = $filter;
                $config = $this.insertMissingConditionsIfNeeded($config);
            }

        }

        $config.Limit                = $maxCount;


        if ($attributesToGet -ne $null)
        {
            $config.AttributesToGet  = $attributesToGet;
            $config.Select           = [Amazon.DynamoDBv2.DocumentModel.SelectValues]::SpecificAttributes;
        }
        return $config;
    }


    hidden  [PSCustomObject] awsDocToCustomObj([Amazon.DynamoDBv2.DocumentModel.Document]$d)
    {
        $convertfromjsonerr = $null;
        $c = $null;

        # Depending on the setting on ErrorActionPreference and whether this is being executed on
        # PowerShell or PowerShell ISE, if there is an error, the exception might be captured by the 
        # ErrorVariable mechanism or the try..catch mechanism.
        # DynamoDB sometimes creates documents with the same key twice, which causes ConvertFrom-Json to
        # fail.
        try
        {
            $c = ($d.ToJson() | ConvertFrom-Json -ErrorAction SilentlyContinue -ErrorVariable 'convertfromjsonerr');
        }
        catch
        {
            $convertfromjsonerr = $_.Exception.Message;
        }

        if ($convertfromjsonerr -ne $null)
        {
            # If convertfromjsonerr was populated by the ErrorVariable mechanism, it will be an ArrayList.
            if ($convertfromjsonerr.GetType().Name -eq 'ArrayList')
            {
                [string]$errorMessage = $convertfromjsonerr[0];
            }
            else
            {
                [string]$errorMessage = $convertfromjsonerr;
            }

            if ($errorMessage.StartsWith('Cannot convert the JSON string because a dictionary that was converted from the string contains the duplicated keys '))
            {
                $errorMessage  -match ".* and '(.+)'.*";
                $propertyToRemove = $Matches[1];
                $d.Remove($propertyToRemove);
                return ($this.awsDocToCustomObj($d));
            }
            else
            {
                throw $errorMessage;
            }
        }
        return $c;
    }

    hidden  [System.Collections.ArrayList] awsDocListToCustomObjList([Amazon.DynamoDBv2.DocumentModel.Document[]]$docs, [int]$MaxCount)
    {
        [System.Collections.ArrayList]$resultDocs = [System.Collections.ArrayList]::new();
        $i = 0;
        $c = $docs.Count;
        foreach ($tableDoc in $docs)
        {
            if ($tableDoc -ne $null)
            {
                if ($i -gt 1000 -and ($i % 1000) -eq 0)
                {
                    Write-Host "$i / $c" -ForegroundColor Green;
                }
                $resultDocs  += ($this.awsDocToCustomObj($tableDoc));
            }
            if ($resultDocs.Count -ge $MaxCount)
            {
                break;
            }
            $i++;
        }

        return $resultDocs;
    }
}


