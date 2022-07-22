
function global:Get-FunctionWithAllDependencies
{
    [CmdletBinding()]
    param([parameter(Mandatory=$false)][string]$FunctionName)


    function isInList([object[]]$l, [string]$functionName)
    {
        $item = $l | where Name -eq $functionName;
        $isIn = $item -ne $null;
        return $isIn;
    }

    function notInList([object[]]$l, [string]$functionName)
    {
        $isIn = isInList $l $functionName;
        return (-not $isIn);
    }

    function isInImportModules([string]$moduleName)
    {
        ($global:importModules | where { $_.Contains("'$moduleName'") }) -eq $null;
    }
    
    function parseAndAdd([object]$fnNmd, [string]$functionNameToAdd)
    {
        Write-Host "$functionNameToAdd" -ForegroundColor Green;
        $functionDefinition = $allFunctions | where Name -eq $functionNameToAdd;

        if ($functionDefinition -ne $null -and 
            -not [string]::IsNullOrEmpty($functionDefinition.Module) -and
            ($fnNmd.Modules | where { $_.Contains("'$moduleName'") }) -eq $null)
        {
            $fnNmd.Modules  += "Import-Module -Name '$($functionDefinition.Module)';"
        }
        elseif ($functionDefinition -ne $null -and 
            (notInList $fnNmd.Functions $functionNameToAdd) -and
            -not [string]::IsNullOrEmpty($functionDefinition.File))
        {
            Write-Verbose " Yes...";
            $fnNmd.Functions += $functionDefinition;
            $referencedFunctions = ([Regex]::Matches($functionDefinition.Definition, '[A-Za-z][A-Za-z-]+')).Value | 
                select -Unique | 
                sort;
            $referencedFunctions = $referencedFunctions | 
                where { (notInList $fnNmd.Functions $_) -and (isInList $allFunctions $_) };

            if ($referencedFunctions -ne $null)
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
        foreach { [PSCustomObject]@{ Name=$_.Name; Definition=$_.ScriptBlock.StartPosition.Content; File=$_.ScriptBlock.File; Module = $_.ModuleName } };

    $functionsAndModules = [PSCustomObject]@{
        Functions = @();
        Modules   = @();
    }

    $functionsAndModules = parseAndAdd $functionsAndModules $FunctionName;

    $functionsAndModules.Functions = $functionsAndModules.Functions | sort -Property Name;

    $finalDefinition = [string]::Join("`n", $functionsAndModules.Modules);
    $finalDefinition += "`n`n";
    $finalDefinition += [string]::Join("`n`n`n", ($functionsAndModules.Functions).Definition);

    $envVariables = ([Regex]::Matches($finalDefinition, '\$env:[A-Za-z][A-Za-z-]+')).Value | sort | select -Unique;
    $globalVariables = ([Regex]::Matches($finalDefinition, '\$global:[A-Za-z][A-Za-z-]+')).Value | sort | select -Unique;

    if ($envVariables -ne $null)
    {
        Write-Host "`nIMPORTANT: please verify whether these Environment variables will exist where the new script will execute:`n $([string]::Join("`n ", $envVariables))`n" -ForegroundColor Magenta;
    }

    if ($globalVariables -ne $null)
    {
        Write-Host "`nIMPORTANT: please verify whether these Global variables will exist where the new script will execute:`n $([string]::Join("`n ", $globalVariables))`n" -ForegroundColor Magenta;
    }

    return $finalDefinition;
}

