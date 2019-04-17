param(
    $correctReleaseJsonFileName               = 'C:\temp\eGift.Infrastructure.Develop.Release.json', 
    $nameOfCorrectlyRunningEnvironment        = 'TestEast', 
    $toBeVerifiedReleaseJsonFileName          = 'C:\temp\eGift.Infrastructure.Master.Release.json')

if ($global:allSPNs -eq $null)
{
    $global:allSPNs                           = (Get-AzureRmADServicePrincipal) | Select Id, DisplayName;
}

if ($global:allServiceEndPoints -eq $null)
{
    $global:allServiceEndPoints               = (gc (Join-Path $global:powerShellScriptDirectory 'allVSTSServiceEndPoints.json') | ConvertFrom-Json ) | Select Id, Name;
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
        $possibleSPN                          = ($global:allServiceEndPoints | where { $_.Id -eq $value } ).Name;
        if ($possibleSPN -ne $null -and $possibleSPN.ToString() -ne '')
        {
            $value                            = $value + " [$possibleSPN]";
        }
        else
        {
            $possibleSPN                      = ($global:allSPNs | where { $_.Id -eq $value } ).DisplayName;
            if ($possibleSPN -ne $null -and $possibleSPN.ToString() -ne '')
            {
                $value                        = $value + " [$possibleSPN]";
            }
        }
    }
    return $value;
}

function areDifferent($o1, $o2)
{
    if ($o1 -ne $null -and $o1.GetType() -eq [string]) { $o1 = $o1.Replace(' ',''); }
    if ($o2 -ne $null -and $o2.GetType() -eq [string]) { $o2 = $o2.Replace(' ',''); }
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
            if ($correctValue -eq $null -and $checkingValue  -eq $null) { continue; }
            if ($correctValue -ne $null -and  $checkingValue -ne $null -and $correctValue.ToString() -eq '' -and $checkingValue.ToString() -eq '') { continue; }
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

$correctReleaseDefinition                     = gc $correctReleaseJsonFileName | ConvertFrom-Json;
$toBeVerifiedReleaseDefinition                = gc $toBeVerifiedReleaseJsonFileName | ConvertFrom-Json;

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
        $correctPhase                         = $correctEnvironment.DeployPhases | Where { $_.Name -eq $phaseName};
        if ($correctPhase -eq $null)
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
            $correctWorkflowTask              = ($correctPhase.WorkflowTasks) | Where { $_.Name -eq $workflowTaskName};
            if ($correctWorkflowTask -eq $null)
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

