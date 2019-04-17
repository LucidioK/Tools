param(
    [Parameter(Mandatory=$True,  Position=0)][string]$topicName, # if you provide 'PleaseDoNotAdd', this script will only read and write the variable group.
    [Parameter(Mandatory=$True,  Position=1)][string]$subscriptionName,
    [Parameter(Mandatory=$False, Position=2)][string]$filter = '1=1' # or, for example "PaymentType=''PayPal''", do not forget the double quotes.
)

class topic
{
    [string]$topicName
    [string]$subscriptionName
    [string]$filter
}

pushd .
try
{
    cd (Resolve-Path (Join-Path $global:powerShellScriptDirectory '..'))
    $currentTopics             =  (.\GetVariable\bin\Debug\GetVariable.exe EGiftAPI-V2-CI-Invariants serviceBusTopicSubscriptionsFilters) | ConvertFrom-Json;
    if ($topicName -ne 'PleaseDoNotAdd')
    {
        $newTopic                  = New-Object -TypeName topic;
        $newTopic.topicName        = $topicName;
        $newTopic.subscriptionName = $subscriptionName;
        $newTopic.filter           = $filter;
        $currentTopics            += $newTopic;
    }
    $currentTopicsJson         = ($currentTopics | ConvertTo-Json -Compress).Replace('\u0027', "'");
    $currentTopicsJson         = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($currentTopicsJson));
    (.\SetVariable\bin\Debug\SetVariable.exe 'EGiftAPI-V2-CI-Invariants' 'serviceBusTopicSubscriptionsFilters' $currentTopicsJson)
}
finally
{
    popd
}

