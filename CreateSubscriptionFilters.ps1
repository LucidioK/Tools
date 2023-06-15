param($rg,$ns,$json)
$lf = $json | ConvertFrom-Json;
foreach ($f in $lf){
    $topicName=$f.topicName;
    $subscriptionName=$f.subscriptionName; 
    $filter = $f.filter.Replace("''", "'");
    $filterName = "filter$(removeNonAlphaCharacters $filter)";
    Write-Host "Filter $ResourceGroupName $NameSpace $topicName $subscriptionName $filter $filterNam." -ForegroundColor Green;
    New-AzureRmServiceBusRule -ResourceGroupName $ResourceGroupName -Namespace $NameSpace -Topic $topicName -Subscription $subscriptionName -Name $filterName -SqlExpression $filter;
}
Write-Host "`nDone."

