$resourceNameAndResourceGroupVariablePairs = @"
[
    {'resourceNameVariable':'applicationInsightsName'                    , 'resourceGroupNameVariable':'resourceGroupForApplicationInsights'                 },
    {'resourceNameVariable':'cosmosDbName'                               , 'resourceGroupNameVariable':'resourceGroupForCosmosDB'                            },
    {'resourceNameVariable':'keyVaultName'                               , 'resourceGroupNameVariable':'resourceGroupForKeyVault'                            },
    {'resourceNameVariable':'keyVaultNameV1'                             , 'resourceGroupNameVariable':'resourceGroupForKeyVaultV1'                          },
    {'resourceNameVariable':'serviceBusName'                             , 'resourceGroupNameVariable':'resourceGroupForServiceBus'                          },
    {'resourceNameVariable':'storageAccountForApplicationInsights'       , 'resourceGroupNameVariable':'resourceGroupForStorageAccountForApplicationInsights'},
    {'resourceNameVariable':'storageAccountName'                         , 'resourceGroupNameVariable':'resourceGroupForStorageAccountForKeyVault'           },
    {'resourceNameVariable':'storageAccountNameForKeyVaultDiagnosticsLog', 'resourceGroupNameVariable':'resourceGroupForStorageAccountForApplicationInsights'} 
]
"@ | ConvertFrom-Json;

Write-Host 'Retrieving all Egift*-Variants-* variable groups.' -ForegroundColor Green;
$allVariableGroups = (LK-Tool-GetVariableGroups -variableGroupFilter 'Egift*Variants*') | ConvertFrom-Json;
$groupNames = (Get-Member -InputObject $allVariableGroups -MemberType NoteProperty).Name;
$allVariables = @{};
$valueToGroupAndVariableMap = @{};
foreach ($groupName in $groupNames)
{
    $allVariables[$groupName] = @{};
    $group = $allVariableGroups."$groupName";
    $groupMemberNames = (Get-Member -InputObject $group -MemberType NoteProperty).Name;
    foreach ($groupMemberName in $groupMemberNames)
    {
        $value = $group."$groupMemberName";
        $allVariables[$groupName][$groupMemberName] = $value;
        $valueToGroupAndVariableMap[$value] = "$groupName,$groupMemberName";
    }
}



#$allStorageAccounts = Get-AzureRmStorageAccount;
#$allServiceBuses = Get-AzureRmServiceBusNamespace;
#$allApplicationInsights = Get-AzureRmApplicationInsights;
#$allKeyVaults = Get-AzureRmKeyVault;
#$allCosmosDb = (Get-AzureRmResource) | where { $_.Kind -match 'GlobalDocumentDB' };
Write-Host 'Retrieving all s00293 resources.' -ForegroundColor Green;
$rrgs = get-azurermresource | select ResourceGroupName, Name | where { $valueToGroupAndVariableMap.ContainsKey($_.Name) };

foreach ($rrg in $rrgs)
{
    write-host "Inspecting $($rrg.Name), resource group $($rrg.ResourceGroupName)... " -NoNewline -ForegroundColor Green;
    if ($valueToGroupAndVariableMap.ContainsKey($rrg.Name))
    {
        write-host "It is a resource deployed by infrastructure pipeline, let's see if its resource group is correct in the variables..." -ForegroundColor Green;
        $variableGroupName = $valueToGroupAndVariableMap[$rrg.Name].Split(',')[0];
        $variableName      = $valueToGroupAndVariableMap[$rrg.Name].Split(',')[1];
        $resourceNameAndResourceGroupVariablePair = $resourceNameAndResourceGroupVariablePairs | Where { $_.resourceNameVariable -match $variableName } | select -First 1;
        if ($resourceNameAndResourceGroupVariablePair -ne $null)
        {
            $resourceGroupFromVariable = $allVariables[$variableGroupName][$resourceNameAndResourceGroupVariablePair.resourceGroupNameVariable];
            if ($resourceGroupFromVariable -notmatch $rrg.ResourceGroupName)
            {
                write-host "LK-Tool-SetVariable -variableGroupName '$($variableGroupName)' -variableName '$($resourceNameAndResourceGroupVariablePair.resourceGroupNameVariable)' -variableValue '$($rrg.ResourceGroupName)'" -ForegroundColor Yellow;
                #LK-Tool-SetVariable -variableGroupName $variableGroupName -variableName $resourceNameAndResourceGroupVariablePair.resourceGroupNameVariable -variableValue $rrg.ResourceGroupName;
            }
        }
    }
    else
    {
        write-host "Not in the list of resources deployed by infrastructure pipeline." -ForegroundColor Green;
    }
}
