param(
    [parameter(Mandatory=$false,  Position=0)][string]$ResourceGroupName                           = "deleteme",
    [parameter(Mandatory=$false,  Position=1)][string]$NameSpace                                   = "svbdeleteme",
    [parameter(Mandatory=$false,  Position=2)][string]$Location                                    = "eastus"  ,
    [parameter(Mandatory=$false,  Position=3)][string]$ServiceBusWithTopicsAndSubscriptionJSONText = '[{"topicName":"anytopic","subscriptionName":"nofilter","filter":"1=1"},{"topicName":"anytopic","subscriptionName":"onecondition","filter":"Label=''data''"},{"topicName":"anytopic","subscriptionName":"multipleconditions","filter":"Label=''data'' or Label=''Data'' or Label=''DATA''"}]'

) 
$lf=$ServiceBusWithTopicsAndSubscriptionJSONText|ConvertFrom-Json;

function CreateResourceGroupIfNeeded([string]$ResourceGroupName, [string]$Location)
{
    $x = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue;
    if ($null -eq $x)
    {
        Write-Host "Creating Resource Group $ResourceGroupName." -ForegroundColor Green;
        $x = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location ;
    }
    return $x;
}

function CreateServiceBusNamespaceIfNeeded([string]$ResourceGroupName, [string]$Location, [string]$NameSpace)
{
    $x = Get-AzureRmServiceBusNamespace -ResourceGroupName $ResourceGroupName -Name $NameSpace -ErrorAction SilentlyContinue;
    if ($null -eq $x)
    {
        Write-Host "Creating Service Bus namespace $NameSpace on Resource Group $ResourceGroupName." -ForegroundColor Green;
        $x = New-AzureRmServiceBusNamespace -ResourceGroupName $ResourceGroupName -Name $NameSpace -Location $Location ;
    }
    return $x;
}

function CreateServiceBusTopicIfNeeded([string]$ResourceGroupName, [string]$NameSpace, [string]$TopicName)
{
    $x = Get-AzureRmServiceBusTopic -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Name $TopicName -ErrorAction SilentlyContinue;
    if ($null -eq $x)
    {
        Write-Host "Creating Service Bus topic $TopicName on namespace $NameSpace on Resource Group $ResourceGroupName." -ForegroundColor Green;
        $x = New-AzureRmServiceBusTopic -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Name $TopicName -EnablePartitioning $false;
    }
    return $x;
}

function CreateServiceBusTopicSubscriptionIfNeeded([string]$ResourceGroupName, [string]$NameSpace, [string]$TopicName, [string]$SubscriptionName)
{
    $x = Get-AzureRmServiceBusSubscription -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Topic $TopicName -Name $SubscriptionName -ErrorAction SilentlyContinue;
    if ($null -eq $x)
    {
        Write-Host "Creating Service Bus topic subscription $SubscriptionName on topic $TopicName on namespace $NameSpace on Resource Group $ResourceGroupName." -ForegroundColor Green;
        $x = New-AzureRmServiceBusSubscription -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Topic $TopicName -Name $SubscriptionName;
    }
    $filterNames = (get-azurermservicebusrule -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Topic $TopicName -Subscription $SubscriptionName).Name  | Where-Object { $_ -ne '$Default' };
    foreach ($filterName in $filterNames)
    {
        Remove-AzureRmServiceBusRule -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Topic $TopicName -Subscription $SubscriptionName -Name $filterName -Force;
    }
    return $x;
}

function removeNonAlphaCharacters([string]$s)
{
    while ($s -match '^[A-Za-z0-9]')
    {
        $s = $s.Replace($Matches[0], "")
        $c = $Matches[0];
        $result += $c;
        $p = $s.IndexOf($c);
        $s = $s.Substring($p + 1);
    }
    return $result;
}

CreateResourceGroupIfNeeded $ResourceGroupName $Location;
CreateServiceBusNamespaceIfNeeded $ResourceGroupName $Location $NameSpace;

$topicNames = $lf | Select-Object -Unique -ExpandProperty 'topicName';
foreach ($topicName in $topicNames)
{
    CreateServiceBusTopicIfNeeded $ResourceGroupName $NameSpace $topicName;
    $subscriptionNames = $lf  | Where-Object { $_.topicName -eq $topicName } | Select-Object -Unique -ExpandProperty 'subscriptionName';
    foreach ($subscriptionName in $subscriptionNames)
    {
        CreateServiceBusTopicSubscriptionIfNeeded $ResourceGroupName $NameSpace $topicName $subscriptionName;
    }
}

foreach ($f in $lf){
    $topicName=$f.topicName;
    $subscriptionName=$f.subscriptionName; 
    $filter = $f.filter.Replace("''", "'");
    $filterName = "filter$(removeNonAlphaCharacters $filter)";
    Write-Host "Filter $ResourceGroupName $NameSpace $topicName $subscriptionName $filter $filterName." -ForegroundColor Green;
    New-AzureRmServiceBusRule -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Topic $topicName -Subscription $subscriptionName -Name $filterName -SqlExpression $filter;
}

Write-Host "`nDone."

