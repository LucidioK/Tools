param(
    [parameter(Mandatory=$false, Position=0)][string]$FileNamePattern  = '*.*',
    [parameter(Mandatory=$false, Position=1)][string]$SearchFolder = '.'
)


if ($null -eq $global:finder) { &(join-path $PSScriptRoot 'utils.ps1'); }

$global:finder.Initialize($SearchFolder, $FileNamePattern);

return $global:finder.Find();
