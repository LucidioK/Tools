# To get the type list, run IlDasm.exe, open the .Net assembly, then File/Dump Tree.
param(
     [parameter(Mandatory=$true, HelpMessage = "Full file path for the result of File/Dump tree from ILDasm.exe", ValueFromPipeline=$false)]
     [string]$IlDasmTypeTreePath,
     [parameter(Mandatory=$true, HelpMessage = "Namespace for classes/interfaces to be retrieved.", ValueFromPipeline=$false)]
     [string]$BasicNamespace)

if (!(Test-Path $IlDasmTypeTreePath))
{
    throw "$IlDasmTypeTreePath not found."
}

[string[]]$lines = Get-Content $IlDasmTypeTreePath;

$currentClass = $null;
foreach ($line in $lines)
{
    if ($line.Contains("[CLS] $BasicNamespace"))
    {
        $currentClass
    }
}