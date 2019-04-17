param($rg,$ns,$json)
$lf=$json|ConvertFrom-Json;
$jobs = @();
foreach ($f in $lf){
 $t=$f.topicName;
 $n=$f.subscriptionName; 
 Write-Host "Filter $rg $ns $t $n $($f.filter).";
 $jobs += Start-Job { New-AzureRmServiceBusRule -ResourceGroupName $rg -Namespace $ns -Topic $t -Subscription $n -Name 'filter' -SqlExpression $f.filter; };
}
Write-Host "Waiting $($jobs.Count) jobs..."
Wait-Job -Job $jobs;
Write-Host "`nDone."
