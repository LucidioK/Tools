$types = CSharpTypeStructure.ps1
Write-Output '#direction: right';
Write-Output '#gravity: 2';
Write-Output '#edges: rounded';
Write-Output '#ranker: tight-tree';
foreach ($type in $types)
{
    if ($null -eq $type.DerivesFrom -and $null -eq $type.References)
    {
        Write-Output "[$($type.Name)]";
        continue;
    }

    foreach ($d in $type.DerivesFrom)
    {
        $definition = $types | Where-Object { $_.Name -eq $d };
        if ($null -ne $definition -and $definition.Kind -eq 'interface')
        {
            Write-Output "[$($type.Name)]--:>[$d]";
        }
        else
        {
            Write-Output "[$($type.Name)]-:>[$d]";
        }
    }

    foreach ($r in $type.References)
    {
        Write-Output "[$($type.Name)]-->[$r]";
    }
}