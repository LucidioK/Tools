param(
    [parameter(Mandatory=$true,  Position=0)][int[]]   $Ids,
    [parameter(Mandatory=$true,  Position=1)][string[]]$Descriptions,
    [parameter(Mandatory=$false,  Position=2)][string]$SettingsFileName = "settings.json",
    [parameter(Mandatory=$false,  Position=3)][string[]]$Labels = ("none"),
    [parameter(Mandatory=$false,  Position=4)][string[]]$Sources = ("none"),
    [parameter(Mandatory=$false,  Position=5)][int]$repetitions = 1

) 

$startTime = [System.DateTime]::Now;
&(join-path $PSScriptRoot 'AzureUtils.ps1');

function main(
    [ValidateScript({$_ -ne $null -and $_ -gt 0})][int]$id, 
    [ValidateNotNullOrEmpty()][string]$description, 
    [ValidateNotNullOrEmpty()][string]$settingsFileName,
    [ValidateNotNullOrEmpty()][string]$label,
    [ValidateNotNullOrEmpty()][string]$source, 
    [bool]$mustConnectWithServiceBus)
{
    if ($mustConnectWithServiceBus)
    {
        global:azureConnectServiceBusTopicWithSettingsFile $settingsFileName;
    }

    if (-not ("GiftingComponentsAzure.IdDesc" -as [type]))
    {
        $class="namespace GiftingComponentsAzure
        {
            using System.Runtime.Serialization;
            [DataContract]
            public class IdDesc
            {
                [DataMember]
                public int Id { get; set; }
                [DataMember]
                public string Description { get; set; }
            }
        }";
        Add-Type -TypeDefinition $class -ReferencedAssemblies 'System.Runtime.Serialization.dll'; 
    }

    $idDesc             = [GiftingComponentsAzure.IdDesc]::new();
    $idDesc.Id          = $id;
    $idDesc.Description = $description;
    $brokeredMessage    = [Microsoft.ServiceBus.Messaging.BrokeredMessage]::new($idDesc);
    $brokeredMessage.SessionId = New-Guid;
    $brokeredMessage.Label = $label;
    $brokeredMessage.Properties['DataType'] = 'GiftingComponentsAzure.IdDesc';
    $brokeredMessage.Properties['source'] = $source;
    while (([system.DateTime]::now.Second % 5) -ne 0){}
    $global:TopicClient.Send($brokeredMessage);
}

function nth([object[]]$list, [int]$index)
{
    $index = $index % $list.Count;
    return $list[$index];
}

$firstRepetition = $true;
for ($i=0;$i -lt $repetitions;$i++)
{
    $id = nth $ids          $i;
    $id = $id + ($i * 1000);
    $de = nth $Descriptions $i;
    $la = nth $Labels       $i;
    $so = nth $Sources      $i;
    Write-Host "$id $de $SettingsFileName $la $so" -ForegroundColor Green;
    main $id $de $SettingsFileName $la $so $firstRepetition;
    $firstRepetition = $false;
}
$elapsed = ([System.DateTime]::Now - $startTime);
$milliseconds = $elapsed.TotalMilliseconds;
Write-Host "Done in $milliseconds milliseconds" -ForegroundColor Green;
