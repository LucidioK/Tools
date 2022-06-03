param(
    [parameter(Mandatory=$true , Position = 0)]
    [string]$ExecutableNameWithExtension,    
    [parameter(Mandatory=$true , Position = 1)]
    [string]$NugetPackageName    
)

if ($null -eq (where.exe 'nuget'))
{
    throw "Please install nuget.";
}

if ($null -eq (Get-Command Add-PathVariable -ErrorAction Ignore))
{
    Install-Module -Name Pscx -Force -AllowClobber;
}

$executablePath = where.exe $ExecutableNameWithExtension;
if ($null -eq $executablePath)
{
    $nugetPackagesFolder = (nuget locals global-packages -list).Replace('global-packages: ','');;
    $package = Install-Package $NugetPackageName -Source 'nuget.org' -Force -Destination $nugetPackagesFolder;
    $kustoToolsFolder = (get-childItem -Path $nugetPackagesFolder -Filter "$($package.Name)*.*").FullName;
    $candidates = (get-childitem -Path $kustoToolsFolder -Recurse -Filter $ExecutableNameWithExtension).FullName;
    foreach ($candidate in $candidates)
    {
        try
        {
            [System.Reflection.Assembly]::LoadFrom($candidate);
            Add-PathVariable -Value ([System.IO.Path]::GetDirectoryName($candidate)) -Name 'Path' -Target User;
            $executablePath = $candidate;
            break;
        }
        catch
        {
            Write-Host "OK, couldn't load from $candidate, let's see if there is another version..." -ForegroundColor Yellow;
        }
    }
}

return $executablePath;
