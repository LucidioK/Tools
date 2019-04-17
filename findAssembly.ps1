param(
    [parameter(Mandatory=$true, Position=0)][string]$assembly = 'System.Net.Http.Primitives.dll',
    [parameter(Mandatory=$true, Position=1)][string]$version  = '1.5.0.0',
    [parameter(Mandatory=$true, Position=2)][string]$publicKeyToken  = 'b03f5f7f11d50a3a'
)
#.\findAssembly.ps1 'System.Net.Http.Primitives.dll' '1.5.0.0' 'b03f5f7f11d50a3a'
if (!($assembly.EndsWith(".dll") -or $assembly.EndsWith(".exe")))
{
    throw "Assembly must end with .dll or .exe";
}

Write-Host "Findind all $assembly, this might take a while..." -ForegroundColor Green;

if (!($env:Path -ccontains 'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools'))
{
    $env:Path = $env:Path + ';C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools';
}

$files = Get-ChildItem -Path 'c:\' -Filter $assembly -Recurse -ErrorAction SilentlyContinue;

[string]$pkt = $publicKeyToken.ToUpperInvariant();
$publicKeyToken = "";
for ($i = 0; $i -lt $pkt.Length; $i = $i + 2)
{
    if ($publicKeyToken.Length -gt 0)
    {
        $publicKeyToken = $publicKeyToken + ' ';
    }
    $publicKeyToken = $publicKeyToken + $pkt.Substring($i, 2);
}

$publicKeyToken = "\.publickeytoken *= *\(" + $publicKeyToken;
$versionRegex   = 'System.Reflection.AssemblyFileVersionAttribute.*\.' + ($version.Replace('.', '\.'));
$count = 1;
$total = $files.Count;
foreach ($file in $files)
{
    Write-Host "$count / $total : $($file.FullName)" -ForegroundColor Green -NoNewline;
    $count = $count + 1;
    
    try
    {
        $fullName = ([system.reflection.assembly]::loadfile($file.FullName)).FullName;
    }
    catch
    {
        write-host " Exception: $_" -ForegroundColor Red;
        continue;
    }
    $publicToken = global:extractWithRegex $fullName '.*PublicKeyToken=([a-z0-9]+)';
    $thisVersion = global:extractWithRegex $fullName '.*Version=([0-9\.]+)';
    Write-Host " $publicToken $thisVersion" -ForegroundColor Green  -NoNewline;
    if ($publicToken -match $publicKeyToken)
    {
        if ($thisVersion -match $version)
        {
            Write-Host " YES!" -ForegroundColor Green;
        }
        elseif ($thisVersion -gt $version)
        {
            Write-Host " Newer version" -ForegroundColor Yellow;
        }
    }
    else
    {
        Write-Host " No..." -ForegroundColor Gray;
    }
}
