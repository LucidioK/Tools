<#
.SYNOPSIS
  Cmdlets to retrieve data from Loggly

.NOTES
  Please set the LogglyApiToken environment variable with the token from https://LK.loggly.com/account/users/api/tokens
#>

if ($env:LogglyApiToken -eq $null)
{
    write-host "`n`n`n";
    throw "Please set the LogglyApiToken environment variable with the token from https://LK.loggly.com/account/users/api/tokens";
}

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
    $result = Invoke-WebRequest -Headers @{ Authorization = "Bearer $($env:LogglyApiToken)" } -Uri $url;
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
    $originalO = $O;
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

function logglyFieldsApi
{
    param(
        [parameter(Mandatory=$false, Position=1)][string]$filter     = '*', #'json.Level:"Error" json.Commit:"b995211"',
        [parameter(Mandatory=$false, Position=2)][string]$from       = "-1d",
        [parameter(Mandatory=$false, Position=3)][string]$to         = "now",
        [parameter(Mandatory=$false, Position=4)][string]$fieldName  = 'json.Commit'
    )

    $url = "https://LK.loggly.com/apiv2/fields/$fieldName/?q=$filter&from=$from&until=$to";
    $result = Invoke-WebRequest -Headers @{ Authorization = "Bearer $($env:LogglyApiToken)" } -Uri $url;
    if ($result.StatusCode -ne 200)
    {
        throw "Search failed for $url";
    }
    return ($result.Content | ConvertFrom-Json);
}


<#
.SYNOPSIS
  Retrieves data from Loggly according to search parameters.
.DESCRIPTION
  Retrieves data from Loggly according to search parameters.
.PARAMETER <columns>
    Which columns to be retrieved. If nothing is provided, it will use json.Application,json.Cloud,http.clientHost,json.Exception,json.Commit.
    Inform '*' to return all columns.
.PARAMETER <terms>
    Search terms, separated by space. Defaults to 'InnerException StackTrace'.
    Inform '*' to search no terms..
.PARAMETER <filter>
    Filter, according to format described at https://www.loggly.com/docs/api-retrieving-data/.
    Defaults t $null.
.PARAMETER <size>
    How many items to be retrieved. Default is 1000, maximum is 5000.
.PARAMETER <from>
    Start of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is '-1d' (Last day).
.PARAMETER <to>
    End of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is 'now'.
.PARAMETER <jsonCommit>
    Optional parameter, shortcut to filter by commit.
.PARAMETER <jsonVertical>
    Optional parameter, shortcut to filter by vertical name.
.PARAMETER <jsonLevel>
    Optional parameter, shortcut to filter by json.Level. Default is 'Error'.
    Acceptable values are 'Error','Debug','Warning','Information','*'
.PARAMETER <keepLogMsgColumn>
    Switch to keep the column logmsg. Normally, logmsg is removed from the result.
.PARAMETER <format>
    Either csv or json.
    
    When using json, this script "flattens" the json output. 
    
    For instance, if an entry is like this:
        {
	        "json": {
		        "Exception": {
			        "StackTrace": "   at Amazon.Runtime.Internal.HttpErrorResponseExceptionHandler.HandleException(IExecutionContext executionContext, HttpErrorResponseException exception)\r\n   at Amazon.Runtime.Internal.ErrorHandler.ProcessException(IExecutionContext executionContext, Exception exception)\r\n   at Amazon.Runtime.Internal.ErrorHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.RetryHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.ErrorCallbackHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.MetricsHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.RuntimePipeline.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.AmazonServiceClient.Invoke[TRequest,TResponse](TRequest request, IMarshaller`2 marshaller, ResponseUnmarshaller unmarshaller)\r\n   at Amazon.Kinesis.AmazonKinesisClient.GetShardIterator(GetShardIteratorRequest request)\r\n   at PlayStreamConsumer.PlayStreamReader.GetShardIterator(String streamName, String shardId, String afterSequenceId) in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamConsumer\\PlayStreamReader.cs:line 190\r\n   at PlayStreamProcessor.ShardProcessorBase.SetStartingPoint(String streamName) in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamProcessor\\ShardProcessor.cs:line 336\r\n   at PlayStreamProcessor.VerticalShardProcessor.RunUntilCancelled() in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamProcessor\\ShardProcessor.cs:line 490\r\n   at LK.PlayStream.Processor.VerticalStreamProcessor.\u003c\u003ec__DisplayClass27_0.\u003cTryProcessShardToCompletionAsync\u003eb__0() in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamProcessor\\StreamProcessManager.cs:line 339\r\n   at System.Threading.Tasks.Task.Execute()",
			        "Message": "Rate exceeded for shard shardId-000000000000 in stream spi-playstream_live under account 773275573528.",
			        "Type": "Amazon.Kinesis.Model.ProvisionedThroughputExceededException",
			        "InnerExceptions": [{
					        "StackTrace": "   at Amazon.Runtime.Internal.HttpRequest.GetResponse()\r\n   at Amazon.Runtime.Internal.HttpHandler`1.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.Unmarshaller.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.ErrorHandler.InvokeSync(IExecutionContext executionContext)",
					        "Message": "The remote server returned an error: (400) Bad Request.",
					        "Type": "Amazon.Runtime.Internal.HttpErrorResponseException",
					        "InnerExceptions": [{
							        "StackTrace": "   at System.Net.HttpWebRequest.GetResponse()\r\n   at Amazon.Runtime.Internal.HttpRequest.GetResponse()",
							        "Message": "The remote server returned an error: (400) Bad Request.",
							        "Type": "System.Net.WebException"
						        }
					        ]
				        }
			        ]
		        },
		        "Ec2InstanceId": "i-08aa975df4ca62856",
		        "Vertical": "spi",
		        "Level": "Error",
		        "timestamp": "2019-03-11T21:13:37.3533815+00:00",
		        "ThreadName": "100",
		        "Application": "playstreamarchiver",
		        "Commit": "451edda",
		        "Message": "\"Failed during shard [{shardStatus.ShardId}] processing\"",
		        "Logger": "VerticalStreamProcessor",
		        "Cloud": "spi"
	        },
	        "http": {
		        "clientHost": "35.155.163.197",
		        "contentType": "application/json; charset=utf-8"
	        }
        }

    The resulting json will be like this:

    {
	    "http_clientHost": "35.155.163.197",
	    "http_contentType": "application/json; charset=utf-8",
	    "json_Application": "playstreamarchiver",
	    "json_Cloud": "spi",
	    "json_Commit": "451edda",
	    "json_Ec2InstanceId": "i-08aa975df4ca62856",
	    "json_Exception_Message": "Rate exceeded for shard shardId-000000000000 in stream spi-playstream_live under account 773275573528.",
	    "json_Exception_StackTrace": "   at Amazon.Runtime.Internal.HttpErrorResponseExceptionHandler.HandleException(IExecutionContext executionContext, HttpErrorResponseException exception)   at Amazon.Runtime.Internal.ErrorHandler.ProcessException(IExecutionContext executionContext, Exception exception)   at Amazon.Runtime.Internal.ErrorHandler.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.Internal.RetryHandler.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.Internal.ErrorCallbackHandler.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.Internal.MetricsHandler.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.Internal.RuntimePipeline.InvokeSync(IExecutionContext executionContext)   at Amazon.Runtime.AmazonServiceClient.Invoke[TRequest,TResponse](TRequest request, IMarshaller`2 marshaller, ResponseUnmarshaller unmarshaller)   at Amazon.Kinesis.AmazonKinesisClient.GetShardIterator(GetShardIteratorRequest request)   at PlayStreamConsumer.PlayStreamReader.GetShardIterator(String streamName, String shardId, String afterSequenceId) in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamConsumer\\PlayStreamReader.cs:line 190   at PlayStreamProcessor.ShardProcessorBase.SetStartingPoint(String streamName) in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamProcessor\\ShardProcessor.cs:line 336   at PlayStreamProcessor.VerticalShardProcessor.RunUntilCancelled() in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamProcessor\\ShardProcessor.cs:line 490   at LK.PlayStream.Processor.VerticalStreamProcessor.\u003c\u003ec__DisplayClass27_0.\u003cTryProcessShardToCompletionAsync\u003eb__0() in Z:\\jenkins-slave-vertical\\workspace\\update-application\\Server\\PlayStreamProcessor\\StreamProcessManager.cs:line 339   at System.Threading.Tasks.Task.Execute()",
	    "json_Exception_Type": "Amazon.Kinesis.Model.ProvisionedThroughputExceededException",
	    "firstLKMethodOnStackTrace": "LK.PlayStream.Processor.VerticalStreamProcessor.",
	    "json_Level": "Error",
	    "json_Logger": "VerticalStreamProcessor",
	    "json_Message": "\"Failed during shard [{shardStatus.ShardId}] processing\"",
	    "json_ThreadName": "100",
	    "json_timestamp": "2019-03-11T21:13:37.3533815+00:00",
	    "json_Vertical": "spi"
    }

    Notice that the exception data will always be from the innermost exception.



.OUTPUTS
  A string with the csv or json representation of the search results.
  
.EXAMPLE
  Loggly-Search 
  Will return all entries with terms 'InnerException StackTrace' in the last 24h

.EXAMPLE
  Loggly-Search -terms '*' -format csv -from -1h
  "19-03-11 21:03:38.162 -00:00","","a29e466","main","playstreameventanonymizer","34.213.208.16"
"19-03-11 21:03:38.162 -00:00","{'StackTrace': '   at Amazon.Runtime.Internal.HttpErrorResponseExceptionHandler.HandleException(IExecutionContext executionContext, HttpErrorResponseException exception)\r\n   at Amazon.Runtime.Internal.ErrorHandler.ProcessExc
eption(IExecutionContext executionContext, Exception exception)\r\n   at Amazon.Runtime.Internal.ErrorHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)\r\n  
 at Amazon.Runtime.Internal.RetryHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.CallbackHandler.InvokeSync(IExecutionCont
ext executionContext)\r\n   at Amazon.Runtime.Internal.ErrorCallbackHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.MetricsHandler.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.Runtime
Pipeline.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.AmazonServiceClient.Invoke[TRequest,TResponse](TRequest request, IMarshaller`2 marshaller, ResponseUnmarshaller unmarshaller)\r\n   at Amazon.SimpleNotificationService.AmazonSimp
leNotificationServiceClient.Publish(PublishRequest request)\r\n   at LK.Services.PushNotificationService.SendMessage(PublishRequest publishRequest, UInt64 notificationRecipient, UInt64 titleId, String pushNotificationTemplateId, String language) in Z:\\
master-node-workspace@2\\Server\\UberNetServices\\PushNotificationService.cs:line 696', 'Message': 'Invalid parameter: TargetArn Reason: No endpoint found for the target arn specified', 'Type': 'Amazon.SimpleNotificationService.Model.InvalidParameterExceptio
n', 'InnerExceptions': [{'StackTrace': '   at Amazon.Runtime.Internal.HttpRequest.GetResponse()\r\n   at Amazon.Runtime.Internal.HttpHandler`1.InvokeSync(IExecutionContext executionContext)\r\n   at Amazon.Runtime.Internal.Unmarshaller.InvokeSync(IExecutionC
ontext executionContext)\r\n   at Amazon.Runtime.Internal.ErrorHandler.InvokeSync(IExecutionContext executionContext)', 'Message': 'The remote server returned an error: (400) Bad Request.', 'Type': 'Amazon.Runtime.Internal.HttpErrorResponseException', 'Inner
Exceptions': [{'StackTrace': '   at System.Net.HttpWebRequest.GetResponse()\r\n   at Amazon.Runtime.Internal.HttpRequest.GetResponse()', 'Message': 'The remote server returned an error: (400) Bad Request.', 'Type': 'System.Net.WebException'}]}]}","a29e466","
main","queueprocessor","52.13.201.178"
"19-03-11 21:03:38.157 -00:00","","92e7c33","main","logicserver","34.216.170.167"
"19-03-11 21:03:38.157 -00:00","","92e7c33","main","logicserver","34.216.170.167"

.EXAMPLE
    Loggly-Search -terms '*' -format csv -from -15s -jsonLevel * -size 10 -columns 'json.Application,json.Cloud,http.clientHost,json.Exception,json.Commit,json.Level'
    Done in 0 seconds
    "timestamp","json.Level","json.Exception","json.Commit","json.Cloud","json.Application","http.clientHost"
    "19-03-11 21:05:56.050 -00:00","Information","","a29e466","main","playstreamrelaypublisher","34.213.208.16"
    "19-03-11 21:05:55.784 -00:00","Information","","a29e466","main","playstreamrelaypublisher","34.213.208.16"
    "19-03-11 21:05:54.206 -00:00","Debug","","a29e466","main","logicserver","34.216.170.167"
    "19-03-11 21:05:54.206 -00:00","Debug","","a29e466","main","logicserver","34.216.170.167"
    "19-03-11 21:05:54.016 -00:00","Debug","","a29e466","main","logicserver","34.213.208.16"
    "19-03-11 21:05:54.016 -00:00","Debug","","a29e466","main","logicserver","34.213.208.16"
    "19-03-11 21:05:54.016 -00:00","Debug","","a29e466","main","logicserver","34.213.208.16"
    "19-03-11 21:05:54.016 -00:00","Debug","","a29e466","main","logicserver","34.213.208.16"
    "19-03-11 21:05:54.016 -00:00","Debug","","a29e466","main","logicserver","34.213.208.16"
    "19-03-11 21:05:54.000 -00:00","Debug","","a29e466","main","logicserver","34.213.208.16"

.EXAMPLE
    Loggly-Search -terms '*' -format json -from -2d -jsonLevel Error -size 10 -columns '*'
    [
        {
            "http_clientHost":  "35.155.163.197",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "playstreamarchiver",
            "json_Cloud":  "spi",
            "json_Commit":  "451edda",
            "json_Ec2InstanceId":  "i-08aa975df4ca62856",
            "json_Level":  "Information",
            "json_Logger":  "ServiceActivatorBase",
            "json_Message":  "\"Deactivated service. LockName: spi-playstream_live_shardId-000000000000. ResourceId: event_archiver. ClientId: i-08aa975df4ca62856_SOME_GUID. VerticalStatus (Cloud: spi Region: us-west-2 SharedRegion: us
    -west-2 Vertical: spi Application: playstreamarchiver Commit: 451edda IsPrivateCloud: True). Instance = i-08aa975df4ca62856. Ready = False\"",
            "json_ThreadName":  "49",
            "json_timestamp":  "2019-03-11T21:09:02.5566489+00:00",
            "json_Vertical":  "spi"
        },
        {
            "http_clientHost":  "35.155.163.197",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "playstreamarchiver",
            "json_Cloud":  "spi",
            "json_Commit":  "451edda",
            "json_Ec2InstanceId":  "i-08aa975df4ca62856",
            "json_Level":  "Information",
            "json_Logger":  "ServiceActivatorBase",
            "json_Message":  "\"Activated service. LockName: spi-playstream_live_shardId-000000000000. ResourceId: event_archiver. ClientId: i-08aa975df4ca62856_SOME_GUID. VerticalStatus (Cloud: spi Region: us-west-2 SharedRegion: us-w
    est-2 Vertical: spi Application: playstreamarchiver Commit: 451edda IsPrivateCloud: True). Instance = i-08aa975df4ca62856. Ready = True.\"",
            "json_ThreadName":  "9",
            "json_timestamp":  "2019-03-11T21:09:02.5254331+00:00",
            "json_Vertical":  "spi"
        },
        {
            "http_clientHost":  "34.216.170.167",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "logicserver",
            "json_Cloud":  "main",
            "json_Commit":  "a29e466",
            "json_Ec2InstanceId":  "i-0efab65791c101d0f",
            "json_Level":  "Debug",
            "json_Logger":  "ScriptEngineManager",
            "json_Message":  "\"Loading 1 scripts into engine 197489 for title A4B5 revision 3\"",
            "json_ThreadName":  "137",
            "json_timestamp":  "2019-03-11T21:09:00.5789658+00:00",
            "json_Vertical":  "master"
        },
        {
            "http_clientHost":  "34.216.170.167",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "logicserver",
            "json_Cloud":  "main",
            "json_Commit":  "a29e466",
            "json_Ec2InstanceId":  "i-0efab65791c101d0f",
            "json_Level":  "Debug",
            "json_Logger":  "ScriptEngineManager",
            "json_Message":  "\"Initializing engine for title A4B5 revision 3\"",
            "json_ThreadName":  "137",
            "json_timestamp":  "2019-03-11T21:09:00.5633318+00:00",
            "json_Vertical":  "master"
        },
        {
            "http_clientHost":  "34.216.170.167",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "logicserver",
            "json_Cloud":  "main",
            "json_Commit":  "a29e466",
            "json_Ec2InstanceId":  "i-0efab65791c101d0f",
            "json_Level":  "Debug",
            "json_Logger":  "ScriptEngineManager",
            "json_Message":  "\"Making engine 197489 for title A4B5 revision 3\"",
            "json_ThreadName":  "137",
            "json_timestamp":  "2019-03-11T21:09:00.5633318+00:00",
            "json_Vertical":  "master"
        },
        {
            "http_clientHost":  "34.216.170.167",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "gamemanager",
            "json_Cloud":  "main",
            "json_Commit":  "92e7c33",
            "json_Ec2InstanceId":  "i-0b07175a2083c0fe8",
            "json_Level":  "Debug",
            "json_Logger":  "ProfileClient",
            "json_Message":  "\"Search Request Completed Debug: Successful low level call on POST: /combined-profiles/_search# Audit trail of this API call: - [1] HealthyResponse: Node: http://10.0.2.100:9200/ Took: 00:00:00.0156288# Request:\u003cRequest stream
     not captured or already read to completion by serializer. Set DisableDirectStreaming() on ConnectionSettings to force it to be set on the response.\u003e# Response:\u003cResponse stream not captured or already read to completion by serializer. Set DisableDi
    rectStreaming() on ConnectionSettings to force it to be set on the response.\u003e Audit: [{\\\"Event\\\":10,\\\"Started\\\":\\\"2019-03-11T21:09:00.3014595Z\\\",\\\"Ended\\\":\\\"2019-03-11T21:09:00.3170883Z\\\",\\\"Node\\\":{\\\"Uri\\\":\\\"http://10.0.2.1
    00:9200/\\\",\\\"IsResurrected\\\":false,\\\"HttpEnabled\\\":true,\\\"HoldsData\\\":true,\\\"MasterEligible\\\":true,\\\"IngestEnabled\\\":true,\\\"MasterOnlyNode\\\":false,\\\"ClientNode\\\":false,\\\"Id\\\":\\\"q5H_TRJKR5KwgS0Nby7t6w\\\",\\\"Name\\\":\\\"i
    -0ea1369b50de6c6bd\\\",\\\"Settings\\\":{\\\"bootstrap.memory_lock\\\":\\\"true\\\",\\\"client.type\\\":\\\"node\\\",\\\"cloud.aws.region\\\":\\\"us-west-2\\\",\\\"cloud.node.auto_attributes\\\":\\\"true\\\",\\\"cluster.name\\\":\\\"playstream_profiles\\\",\
    \\"cluster.routing.allocation.awareness.attributes\\\":\\\"aws_availability_zone\\\",\\\"discovery.ec2.groups.0\\\":\\\"sg-bda30fc5\\\",\\\"discovery.ec2.host_type\\\":\\\"private_ip\\\",\\\"discovery.zen.hosts_provider\\\":\\\"ec2\\\",\\\"discovery.zen.mini
    mum_master_nodes\\\":\\\"2\\\",\\\"discovery.zen.ping_timeout\\\":\\\"5s\\\",\\\"http.port\\\":\\\"9200\\\",\\\"http.type.default\\\":\\\"netty4\\\",\\\"network.host\\\":\\\"0.0.0.0\\\",\\\"network.publish_host\\\":\\\"_ec2:publicDns_\\\",\\\"node.attr.aws_a
    vailability_zone\\\":\\\"us-west-2c\\\",\\\"node.name\\\":\\\"i-0ea1369b50de6c6bd\\\",\\\"path.conf\\\":\\\"/etc/elasticsearch\\\",\\\"path.data.0\\\":\\\"/mnt\\\",\\\"path.home\\\":\\\"/usr/share/elasticsearch\\\",\\\"path.logs\\\":\\\"/var/log/elasticsearc
    h\\\",\\\"pidfile\\\":\\\"/var/run/elasticsearch/elasticsearch.pid\\\",\\\"thread_pool.bulk.queue_size\\\":\\\"5000\\\",\\\"transport.tcp.port\\\":\\\"9300\\\",\\\"transport.type.default\\\":\\\"netty4\\\",\\\"xpack.security.enabled\\\":\\\"false\\\"},\\\"Fa
    iledAttempts\\\":0,\\\"DeadUntil\\\":\\\"0001-01-01T00:00:00\\\",\\\"IsAlive\\\":true},\\\"Path\\\":\\\"combined-profiles/_search\\\",\\\"Exception\\\":null}]\"",
            "json_ThreadName":  "80",
            "json_timestamp":  "2019-03-11T21:09:00.3170883+00:00",
            "json_Vertical":  "master"
        },
        {
            "http_clientHost":  "52.13.201.178",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "logicserver",
            "json_Cloud":  "main",
            "json_Commit":  "a29e466",
            "json_Ec2InstanceId":  "i-03a0e4bfaeacae724",
            "json_Level":  "Debug",
            "json_Logger":  "ScriptEngineManager",
            "json_Message":  "\"Initializing engine for title 7E43A92 revision 1\"",
            "json_RequestId":  "003a628d393b4b36bf5f1694619c1c3d",
            "json_ThreadName":  "74",
            "json_timestamp":  "2019-03-11T21:09:00.2180104+00:00",
            "json_Vertical":  "master"
        },
        {
            "http_clientHost":  "34.213.208.16",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "playstreamrelaypublisher",
            "json_Cloud":  "main",
            "json_Commit":  "a29e466",
            "json_Ec2InstanceId":  "i-03a52beccbd5e4bf4",
            "json_Level":  "Warning",
            "json_Logger":  "RelayPublisher",
            "json_Message":  "\"Event is not EntityCustomEventData and will have null OriginalTimestamp, OriginalEventId and PublisherEntityKey fields. EventNamespace: com.LK EventName: entity_logged_in, EntityId :title_player_account!FC0E99D0DF2B1B2D Type:
     (PlayStreamEvents.LKEvents.EntityLoggedInEventData\"",
            "json_ThreadName":  "16",
            "json_timestamp":  "2019-03-11T21:09:00.1097769+00:00",
            "json_Vertical":  "master"
        },
        {
            "http_clientHost":  "34.216.170.167",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "logicserver",
            "json_Cloud":  "main",
            "json_Commit":  "a29e466",
            "json_Ec2InstanceId":  "i-0efab65791c101d0f",
            "json_Level":  "Debug",
            "json_Logger":  "ScriptEngineManager",
            "json_Message":  "\"Loading 1 scripts into engine 197488 for title 87D3 revision 654\"",
            "json_RequestId":  "78b700796ada41fe91730cfb100b11b4",
            "json_ThreadName":  "16",
            "json_timestamp":  "2019-03-11T21:08:59.8902466+00:00",
            "json_Vertical":  "master"
        },
        {
            "http_clientHost":  "34.216.170.167",
            "http_contentType":  "application/json; charset=utf-8",
            "json_Application":  "logicserver",
            "json_Cloud":  "main",
            "json_Commit":  "a29e466",
            "json_Ec2InstanceId":  "i-0efab65791c101d0f",
            "json_Level":  "Debug",
            "json_Logger":  "ScriptEngineManager",
            "json_Message":  "\"Initializing engine for title 87D3 revision 654\"",
            "json_RequestId":  "78b700796ada41fe91730cfb100b11b4",
            "json_ThreadName":  "16",
            "json_timestamp":  "2019-03-11T21:08:59.8902466+00:00",
            "json_Vertical":  "master"
        }
    ]

#>
function Loggly-Search
{
    [CmdletBinding()]
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

}


<#
.SYNOPSIS
  Retrieves value counts for a given column (field).
.DESCRIPTION
  Retrieves value counts for a given column (field).

.PARAMETER <filter>
    Filter, according to format described at https://www.loggly.com/docs/api-retrieving-data/.
    Defaults t $null.
.PARAMETER <from>
    Start of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is '-1d' (Last day).
.PARAMETER <to>
    End of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is 'now'.
.PARAMETER <fieldName>
    Field to be summarized. Default is json.Commit. Must be one of these:
            'http.clientHost',
            'http.contentType',
            'json.Application',
            'json.Cloud',
            'json.Commit',
            'json.Creator',
            'json.Ec2InstanceId',
            'json.Environment',
            'json.EventName',
            'json.Exception',
            'json.Level',
            'json.Logger',
            'json.MachineName',
            'json.Message',
            'json.ProcessId',
            'json.QueueName',
            'json.RequestId',
            'json.ThreadName',
            'json.TitleId',
            'json.Vertical',
            'json.configUrl',
            'json.response',
            'json.timestamp'

.OUTPUTS
  A dictionary (Hashtable) where the key is the field value and the value is the count.
  
.EXAMPLE
  Loggly-Search 
  Name                           Value                                                                                                                                                                                                                             
  ----                           -----                                                                                                                                                                                                                             
  0c285e7                        10                                                                                                                                                                                                                                
  7019f3f                        1752                                                                                                                                                                                                                              
  238163e                        439                                                                                                                                                                                                                               
  6daef1f                        24969                                                                                                                                                                                                                             
  d2c8566                        120516  

.EXAMPLE
  Loggly-GetFieldValueCount -from '-2h' -fieldName json.Cloud
    Name                           Value                                                                                                                                                                                                                             
    ----                           -----                                                                                                                                                                                                                             
    rblx                           2844                                                                                                                                                                                                                              
    devservices                    4244                                                                                                                                                                                                                              
    main                           809258                                                                                                                                                                                                                            
    serendipity                    158                                                                                                                                                                                                                               
    upr-usj                        1985                                                                                                                                                                                                                              
    matchmaking                    2676                                                                                                                                                                                                                              
    analytics                      35620                                                                                                                                                                                                                             
    prod.corematch.xboxlive.com    62                                                                                                                                                                                                                                
    china                          148                                                                                                                                                                                                                               
    gamemgr                        1744                                                                                                                                                                                                                              
    multiplayer                    1458                                                                                                                                                                                                                              
    upr-ush                        1963                                                                                                                                                                                                                              
    player-svcs                    8247                                                                                                                                                                                                                              
    data-svcs                      1314                                                                                                                                                                                                                              
    spi                            101972       

.EXAMPLE
    Loggly-GetFieldValueCount -from '-2d' -fieldName json.Cloud -filter 'json.Level:"Error" json.QueueName:"release_queue_v2"'

    Name                           Value                                                                                                                                                                                                                             
    ----                           -----                                                                                                                                                                                                                             
    prod.corematch.xboxlive.com    2         
#>

function Loggly-GetFieldValueCount 
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=1)][string]$filter     = '*', #'json.Level:"Error" json.Commit:"b995211"',
        [parameter(Mandatory=$false, Position=2)][string]$from       = "-1d",
        [parameter(Mandatory=$false, Position=3)][string]$to         = "now",
        [ValidateSet(
            'http.clientHost',
            'http.contentType',
            'json.Application',
            'json.Cloud',
            'json.Commit',
            'json.Creator',
            'json.Ec2InstanceId',
            'json.Environment',
            'json.EventName',
            'json.Exception',
            'json.Level',
            'json.Logger',
            'json.MachineName',
            'json.Message',
            'json.ProcessId',
            'json.QueueName',
            'json.RequestId',
            'json.ThreadName',
            'json.TitleId',
            'json.Vertical',
            'json.configUrl',
            'json.response',
            'json.timestamp')]
        [parameter(Mandatory=$false, Position=4)][string]$fieldName  = 'json.Commit'
    )
    $content = logglyFieldsApi $filter $from $to $fieldName;
    $dd = @{}; 
    foreach ($item in $content."$fieldName") { $dd[$item.term]=$item.count; }
    return $dd;
}


<#
.SYNOPSIS
  Retrieves distinct values from a given column (field).
.DESCRIPTION
  Retrieves distinct values from a given column (field).

.PARAMETER <filter>
    Filter, according to format described at https://www.loggly.com/docs/api-retrieving-data/.
    Defaults t $null.
.PARAMETER <from>
    Start of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is '-1d' (Last day).
.PARAMETER <to>
    End of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is 'now'.
.PARAMETER <fieldName>
    Field to be listed. Default is json.Commit. Must be one of these:
            'http.clientHost',
            'http.contentType',
            'json.Application',
            'json.Cloud',
            'json.Commit',
            'json.Creator',
            'json.Ec2InstanceId',
            'json.Environment',
            'json.EventName',
            'json.Exception',
            'json.Level',
            'json.Logger',
            'json.MachineName',
            'json.Message',
            'json.ProcessId',
            'json.QueueName',
            'json.RequestId',
            'json.ThreadName',
            'json.TitleId',
            'json.Vertical',
            'json.configUrl',
            'json.response',
            'json.timestamp'

.OUTPUTS
  A list with the distict values.
  
.EXAMPLE
    Loggly-GetFieldValues 
    a29e466
    451edda
    47c7c73
    f3f6a18
    92e7c33
    a06dfb1
    b781207
    83e1469
    84ab783

.EXAMPLE
    Loggly-GetFieldValues -from '-2h' -fieldName json.Cloud
    main
    spi
    analytics
    player-svcs
    devservices
    rblx
    matchmaking
    upr-usj
    upr-ush
    gamemgr
    multiplayer
    data-svcs
    serendipity
    china
    prod.corematch.xboxlive.com     

.EXAMPLE
     Loggly-GetFieldValues -from '-2d' -fieldName json.Cloud -filter 'json.Level:"Error" json.QueueName:"release_queue_v2"'
    prod.corematch.xboxlive.com       
#>
function Loggly-GetFieldValues 
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=1)][string]$filter     = '*', #'json.Level:"Error" json.Commit:"b995211"',
        [parameter(Mandatory=$false, Position=2)][string]$from       = "-1d",
        [parameter(Mandatory=$false, Position=3)][string]$to         = "now",
        [ValidateSet(
            'http.clientHost',
            'http.contentType',
            'json.Application',
            'json.Cloud',
            'json.Commit',
            'json.Creator',
            'json.Ec2InstanceId',
            'json.Environment',
            'json.EventName',
            'json.Exception',
            'json.Level',
            'json.Logger',
            'json.MachineName',
            'json.Message',
            'json.ProcessId',
            'json.QueueName',
            'json.RequestId',
            'json.ThreadName',
            'json.TitleId',
            'json.Vertical',
            'json.configUrl',
            'json.response',
            'json.timestamp')]
        [parameter(Mandatory=$false, Position=4)][string]$fieldName  = 'json.Commit'
    )
    $content = logglyFieldsApi $filter $from $to $fieldName;
    return ($content."$fieldName" | select -ExpandProperty term);
}


<#
.SYNOPSIS
  Calculates the percentage of non-error events in loggly.
.DESCRIPTION
  Calculates the percentage of non-error events in loggly.
.PARAMETER <filter>
    Filter, according to format described at https://www.loggly.com/docs/api-retrieving-data/.
    Defaults t $null.
.PARAMETER <from>
    Start of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is '-1d' (Last day).
.PARAMETER <to>
    End of search period, using loggly notation as described here: https://www.loggly.com/docs/search-query-language/#time.
    Default is 'now'.
.PARAMETER <jsonCommit>
    Optional parameter, shortcut to filter by commit.
.PARAMETER <jsonVertical>
    Optional parameter, shortcut to filter by vertical name.
.OUTPUTS
  A (double) number from 0 to 100. 100 meaning that all events were non-error, 0 meaning all events were error events.
  
.EXAMPLE
    Loggly-GetHealthIndex
    89.1083673844154

    In the last 24h, on all verticals and all clouds, 89% of all events were non-error.

.EXAMPLE
    Loggly-GetHealthIndex
    89

    In the last 24h, on all verticals and all clouds, 89% of all events were non-error.

.EXAMPLE
    Loggly-GetHealthIndex -jsonCommit 63db5cc
    30.5084745762712

    Only 31% of events related to commit 63db5cc were healthy.

.EXAMPLE
    Loggly-GetFieldValues -fieldName json.Vertical -from '-2h' | foreach { write-host "$_ $(Loggly-GetHealthIndex -jsonVertical $_ -from '-2h')" }

    master 98.5588454189197
    spi 66.8677290057679
    low 99.6085313174946
    analytics 30.0414287313851
    p-idle-miner 99.9959395809648
    p-battlelands 100
    p-b009 100
    p-5449 99.9882103277529
    analytics-exp 100
    player-svcs 82.6138379657008
    p-adcap 99.9531725591197
    emoji 99.9729217438397
    player-svcs-fbig 80.0111513799833
    p-stickman 99.9692496924969
    rblx 98.5232067510549
    matchmaking-stress 74.0333451578574
    p-dd9 100
    devservices 99.0321057601511
    p-d401 99.5699952221691
     
#>
function Loggly-GetHealthIndex
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=1)][string]$filter     = '*', #'json.Level:"Error" json.Commit:"b995211"',
        [parameter(Mandatory=$false, Position=2)][string]$from       = "-1d",
        [parameter(Mandatory=$false, Position=3)][string]$to         = "now",
        [parameter(Mandatory=$false, Position=6)][string]$jsonCommit = $null,
        [parameter(Mandatory=$false, Position=7)][string]$jsonVertical = $null
    )

    if (ShouldCareAbout $jsonCommit)
    {
        $filter = "$(AtLeastEmptyString $filter) json.Commit:`"$jsonCommit`"";
    }
    if (ShouldCareAbout $jsonVertical)
    {
        $filter = "$(AtLeastEmptyString $filter) json.Vertical:`"$jsonVertical`"";
    }

    $url = "https://LK.loggly.com/apiv2/fields/json.Level/?q=$filter&from=$from&until=$to";

    $result = Invoke-WebRequest -Headers @{ Authorization = "Bearer $($env:LogglyApiToken)" } -Uri $url;
    if ($result.StatusCode -ne 200)
    {
        throw "Search failed...";
    }
    $content = $result.Content | ConvertFrom-Json;
    [double]$totalEvents = $content.total_events;
    [double]$errorEvents = [linq.enumerable]::Where($content.'json.Level', [Func[object, bool]]{param ($l); return $l.term -eq 'Error';}) | select -ExpandProperty count;

    [double]$healthIndex = (($totalEvents - $errorEvents) * 100) / $totalEvents;

    return $healthIndex;
}
