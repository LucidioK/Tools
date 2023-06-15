
function global:Get-FunctionWithAllDependencies
{
    [CmdletBinding()]
    param([parameter(Mandatory=$false)][string]$FunctionName)


    function isInList([object[]]$l, [string]$functionName)
    {
        $item = $l | Where-Object Name -eq $functionName;
        $isIn = $null -ne $item;
        return $isIn;
    }

    function notInList([object[]]$l, [string]$functionName)
    {
        $isIn = isInList $l $functionName;
        return (-not $isIn);
    }

    function isInImportModules([string]$moduleName)
    {
        $null -eq ($global:importModules | Where-Object { $_.Contains("'$moduleName'") });
    }
    
    function parseAndAdd([object]$fnNmd, [string]$functionNameToAdd)
    {
        Write-Host "$functionNameToAdd" -ForegroundColor Green;
        $functionDefinition = $allFunctions | Where-Object Name -eq $functionNameToAdd;

        if ($null -ne $functionDefinition -and 
            -not [string]::IsNullOrEmpty($functionDefinition.Module) -and
            $null -eq ($fnNmd.Modules | Where-Object { $_.Contains("'$moduleName'") }))
        {
            $fnNmd.Modules  += "Import-Module -Name '$($functionDefinition.Module)';"
        }
        elseif ($null -ne $functionDefinition -and 
            (notInList $fnNmd.Functions $functionNameToAdd) -and
            -not [string]::IsNullOrEmpty($functionDefinition.File))
        {
            Write-Verbose " Yes...";
            $fnNmd.Functions += $functionDefinition;
            $referencedFunctions = ([Regex]::Matches($functionDefinition.Definition, '[A-Za-z][A-Za-z-]+')).Value | 
                Select-Object -Unique | 
                Sort-Object;
            $referencedFunctions = $referencedFunctions | 
                Where-Object { (notInList $fnNmd.Functions $_) -and (isInList $allFunctions $_) };

            if ($null -ne $referencedFunctions)
            {
                Write-Verbose " Referenced functions: [$([string]::Join(",", $referencedFunctions))]...";
            }

            foreach ($referendedFunction in $referencedFunctions)
            {
                $fnNmd = parseAndAdd $fnNmd $referendedFunction;
            }
        }
        else
        {
            Write-Host " No..." -ForegroundColor Yellow;
        }

        return $fnNmd;
    }

    $allFunctions = get-childitem function:* | 
        ForEach-Object { [PSCustomObject]@{ Name=$_.Name; Definition=$_.ScriptBlock.StartPosition.Content; File=$_.ScriptBlock.File; Module = $_.ModuleName } };

    $functionsAndModules = [PSCustomObject]@{
        Functions = @();
        Modules   = @();
    }

    $functionsAndModules = parseAndAdd $functionsAndModules $FunctionName;

    $functionsAndModules.Functions = $functionsAndModules.Functions | Sort-Object -Property Name;

    $finalDefinition = [string]::Join("`n", $functionsAndModules.Modules);
    $finalDefinition += "`n`n";
    $finalDefinition += [string]::Join("`n`n`n", ($functionsAndModules.Functions).Definition);

    $envVariables = ([Regex]::Matches($finalDefinition, '\$env:[A-Za-z][A-Za-z-]+')).Value | Sort-Object | Select-Object -Unique;
    $globalVariables = ([Regex]::Matches($finalDefinition, '\$global:[A-Za-z][A-Za-z-]+')).Value | Sort-Object | Select-Object -Unique;

    if ($null -ne $envVariables)
    {
        Write-Host "`nIMPORTANT: please verify whether these Environment variables will exist where the new script will execute:`n $([string]::Join("`n ", $envVariables))`n" -ForegroundColor Magenta;
    }

    if ($null -ne $globalVariables)
    {
        Write-Host "`nIMPORTANT: please verify whether these Global variables will exist where the new script will execute:`n $([string]::Join("`n ", $globalVariables))`n" -ForegroundColor Magenta;
    }

    return $finalDefinition;
}

