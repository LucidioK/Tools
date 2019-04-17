param(
    [parameter(Mandatory=$true, position=0)][string]$FilePath,
    [parameter(Mandatory=$true, position=1)][string]$Separator
)
$o = @();
$columnSizes = @()
gc $FilePath |  foreach { 
    $o += $_; 
    $pieces = $_.Split($Separator);

    for ($i=0; $i -lt $pieces.Count; $i++) {
        if ($columnSizes[$i] -eq $null) {
            $columnSizes += 0;
        }
        if ($pieces[$i].Length -gt $columnSizes[$i]) {
            $columnSizes[$i] = $pieces[$i].Length;
        }
    }
}

$o |  foreach { 
    $pieces = $_.Split($Separator);
    $i = 0;
    $s = "";
    foreach ($piece in $pieces) {
        if ($i -gt 0) {
            $s += $Separator;
        }
        $s += $piece.PadRight($columnSizes[$i] + 1);
        $i++;
    }
    Write-Output $s;
}

