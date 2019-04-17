$rg=@{};
foreach($rgn in ((Get-AzureRmResourceGroup).ResourceGroupName).Where({$_.Contains($env:fgid)}))
{
    foreach($r in (get-azurermresource -ResourceGroupName $rgn).Name)
    {
        $rg[$r]=$rgn;
    }
}
foreach ($v in (Get-ChildItem Env:*)) 
{
if ($rg.ContainsKey($v.Value))
{
 $nm = "resourceGroupFor$($v.Name)"; 
 $vl = $rg[$v.Value]; 
 Invoke-Expression ('$env:' + $nm + "='$vl'");
 #[environment]::SetEnvironmentVariable($nm, $vl, 'Machine'); 
 write-host "$nm $vl"; 
}
}