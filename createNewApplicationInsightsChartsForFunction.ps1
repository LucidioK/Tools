#
# This script adds the two most common charts into an Application Insights dashboard.
# The charts are: Availability and Response Time.
#
# Input:
#  applicationInsightsTemplateJsonFilePath: The ARM template for the Application Insights to be used as input.
#  functionName: Name of the function.
#
# Output:
#  The ARM template with the new charts, as JSON in the standard output.
#  Notice that the output does not follow the format used in our ARM templates,
#  so you better follow these steps to have it properly formatted:
#   a. Run the script, save it to another file, for instance:
#
#      (.\createNewApplicationInsightsChartsForFunction.ps1 -applicationInsightsTemplateJsonFilePath 'C:\MYSOURCES\egiftazure\Deployment\appinsights\appInsightsEGiftFnHealthOverviewDeploy.json' -functionName RefundOrderForPayPal) | Out-File 'c:\temp\refund.json'
#      
#      At the end of the script execution, it will say where the new charts were inserted, for instance:
#
#             Inserting UpdatePayPalOrder Availability in position 27
#             Inserting UpdatePayPalOrder Response Time in position 28
#
#   b. Using Visual Studio, open the generated file, search for "27" (for example)
#   c. Select all definition for "27" and "28" (and in the example), including the comma after the last curly brace before "27"
#   d.On the selection, remove all beginning spaces and new lines, by doing this:
#     Type Control-H (replace)
#     Select Regular Expressions (the .* icon)
#     Replace ^ +|\r\n for empty string.
#   e. Open the input ARM Template and copy "27" and "28" (for example) to the ARM Template, after the definition for "26" (for example).
#   f. Select the inserted text.
#   f. Now go to Edit / Advanced / Format Selection.
#   g. Save, commit and push the ARM Template file. 
#   h. After code review, merge it and run the release.
#
param(
    [string]$applicationInsightsTemplateJsonFilePath = 'C:\dsv\egiftazure\Deployment\appinsights\appInsightsEGiftFnHealthOverviewDeploy.json',
    [string]$functionName = 'CreateOrderForPayPal'
)

function max($a,$b) { if ($a -gt $b) { return $a; } else { return $b; } }

function extractWithRegex([string]$str, [string]$patternWithOneGroupMarker)
{
    if ($str -match $patternWithOneGroupMarker)
    {
        $ret = $matches[1];
    }
    else
    {
        $ret = $null;
    }
    return $ret;
}

function cloneObject($o)
{
    if ($o -eq $null)
    {
        return $null;
    }
    $t = $o.GetType();
    if ($t -eq [string] -or $t.IsValueType)
    {
        return $o;
    }
    if ($t.IsArray)
    {
        $a = @();
        foreach ($item in $o)
        {
            $a = $a + (global:cloneObject $item);
        }
        return $a;
    }
    $n = New-Object -TypeName PSCustomObject;
    $propertyNames = (Get-Member -InputObject $o -MemberType NoteProperty).Name;
    foreach ($propertyName in $propertyNames)
    {
        $n | Add-Member -MemberType NoteProperty -Name $propertyName -Value (global:cloneObject $o."$propertyName");
    }
    return $n;
}

function newPart($basePart, [int]$partId, [string]$regexPatternForFunctionNameInQuery, [string]$newFunctionName, [string]$title)
{
    Write-Host "Inserting $title in position $partId" -ForegroundColor Green;
    $newPart = cloneObject $basePart;
    $newPart.position.x += 6;
    $newPart.position.y += 6;
    $query = $newPart.metadata.inputs.Where( { $_.name -eq 'Query' } );
    $oldFunctionName = extractWithRegex $query.Value $regexPatternForFunctionNameInQuery;
    $query[0].Value = $query.Value.Replace($oldFunctionName, $newFunctionName);
    ($newPart.metadata.inputs.Where( { $_.name -eq 'PartId' } ))[0].Value = New-Guid;
    $newpart.metadata.settings.content.dashboardPartTitle = $title;
    return $newPart;
}

$a = gc $applicationInsightsTemplateJsonFilePath | ConvertFrom-Json;
$parts = $a.resources[0].properties.lenses."0".parts;
$count = (Get-Member -InputObject $parts -MemberType NoteProperty).Count;
$maxX  = -1;
$maxY  = -1;

for ($i = 0; $i -lt $count; $i++)
{
    $part = $parts."$i";
    Write-Host "Analysing $i $($part.metadata.settings.content.dashboardPartTitle)" -ForegroundColor Green;
    $maxX = max $part.position.x $maxX;
    $maxY = max $part.position.y $maxY;
    $query = ($part.metadata.inputs).Where( { $_.name -eq 'Query' } );

    if ($query -ne $null -and $query.Value -ne $null)
    {
        if ($query.Value.Contains('summarize count() by resultCode'))
        {
            $availabilityPart = $part;
        }
        elseif ($query.Value.Contains('summarize avg(duration)'))
        {
            $responseTimePart = $part;
        }
    }
}

$nextAvailabilityId = $count;
$nextResponseTimeId = $nextAvailabilityId + 1;


$nextAvailabilityPartObject = newPart $availabilityPart $nextAvailabilityId '.*and name == ''(.*?)''' $functionName "$functionName Availability";
$nextResponseTimePartObject = newPart $responseTimePart $nextresponseTimeId '.*and name == ''(.*?)''' $functionName "$functionName Response Time";

$a.resources[0].properties.lenses."0".parts | Add-Member -Name $nextAvailabilityId.ToString() -MemberType NoteProperty -Value $nextAvailabilityPartObject;
$a.resources[0].properties.lenses."0".parts | Add-Member -Name $nextResponseTimeId.ToString() -MemberType NoteProperty -Value $nextResponseTimePartObject;

if ($global:JsonBeautifierJsonBeautifyDefined -eq $null)
{
    &(join-path $PSScriptRoot 'Utils.ps1');
}

return (global:toBeautifulJson $a);


