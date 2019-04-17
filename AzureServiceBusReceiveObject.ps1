param(
    [parameter(Mandatory=$false,  Position=0)][string]$SettingsFileName = "settings.json",
    [parameter(Mandatory=$false,  Position=1)][int]   $repetitions      = 1, # use -1 for infinite
    [parameter(Mandatory=$false,  Position=2)][string]$subscriptionName = $null # use $null for settings.topicSubscription
) 


$startTime = [System.DateTime]::Now;
&(join-path $PSScriptRoot 'AzureUtils.ps1');

function shouldRepeat($count)
{
    return ($count -ne 0);
}

function tryReadContentWithType([Microsoft.ServiceBus.Messaging.BrokeredMessage]$message, [string]$typeFullName)
{
    Write-Host "Trying to get body as $typeFullName..." -ForegroundColor Green;
    $clonedMessage  = $message.Clone();
    $BindingFlags   = [Reflection.BindingFlags] "Public,Instance";
    $contentType    = ($typeFullName -as [Type]);
    $getBody_method = $clonedMessage.GetType().GetMethod("GetBody",$BindingFlags,$null, @(),$null).MakeGenericMethod($contentType);
    $content = $getBody_method.Invoke($clonedMessage,$null);

    return $content;
}

function readContent([Microsoft.ServiceBus.Messaging.BrokeredMessage]$message)
{
    $messageSequeceNumber = $message.SequenceNumber;
    Write-Host "Reading content from message # $($message.SequenceNumber) Enqueued # $($message.EnqueuedSequenceNumber) Enqueued Time UTC $($message.EnqueuedTimeUtc.ToLocalTime())." -ForegroundColor Green;
    $content = $null;
    try
    {
        $content = tryReadContentWithType $message "string";
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        $clonedMessage = 
        [string]$errorMessage   = $_.Exception.Message;
        $namespaceStartPosition = $errorMessage.LastIndexOf("/") + 1;
        $namespace              = $errorMessage.Substring($namespaceStartPosition);
        $namespaceEndPosition   = $namespace.IndexOf("'");
        $namespace              = $namespace.Substring(0, $namespaceEndPosition);
        $withName               = "with name '";
        $typeNameStartPosition  = $errorMessage.IndexOf($withName) + $withName.Length;
        $typeName               = $errorMessage.Substring($typeNameStartPosition);
        $typeNameEndPosition    = $typeName.IndexOf("'");
        $typeName               = $typeName.Substring(0, $typeNameEndPosition);

        $typeName               = "$namespace.$typeName";
        $content                =  tryReadContentWithType $message $typeName;
    }
    if ($content -ne $null)
    {
        $message.Complete();
        return $content | ConvertTo-Json;
    }
    return $null;
}

$global:lastBrokeredMessages = @();

function main(
    [ValidateNotNullOrEmpty()][string]$settingsFileName, [string]$subscriptionName)
{
    if ($subscriptionName -eq $null)
    {
        $subscriptionName = $Global:settings.topicSubscription;
    }
    $timeout = [System.TimeSpan]::FromSeconds($timeoutSeconds);
    global:azureConnectServiceBusTopicWithSettingsFile $settingsFileName;
    $message        = global:azureReceiveServiceBusTopicMessage;
    $global:lastBrokeredMessage = $message;
    $content        = readContent $message;
    Write-Output $content;
}

while (shouldRepeat $repetitions)
{
    main $SettingsFileName;
    while (([System.DateTime]::Now.Second % 10) -ne 0){}
    if ($repetitions -gt 0)
    {
        $repetitions--;
    }
}

$elapsed = ([System.DateTime]::Now - $startTime);

Write-Host "Done in $milliseconds milliseconds" -ForegroundColor Green;


