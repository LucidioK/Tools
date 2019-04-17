param(
    [parameter(Mandatory=$true,  Position=0)][object]$Object,
    [parameter(Mandatory=$false, Position=1)][string]$SettingsFileName = $null, # = "settings.json",
    [parameter(Mandatory=$false, Position=2)][string]$ConnectionString = $null, # = "Endpoint=sb://svbdeleteme.servicebus.windows.net/;SharedAccessKeyName=AuthorizationRules_RootManageSharedAccessKey_name;SharedAccessKey=b7Yilyxsgv2QxN2LyIP/b0nJhecgTUGgSIm5S1fXA+o=",
    [parameter(Mandatory=$false, Position=2)][string]$TopicName        = $null, # = "anytopic",
    [parameter(Mandatory=$false, Position=3)][string]$OptionalLabel    = ""
) 

if ($SettingsFileName -ne $null -and $SettingsFileName.Length -ne 0 -and $ConnectionString -ne $null -and $ConnectionString.Length -ne 0)
{
    throw 'You must either provide SettingsFileName or ConnectionString, not both.';
}

if ($ConnectionString -ne $null -and $TopicName -eq $null)
{
    throw 'You must provide a TopicName when you use ConnectionString.';
}

$startTime = [System.DateTime]::Now;
&(join-path $PSScriptRoot 'AzureUtils.ps1');

function main(
    [ValidateNotNull()][object]$object, 
    [ValidateNotNull()][object]$topiClient)
{

    $serializedObject            = ConvertTo-Json -Compress $object;
    $brokeredMessage             = [Microsoft.ServiceBus.Messaging.BrokeredMessage]::new($serializedObject);
    $id                          = (New-Guid).ToString();
    $brokeredMessage.SessionId   = $id;
    $brokeredMessage.CorrelationId = $id;
    $brokeredMessage.ContentType = 'application/json';
    if ($OptionalLabel.Length -gt 0)
    {
        $brokeredMessage.Label = $OptionalLabel;
    }
    $global:TopicClient.Send($brokeredMessage);
}

$topicClient = $null;

if ($settingsFileName -ne $null -and $SettingsFileName.Length -ne 0)
{
    global:azureConnectServiceBusTopicWithSettingsFile $settingsFileName;
    $topicClient = $global:TopicClient;
}
if ($ConnectionString -ne $null -and $ConnectionString.Length -ne 0)
{
    $factory = [Microsoft.ServiceBus.Messaging.MessagingFactory]::CreateFromConnectionString($ConnectionString);
    $topicClient = $factory.CreateTopicClient($TopicName);
}

if ($topicClient -eq $null)
{
    throw 'Please provide either SettingsFileName or ConnectionString and TopicName.';
}

main $Object $topicClient;
$elapsed = ([System.DateTime]::Now - $startTime);
$milliseconds = $elapsed.TotalMilliseconds;
Write-Host "Done in $milliseconds milliseconds" -ForegroundColor Green;
