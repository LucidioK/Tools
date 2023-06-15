function codeCleanup([string]$code)
{
    $code = [Regex]::new('^using .*').Replace($code, "");
    $code = [Regex]::new('#pragma .*').Replace($code, "");
    $code = [Regex]::new('#if .*').Replace($code, "");
    $code = [Regex]::new('#region .*').Replace($code, "");
    $code = [Regex]::new('#else .*').Replace($code, "");
    $code = [Regex]::new('#end.*').Replace($code, "");
    $code = [Regex]::new('^namespace .*').Replace($code, "");
    $code = [Regex]::new('".*?"').Replace($code, "");
    $code = [Regex]::new("'.*?'").Replace($code, "");
    $code = [Regex]::new('`.*?`').Replace($code, "");
    $code = [Regex]::new('//.*|/\*(.|\r|\n)*?\*/').Replace($code, "");
    $code = [Regex]::new('[\r\n\t]').Replace($code, " ");

    $code = [Regex]::new(' *, *').Replace($code, ",");
    $code = [Regex]::new(' *: *').Replace($code, ":");
    $code = [Regex]::new('  +').Replace($code, " ");
    return $code;
}

function getClassBody([string]$code, [System.Text.RegularExpressions.Match]$m)
{
    $countBraces = 0;
    for ($pos = $code.IndexOfAny(@('{','}'), $m.Index); $pos -gt 0; $pos = $code.IndexOfAny(@('{','}'), $pos + 1))
    {
        if ($code[$pos] -eq '{') { $countBraces += 1 } else { $countBraces += -1 };
        if ($countBraces -eq 0)
        {
            return $code.Substring($m.Index, $pos +1 - $m.Index);
        }
    }
    return $null;
}

function getDerives([object]$tp)
{
    $m = [Regex]::new("$($tp.Kind) $($tp.Name)").Match($tp.Body);
    if ($tp.Body[$m.Index + $m.Length] -eq ':')
    {
        $derives = [Regex]::new('.*?{').Match($tp.Body.Substring($m.Index + $m.Length + 1)).Value.Replace(' ','').Replace('{','');
        $derives = $derives | ForEach-Object { $_.Substring($_.LastIndexOf('.')+1) }
        $templateTypes = $derives | Where-Object { $_.Contains('<') };
        if ($templateTypes)
        {
            $templateTypes |
            Where-Object { $_.Contains('<') } | 
            ForEach-Object {
                $positionLastOpeningBracket = $_.LastIndexOf('<');
                $positionClosingBracket     = $_.IndexOf('>', $positionLastOpeningBracket);
                $internalTypeName           = $_.Substring($positionLastOpeningBracket+1, $positionClosingBracket - $positionLastOpeningBracket - 1);
                $derives                   += ",$internalTypeName";
            }
        }
        return ($derives.Split(','));
    }
    else
    {
        return $null;
    }
}

function getDerivesFrom([object]$tp, [object[]]$types)
{
    $derives = getDerives $tp;
    if ($null -ne $derives)
    {
        return (($types | Where-Object { $derives.Contains($_.Name) }).Name);
    }

    return $null;
}

function getReferences([object]$tp, [object[]]$types)
{
    $code = $tp.Body.Substring($tp.Body.IndexOf('{'));
    $otherTypeNames = ($types | Where-Object { $_.Name -ne $tp.Name }).Name;
    $pattern = [string]::Join('|', ($otherTypeNames | ForEach-Object { "[^A-Za-z0-9_<>]$($_)[^A-Za-z0-9_<>]" }));
    $ms = [Regex]::new($pattern).Matches($code);
    $refs = @();
    foreach ($m in $ms)
    {
        $typeName = $m.Value -replace '[^A-Za-z0-9_<>]','';
        $refs += $typeName;
    }

    return ($refs | Sort-Object -Unique);
}

$allCsCode  = ""; (get-childitem -Path . -Filter '*.cs' -Recurse).FullName | ForEach-Object { $c = Get-Content $_ -Raw; $allCsCode += $c; }
$allCsCode2 = codeCleanup $allCsCode;
$ms = [Regex]::new("(class|interface) ([A-Z][A-Za-z0-9_<>]*)").Matches($allCsCode2);
$types = @();

foreach ($m in $ms)
{
    $nm = $m.Value.Split(' ')[1];
    $ci = $m.Value.Split(' ')[0];

    $tp = [PSCustomObject]@{Name = $nm; Kind = $ci; Body = (getClassBody $allCsCode2 $m); DerivesFrom = $null; <#Implements = $null;#> References = $null; };
    $types += $tp;
}

$types = $types | Sort-Object -Property Name -Unique;

foreach ($tp in $types)
{
    $tp.DerivesFrom = (getDerivesFrom $tp $types);
    $tp.References  = (getReferences  $tp $types);
}
return $types;
