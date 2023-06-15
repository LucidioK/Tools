param(
    $correctReleaseJsonFileName               = 'C:\temp\pars.Infrastructure.Develop.Release.json', 
    $nameOfCorrectlyRunningEnvironment        = 'TestEast', 
    $toBeVerifiedReleaseJsonFileName          = 'C:\temp\pars.Infrastructure.Master.Release.json')

if ($null -eq $global:allSPNs)
{
    $global:allSPNs                           = (Get-AzureRmADServicePrincipal) | Select-Object Id, DisplayName;
}

if ($null -eq $global:allServiceEndPoints)
{
    $global:allServiceEndPoints               = (Get-Content (Join-Path $global:powerShellScriptDirectory 'allVSTSServiceEndPoints.json') | ConvertFrom-Json ) | Select-Object Id, Name;
}

class PropertyDiscrepancy
{
    [string]$PropertyName
    [object]$BaseValue
    [object]$FoundValue
}

class GenericDiscrepancy
{
    [string]$Name
    [string]$Description
}

class WorkflowTask
{
    [string]$Name
    [PropertyDiscrepancy[]]$PropertyDiscrepancies
}

class Phase
{
    [string]$Name
    [GenericDiscrepancy[]]$Discrepancies
    [WorkflowTask[]]$WorkflowTasks
}

class Environment
{
    [string]$Name
    [GenericDiscrepancy[]]$Discrepancies
    [Phase[]]$Phases    
}

class Analysis
{
    [string]$CorrectReleaseJsonFileName
    [string]$NameOfCorrectlyRunningEnvironment
    [string]$ToBeVerifiedReleaseJsonFileName
    [Environment[]]$CheckedEnvironments
}

function addSPNDisplayNameIfNeeded([string]$value)
{
    if (global:isItAGuid $value)
    {
        $possibleSPN                          = ($global:allServiceEndPoints | Where-Object { $_.Id -eq $value } ).Name;
        if ($null -ne $possibleSPN -and $possibleSPN.ToString() -ne '')
        {
            $value                            = $value + " [$possibleSPN]";
        }
        else
        {
            $possibleSPN                      = ($global:allSPNs | Where-Object { $_.Id -eq $value } ).DisplayName;
            if ($null -ne $possibleSPN -and $possibleSPN.ToString() -ne '')
            {
                $value                        = $value + " [$possibleSPN]";
            }
        }
    }
    return $value;
}

function areDifferent($o1, $o2)
{
    if ($null -ne $o1 -and $o1.GetType() -eq [string]) { $o1 = $o1.Replace(' ',''); }
    if ($null -ne $o2 -and $o2.GetType() -eq [string]) { $o2 = $o2.Replace(' ',''); }
    return $o1 -ne $o2;
}

function compareObjects([WorkflowTask]$worObj, $correctObject, $correctEnvironmentName, $objectToCheck, $environmentToCheckName)
{
    if ($correctObject.GetType().Name.StartsWith('Collection'))
    {
        $correctObject                        = $correctObject[0];
    }

    if ($objectToCheck.GetType().Name.StartsWith('Collection'))
    {
        $objectToCheck                        = $objectToCheck[0];
    }

    $propertyNames                            = (Get-Member -InputObject $correctObject -MemberType NoteProperty).Name;
    foreach ($propertyName in $propertyNames)
    {
        Write-Host "   Property $propertyName" -ForegroundColor Green;
        $correctValue                         = $correctObject."$propertyName";
        $checkingValue                        = $objectToCheck."$propertyName";
#        if ($propertyName.StartsWith('ConnectedService'))
#        {
#            Write-Host "$propertyName $correctValue $checkingValue";
#            Write-Host;
#        }
        if ($propertyName -eq 'Inputs')
        {
            compareObjects $worObj $correctValue $correctEnvironmentName $checkingValue $environmentToCheckName;
        }
        else
        { 
            if ($null -eq $correctValue -and $null -eq $checkingValue) { continue; }
            if ($null -ne $correctValue -and  $null -ne $checkingValue -and $correctValue.ToString() -eq '' -and $checkingValue.ToString() -eq '') { continue; }
            if (areDifferent $correctValue $checkingValue)
            {
                [PropertyDiscrepancy]$disObj  = new-object PropertyDiscrepancy;
                $disObj.PropertyName          = $propertyName;
                $disObj.BaseValue             = addSPNDisplayNameIfNeeded $correctValue;
                $disObj.FoundValue            = addSPNDisplayNameIfNeeded $checkingValue;
                Write-Host "    $($disObj.BaseValue) $($disObj.FoundValue)" -ForegroundColor Yellow;
                $worObj.PropertyDiscrepancies = $worObj.PropertyDiscrepancies + $disObj;
            }
        }
    }
}

[Analysis]$analysis                           = New-Object Analysis;
$analysis.CorrectReleaseJsonFileName          = $CorrectReleaseJsonFileName;
$analysis.NameOfCorrectlyRunningEnvironment   = $NameOfCorrectlyRunningEnvironment;
$analysis.ToBeVerifiedReleaseJsonFileName     = $ToBeVerifiedReleaseJsonFileName;
$analysis.CheckedEnvironments                 = @();

$correctReleaseDefinition                     = Get-Content $correctReleaseJsonFileName | ConvertFrom-Json;
$toBeVerifiedReleaseDefinition                = Get-Content $toBeVerifiedReleaseJsonFileName | ConvertFrom-Json;

$correctEnvironment                           = ($correctReleaseDefinition.Environments).Where({$_.Name -eq $nameOfCorrectlyRunningEnvironment});
$environmentsToCheck                          = ($toBeVerifiedReleaseDefinition.Environments).Where({$_.Name -ne $nameOfCorrectlyRunningEnvironment});


foreach ($environmentToCheck in $environmentsToCheck)
{
    $environmentName                          = $environmentToCheck.Name;
    Write-Host "Environment $environmentName" -ForegroundColor Green;
    [Environment]$envObj                      = New-Object Environment;
    $envObj.Name                              = $environmentName;
    $envObj.Discrepancies                     = @();
    $envObj.Phases                            = @();

    $phases                                   = $environmentToCheck.DeployPhases;
    foreach ($phase in $phases)
    {
        [Phase]$phaObj                        = New-Object Phase;
        $phaObj.Name                          = $phase.Name;
        $phaObj.Discrepancies                 = @();
        $phaObj.WorkflowTasks                 = @();
        $phaseName                            = $phase.Name;
        Write-Host " Phase $phaseName" -ForegroundColor Green;
        $correctPhase                         = $correctEnvironment.DeployPhases | Where-Object { $_.Name -eq $phaseName};
        if ($null -eq $correctPhase)
        {
            [GenericDiscrepancy]$disObj       = New-Object GenericDiscrepancy;
            $disObj.Name                      = $phaseName;
            $disObj.Description               = "Phase $phaseName found in environment $environmentName but not in $nameOfCorrectlyRunningEnvironment";
            $envObj.Discrepancies             = $envObj.Discrepancies +$disObj;
            $envObj.Phases                    = $envObj.Phases + $phaObj;
             Write-Host "  $($disObj.Description)" -ForegroundColor Yellow;
            continue;
        }

        $workflowTasks                        = $phase.WorkFlowTasks;
        foreach ($workflowTask in $workflowTasks)
        {
            $workflowTaskName                 = $workflowTask.Name;
            Write-Host "  WorkflowTask $workflowTaskName" -ForegroundColor Green;
            [WorkflowTask]$worObj             = New-Object WorkflowTask;
            $worObj.Name                      = $workflowTaskName;
            $worObj.PropertyDiscrepancies     = @();
            $correctWorkflowTask              = ($correctPhase.WorkflowTasks) | Where-Object { $_.Name -eq $workflowTaskName};
            if ($null -eq $correctWorkflowTask)
            {
                [GenericDiscrepancy]$disObj   = New-Object GenericDiscrepancy;
                $disObj.Name                  = $workflowTaskName;
                $disObj.Description           = "WorkflowTask $phaseName $workflowTaskName found in environment $environmentName but not in $nameOfCorrectlyRunningEnvironment"
                $phaObj.Discrepancies         = $phaObj.Discrepancies + $disObj;
                continue;
            }

            compareObjects $worObj $correctWorkflowTask $nameOfCorrectlyRunningEnvironment $workflowTask $environmentToCheck.Name;
            if ($worObj.PropertyDiscrepancies.Count -gt 0)
            {
                $phaObj.WorkflowTasks         = $phaObj.WorkflowTasks +$worObj;
            }
        }

        $envObj.Phases                        = $envObj.Phases + $phaObj;
    }

    $analysis.CheckedEnvironments             = $analysis.CheckedEnvironments + $envObj;
}

return $analysis;

