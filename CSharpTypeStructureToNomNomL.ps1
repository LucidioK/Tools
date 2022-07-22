$types = CSharpTypeStructure.ps1
foreach ($type in $types)
{
    if ($type.DerivesFrom -eq $null -and $type.References -eq $null)
    {
        Write-Output "[$($type.Name)]";
        continue;
    }
    foreach ($d in $type.DerivesFrom)
    {
        $definition = $types | where { $_.Name -eq $d };
        if ($definition -ne $null -and $definition.Kind -eq 'interface')
        {
            Write-Output "[$($type.Name)]--:>[$d]";
        }
        else
        {
            Write-Output "[$($type.Name)]-:>[$d]";
        }
    }
    $p = $null;
    foreach ($r in $type.References)
    {
        Write-Output "[$($type.Name)]-->[$r]";
    }
}