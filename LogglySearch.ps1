param(
    [parameter(Mandatory=$false, Position=0)][string]$columns    = 'json.Application,json.Cloud,http.clientHost,json.Exception,json.Commit',
    [parameter(Mandatory=$false, Position=1)][string]$terms      = 'InnerException StackTrace',
    [parameter(Mandatory=$false, Position=2)][string]$filter     = $null, #'json.Level:"Error" json.Commit:"b995211"',
    [parameter(Mandatory=$false, Position=3)][int]   $size       = 1000,
    [parameter(Mandatory=$false, Position=4)][string]$from       = "-1d",
    [parameter(Mandatory=$false, Position=5)][string]$to         = "now",
    [parameter(Mandatory=$false, Position=6)][string]$jsonCommit = $null,
    [parameter(Mandatory=$false, Position=7)][string]$jsonVertical = $null,
    [parameter(Mandatory=$false, Position=8)][ValidateSet('Error','Debug','Warning','Information','*')][string]$jsonLevel  = "Error",
    [parameter(Mandatory=$false, Position=9)][switch]$keepLogMsgColumn,
    [ValidateSet('csv','json')][parameter(Mandatory=$false, Position=10)][string]$format  = "json"

)
$start=get-date;

function AtLeastEmptyString([string]$s)
{
    if (!(ShouldCareAbout $s))
    {
        return '';
    }
    return $s;
}

function GetFromLoggly([string]$terms, [string]$filter, [int]$size, [string]$from, [string]$to)
{
    Write-Host "About to invoke $url" -ForegroundColor Green;
    $result = Invoke-WebRequest -Headers @{ Authorization = "Bearer LOOGLY_TOKEN" } -Uri $url;
    if ($result.StatusCode -ne 200)
    {
        throw "Search failed...";
    }
    return $result.Content;
}

function ShouldCareAbout([string]$str)
{
    return $str  -ne $null -and $str.Length -gt 0 -and $str -ne '*';
}

function GetSearchUrl([string]$terms, [string]$filter, [int]$size, [string]$from, [string]$to)
{

    if (!(ShouldCareAbout $filter)) { $filter = "*"; }
    if (ShouldCareAbout $terms) 
    { 
        $filter = "$(AtLeastEmptyString $filter) json.context.terms:`"$terms`"";
    }
    $url = "https://LK.loggly.com/apiv2/search?q=$filter&from=$from&until=$to";
    if ($size -gt 0)
    {
        $url += "&size=$size";
    }
    return $url;
}

function GetEventsUrl([string]$rsid, [string]$columns, [string]$format)
{
    $url = "https://LK.loggly.com/apiv2/events?rsid=$rsid&format=$format";
    if (ShouldCareAbout $columns)
    {
        $url += "&columns=$columns"
    }
    return $url;
}


function Search([string]$terms, [string]$filter, [int]$size, [string]$from, [string]$to)
{
    $url = GetSearchUrl  $terms $filter $size $from $to;
    $searchResult = GetFromLoggly $url;
    return $searchResult;
}


function GetEvents([string]$rsid, [string]$columns, [string]$format)
{
    $url = GetEventsUrl $rsid $columns $format;
    $eventsResult = GetFromLoggly $url;
    return $eventsResult;
}

function removeProperties([object]$o, [string[]]$propertyNamesToBeRemoved)
{
    $n = New-Object -TypeName PSCustomObject;
    $properties = get-member -InputObject $o -MemberType NoteProperty;
    for ($i = $properties.Count - 1; $i -ge 0; $i--)
    {
        $property = $properties[$i];
        if (!($propertyNamesToBeRemoved.Contains($property.Name)))
        {
            $value = $o."$($property.Name)";
            Add-Member -InputObject $n -MemberType NoteProperty -Name $property.Name -Value $value;
        }
    }
    return $n;
}

function RemoveLogMsg([string]$eventsResult)
{
    $events = $eventsResult | ConvertFrom-Csv;

    for ($i=0;$i -lt $events.Count; $i++) 
    { 
        $events[$i] = removeProperties $events[$i] @("logmsg") ;
    }

    $tempFileName = [System.IO.Path]::GetTempFileName();
    $events | Export-Csv -Encoding ASCII -Path $tempFileName -NoTypeInformation;
    $eventsResult = gc $tempFileName;
    del $tempFileName;
    if (!($eventsResult.Contains("`n")))
    {
        $eventsResult = $eventsResult -replace '" "20',"`"`n`"";
    }

    return $eventsResult;
}

function flattenObject([PSCustomObject]$o, [string]$prefix="", [PSCustomObject]$newObject = $null)
{
    if ($newObject -eq $null)
    {
        $newObject = new-object -TypeName PSCustomObject;
    }
    if ($prefix.Length -gt 0)
    {
        $prefix += "_";
    }
    $propertyNames = get-member -InputObject $o -MemberType NoteProperty | select -ExpandProperty Name;
    $exceptionProperties = @{};
    foreach ($propertyName in $propertyNames)
    {
        $value = $o."$propertyName";
        $name = ($prefix + $propertyName);
        $type = if ($value -eq $null) { "null" } else { $value.GetType().Name };
#Write-host "--> $name $type $value" -ForegroundColor Green;
        if ($value -ne $null -and $type -eq 'Object[]')
        {
            $value = $value | ConvertTo-Json | ConvertFrom-Json;
            $type = $value.GetType().Name;
        }
        if ($value -ne $null -and $type -eq 'PSCustomObject')
        {
            $newObject = flattenObject $value $name $newObject;
        }
        if ($value -ne $null -and $type -eq 'Hashtable')
        {
            Add-Member -InputObject $newObject -MemberType NoteProperty -Name $name -Value ($value | convertto-json -Compress);
        }
        if ($type -ne 'PSCustomObject' -and $type -ne 'Object[]' -and $type -ne 'Hashtable')
        {
            if ($type -eq "String")
            {
                $value = $value  -replace '[\r\n]','';
            }
            if ($name.Contains("_Exception_"))
            {
                $exceptionProperties.Add($name, $value);                
            }
            else
            {
                Add-Member -InputObject $newObject -MemberType NoteProperty -Name $name -Value $value;
            }
        }
    }
    $innerExceptionsPropertyNames = $exceptionProperties.Keys | where { $_.Contains("InnerExceptions") };
    $exceptionsPropertyNames      = $exceptionProperties.Keys | where { $_.Contains("_Exception_") -and !($_.Contains("InnerExceptions")) };
    if ($innerExceptionsPropertyNames -ne $null -and $innerExceptionsPropertyNames.Count -gt 0)
    {
        $innerMostLevel = "";
        while (($innerExceptionsPropertyNames | where { $_.Contains($innerMostLevel + '_InnerExceptions') }).Count -gt 0)
        {
            $innerMostLevel += '_InnerExceptions';
        }
        $innerMostPropertyNames = $exceptionProperties.Keys | where { $_.Contains($innerMostLevel) };
        foreach ($innerMostPropertyName in $innerMostPropertyNames)
        {
            $plainExceptionPropertyName = $innerMostPropertyName.Replace($innerMostLevel, "");
            $exceptionProperties[$plainExceptionPropertyName] = $exceptionProperties[$innerMostPropertyName];
        }
        foreach ($innerExceptionsPropertyName in $innerExceptionsPropertyNames)
        {
            $exceptionProperties.Remove($innerExceptionsPropertyName);
        }
    }
    foreach ($exceptionPropertyName in $exceptionProperties.Keys)
    {
        Add-Member -InputObject $newObject -MemberType NoteProperty -Name $exceptionPropertyName -Value $exceptionProperties[$exceptionPropertyName] -Force;
    }
    if ($exceptionProperties.ContainsKey('json_Exception_StackTrace') -and $exceptionProperties['json_Exception_StackTrace'].Contains('LK.'))
    {
        $firstLKMethodOnStackTrace = $exceptionProperties['json_Exception_StackTrace'] -replace '.*?(LK\.[A-Za-z0-9\._]+).*','$1';
        Add-Member -InputObject $newObject -MemberType NoteProperty -Name 'firstLKMethodOnStackTrace' -Value $firstLKMethodOnStackTrace -Force;
    }
    return $newObject;
}

if (ShouldCareAbout $jsonCommit)
{
    $filter = "$(AtLeastEmptyString $filter) json.Commit:`"$jsonCommit`"";
}
if (ShouldCareAbout $jsonVertical)
{
    $filter = "$(AtLeastEmptyString $filter) json.Vertical:`"$jsonVertical`"";
}


$searchResult = ((Search $terms $filter $size $from $to) | ConvertFrom-Json);

$rsid = $searchResult."rsid"."id";

$eventsResult = GetEvents $rsid $columns $format;
if ($format -eq 'json')
{
     Write-Host "About to flatten Json properties..." -ForegroundColor Green;
     $eventsResult = [Linq.Enumerable]::Select(($eventsResult | ConvertFrom-Json).events, [Func[object,object]]{ 
        param($e); return flattenObject $e.event }) | ConvertTo-Json -Depth 16;
}
elseif (!($keepLogMsgColumn))
{
    Write-Host "About to clean up CSV properties..." -ForegroundColor Green;
    $eventsResult = RemoveLogMsg $eventsResult $format;
}
$end=get-date;
Write-Host "Done in $(($end-$start).Seconds) seconds" -ForegroundColor Green;

return $eventsResult;
