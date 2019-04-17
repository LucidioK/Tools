param(
    [parameter(Mandatory=$false, Position=0)][string]$FileNamePattern  = '*.*',
    [parameter(Mandatory=$false, Position=1)][string]$SearchFolder = '.',
    [parameter(Mandatory=$false, Position=2)][string]$ForD = 'F'
)

&(join-path $PSScriptRoot 'findClass.ps1');
$finder.Initialize($SearchFolder, $ForD, $FileNamePattern);

$finder.MoveToRecycleBin();
