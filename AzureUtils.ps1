pushd .
cd $PSScriptRoot
    $requiredDlls = @(
        "Microsoft.WindowsAzure.Storage.dll",
        "Microsoft.Data.Services.Client.dll",
        "Microsoft.Azure.Documents.Client.dll",
        "Newtonsoft.Json.dll",
        "Microsoft.Data.Edm.dll",
        "Microsoft.Data.OData.dll",
        "Microsoft.OData.Core.dll",
        "Microsoft.OData.Edm.dll",
        "Microsoft.Spatial.dll",
        "Microsoft.Azure.KeyVault.Core.dll",
        "System.Spatial.dll");

    foreach ($dll in $requiredDlls)
    {
        [System.Reflection.Assembly]::LoadFile((Join-Path $PSScriptRoot $dll)) | Out-Null;
    }
popd

# ----------------- Az module compatible below

function Get-AzCachedAccessToken()
{
    $ErrorActionPreference = 'Stop';
  
    if(-not (Get-Module Az.Accounts)) {
        Import-Module Az.Accounts;
    }
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
    if(-not $azProfile.Accounts.Count) {
        Write-Error "Ensure you have logged in before calling this function.";
    }
  
    $currentAzureContext = Get-AzContext;
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile);
    Write-Debug ("Getting access token for tenant" + $currentAzureContext.Tenant.TenantId);
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId);
    $token.AccessToken
}

function Get-AzBearerToken()
{
    $ErrorActionPreference = 'Stop';
    ('Bearer {0}' -f (Get-AzCachedAccessToken));
}


# ----------------- AzureRM module compatible below

function Get-AzureRmCachedAccessToken()
{
    $ErrorActionPreference = 'Stop';
  
    if(-not (Get-Module AzureRm.Profile)) {
        Import-Module AzureRm.Profile;
    }
    $azureRmProfileModuleVersion = (Get-Module AzureRm.Profile).Version;
    # refactoring performed in AzureRm.Profile v3.0 or later
    if($azureRmProfileModuleVersion.Major -ge 3) {
        $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
        if(-not $azureRmProfile.Accounts.Count) {
            Write-Error "Ensure you have logged in before calling this function."    ;
        }
    } else {
        # AzureRm.Profile < v3.0
        $azureRmProfile = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile;
        if(-not $azureRmProfile.Context.Account.Count) {
            Write-Error "Ensure you have logged in before calling this function."    ;
        }
    }
  
    $currentAzureContext = Get-AzureRmContext;
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
    Write-Debug ("Getting access token for tenant" + $currentAzureContext.Tenant.TenantId);
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId);
    $token.AccessToken;
}

function Get-AzureRmBearerToken()
{
    $ErrorActionPreference = 'Stop'
    ('Bearer {0}' -f (Get-AzureRmCachedAccessToken))
}


function global:getLatestBuildArtifacts([string]$accessToken, [string]$vstsProjectUri, [string]$buildDefinitionName, [string]$outputFolder)
{
    $def = global:getBuildDefinition $accessToken $vstsProjectUri $buildDefinitionName;
    $defId = $def.value.id;
    $builds = global:getBuilds $accessToken $vstsProjectUri $defId;
    $latestBuild = $builds.value[0].id;
    global:getBuildArtifacts $accessToken $vstsProjectUri $latestBuild $outputFolder;
}

function global:getBuildDefinition([string]$accessToken, [string]$vstsProjectUri, [string]$buildDefinitionName)
{
    $vstsProjectUri = $vstsProjectUri.TrimEnd("/");
    $headers = global:basicAuthHeader "" $accessToken;
    $uri = "$vstsProjectUri/_apis/build/definitions?api-version=2.0&name=$buildDefinitionName"
    $buildDef = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get | ConvertTo-Json | ConvertFrom-Json;
    return $buildDef;
}

function global:getBuildDefinitions([string]$accessToken, [string]$vstsProjectUri)
{
    $vstsProjectUri = $vstsProjectUri.TrimEnd("/");
    $headers = global:basicAuthHeader "" $accessToken;
    $uri = "$vstsProjectUri/_apis/build/definitions?api-version=2.0"
    $buildDef = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get | ConvertTo-Json | ConvertFrom-Json;
    return $buildDef.value;
}

function global:getBuilds([string]$accessToken, [string]$vstsProjectUri, [string]$buildDefinitionId)
{
    $vstsProjectUri = $vstsProjectUri.TrimEnd("/");
    $headers = global:basicAuthHeader "" $accessToken;
    $uri = "$vstsProjectUri/_apis/build/builds/?api-version=2.0&definitions=$buildDefinitionId&statusFilter=succeeded";
    $builds = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get  | ConvertTo-Json | ConvertFrom-Json;
    return $builds;
}

function global:getBuildArtifacts([string]$accessToken, [string]$vstsProjectUri, [string]$buildId, [string]$outputFolder)
{
    $vstsProjectUri = $vstsProjectUri.TrimEnd("/");
    $headers = global:basicAuthHeader "" $accessToken;
    $uri = "$vstsProjectUri/_apis/build/builds/$buildId/Artifacts?api-version=2.0";
    [Array] $artifacts = (Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get | ConvertTo-Json -Depth 3 | ConvertFrom-Json).value

    # Process all artifacts found.
    foreach ($artifact in $artifacts)
    {
        $artifactName = "$($artifact.name)";
        $artifactZip = "$artifactName.zip";
        Write-Host "Preparing to download artifact $artifactName to file $artifactZip";

        $downloadUrl = $artifact.resource.downloadUrl;
        if (-not $downloadUrl)
        {
            throw "Unable to get the download URL for artifact $artifactName.";
        }

        $outfile = "$outputFolder\$artifactZip";

        Write-Host "Downloading artifact $artifactName from $downloadUrl to $outfile";
        Invoke-RestMethod -Uri "$downloadUrl" -Headers $Headers -Method Get -Outfile $outfile | Out-Null;
    }
}

function global:azureInstallCosmosDBIfNeeded()
{
    if ((Get-Module -Name 'CosmosDB') -eq $null)
    {
        Install-Module -Name CosmosDB;
    }
}

function global:azureGetCosmosContextByConnectionString([string]$connectionString)
{
    $cosmosDbName      = global:extractWithRegex $connectionString 'https://([a-z0-9]+?)\.documents\.azure\.com';
    $accountKey        = global:extractWithRegex $connectionString 'AccountKey=(.*?);';
    $accountKeySecret  = ConvertTo-SecureString -String $accountKey -AsPlainText -Force;
    #$resourceGroupName = (get-azurermresource -name $cosmosDbName).ResourceGroupName;
    $databaseName      = ('parsing' +  $cosmosDbName.Replace('uswddb0','').Replace('pars',''));
    $context           = New-CosmosDbContext -Account $cosmosDbName -Key $accountKeySecret -Database $databaseName;
    return $context;
}


function global:azureGetCosmosDocument([CosmosDB.Context]$context, [string]$databaseName, [string]$key)
{
    return get-cosmosdbdocument -Context $context -CollectionId $databaseName  -PartitionKey ($key);
}

function global:azureGetCosmosCollection([CosmosDB.Context]$context, [string]$databaseName)
{
    $docs = get-cosmosdbdocument -Context $context -CollectionId $databaseName;
    $docs = $docs.GetEnumerator() | Sort-Object -Property Timestamp -Descending;
    return $docs;
}

#function global:azureGetCosmosDocumentById([string]
#get-cosmosdbdocument -Context $ctx -CollectionId parsOrders


$global:PeekServiceBusAlreadyDefined = $false;
function global:azurePeekAllServiceBusTopicSubscription([string]$connectionString, [string]$topicName, [string]$subscriptionName)
{
    if (!($global:PeekServiceBusAlreadyDefined))
    {
        $class =
@"
namespace PeekServiceBus2
{
    using Microsoft.ServiceBus.Messaging;
    using System.Collections.Generic;
    public class BMStr
    {
        public string ReplyToSessionId { get; set; }
        public int DeliveryCount { get; set; }
        public string DeadLetterSource { get; set; }
        public System.DateTime ExpiresAtUtc { get; set; }
        ///public System.DateTime LockedUntilUtc { get; set; }
        //public System.Guid LockToken { get; set; }
        public string MessageId { get; set; }
        public string ContentType { get; set; }
        public string PartitionKey { get; set; }
        public string ViaPartitionKey { get; set; }
        public string ReplyTo { get; set; }
        public IDictionary<string, object> Properties { get; set; }
        public string SessionId { get; set; }
        public System.DateTime EnqueuedTimeUtc { get; set; }
        public System.DateTime ScheduledEnqueueTimeUtc { get; set; }
        public long SequenceNumber { get; set; }
        public long EnqueuedSequenceNumber { get; set; }
        public long Size { get; set;  }
        public MessageState State { get; set;  }
        public System.TimeSpan TimeToLive { get; set; }
        public string To { get; set; }
        public string Label { get; set; }
        public string CorrelationId { get; set; }
        public bool ForcePersistence { get; set; }
        public bool IsBodyConsumed { get; set;  }

        public BMStr(BrokeredMessage brokeredMessage)
        {
            Body = Newtonsoft.Json.JsonConvert.DeserializeObject<dynamic>(brokeredMessage.Clone().GetBody<string>());

            foreach (var pthis in this.GetType().GetProperties())
            {
                System.Reflection.PropertyInfo pbm;
                if ((pbm = brokeredMessage.GetType().GetProperty(pthis.Name)) != null)
                {
                    pthis.SetValue(this, pbm.GetValue(brokeredMessage));
                }
            }
        }

        public dynamic Body { get; set; }
    }
    public class PeekServiceBus
    {
        private MessagingFactory _messagingFactoryInternal;

        public PeekServiceBus(string connectionString)
        {
            _messagingFactoryInternal = MessagingFactory.CreateFromConnectionString(connectionString);
        }

        public List<BMStr> PeekAllMessagesFromTopicAndSubscription(string topicName, string subscriptionName)
        {
            var subscriptionClient = _messagingFactoryInternal.CreateSubscriptionClient(topicName, subscriptionName);
            BrokeredMessage m;
            var ms = new List<BMStr>();
            while ((m = subscriptionClient.Peek()) != null)
            {
                ms.Add(new BMStr(m));
            }
            return ms;
        }
    }
}
"@;
        Add-Type $class -ReferencedAssemblies ("Microsoft.ServiceBus", "System.xml", "Newtonsoft.Json");
        $global:PeekServiceBusAlreadyDefined = $true;
    }
    $peeker = [PeekServiceBus2.PeekServiceBus]::new($connectionString);
    return $peeker.PeekAllMessagesFromTopicAndSubscription($topicName, $subscriptionName);
}




function global:azureAddSubscriptionFilter([Microsoft.ServiceBus.Messaging.SubscriptionClient]$subscriptionClient = $global:subscriptionClient, [string]$ruleName, [string]$sqlFilterText)
{
    $sqlFilter = [Microsoft.ServiceBus.Messaging.SqlFilter]::new($sqlFilterText);
    $subscriptionClient.AddRule($ruleName, $sqlFilter);
}

function global:azureReceiveServiceBusTopicMessage()
{
    if ($global:azureReceiveServiceBusTopicMessageReceiveMessageDefined -eq $null)
    {
        $class = @"
namespace azureReceiveServiceBusTopicMessage6
{
    using Microsoft.ServiceBus.Messaging;
    using System.Threading;
    using Newtonsoft.Json;
    public class ReceiveMessage
    {
        public static BrokeredMessage Receive(SubscriptionClient client, int timeout)
        {
            AutoResetEvent waitEvent = new AutoResetEvent(false);
            BrokeredMessage message = null;
            client.OnMessage(m => { message = m.Clone(); waitEvent.Set(); }, new OnMessageOptions());
            waitEvent.WaitOne(timeout);
            return message;
        }

    }
}
"@;
        Add-Type  $class -ReferencedAssemblies ((Join-Path $PSScriptRoot 'Microsoft.ServiceBus.dll'), "System.Xml.dll", (Join-Path $PSScriptRoot 'Newtonsoft.Json.dll')) -ErrorAction Stop;
        $global:azureReceiveServiceBusTopicMessageReceiveMessageDefined = $true;
    }
    global:azureReopenTopicSubscriptionClient;
    $message = [azureReceiveServiceBusTopicMessage6.ReceiveMessage]::Receive($global:subscriptionClient, 30000);
    return $message;
}

function global:getAzureStorageTable([string]$resourceGroup,[String]$databaseName,[String]$tableName)
{
    $keys = Invoke-AzureRmResourceAction -Action listKeys -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroup -Name $databaseName -Force;

    if ($keys -eq $null)
    {
        throw "Cosmos DB Database $databaseName didn't return any keys.";
    }

    $connString = [string]::Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1};TableEndpoint=https://{0}.documents.azure.com",$databaseName,$keys.primaryMasterKey);

    $storage = [Microsoft.WindowsAzure.Storage.CloudStorageAccount]::Parse($connString);                                                

    $tableClient = $storage.CreateCloudTableClient();                                                                                  
                
    #[Microsoft.WindowsAzure.Storage.Table.CloudTable]$table = [Microsoft.WindowsAzure.Storage.Table.CloudTable]$tableClient.GetTableReference($tableName);
    $table = $tableClient.GetTableReference($tableName);

    if ($table -eq $null)
    {
        throw "Table $tableName could not be retrieved from Cosmos DB database name $databaseName on resource group $resourceGroupName";
    }

    return $table;
}

function global:queryCosmosDb(
        [String]$EndPoint = 'https://DB_NAME.documents.azure.com:443/', 
        [String]$DataBaseId = 'DB_NAME', 
        [String]$CollectionId = 'COLLECTION', 
        [String]$MasterKey,  
        [String]$Query = 'select * from Root') 
{
    $ResourceType = "docs"; 
    $ResourceLink = "dbs/$DatabaseId/colls/$CollectionId" 
 
    $dateTime = [DateTime]::UtcNow.ToString("r") 
    $authHeader = global:generateMasterKeyAuthorizationSignature "POST" $ResourceLink  "docs" $dateTime $MasterKey "master" "1.0" 
    $queryJson = @{query=$Query} | ConvertTo-Json 
    $header = @{authorization=$authHeader;"x-ms-documentdb-isquery"="True";"x-ms-version"="2017-02-22";"x-ms-date"=$dateTime} 
    $contentType= "application/query+json" 
    $queryUri = "$EndPoint$ResourceLink/docs" 
 
    $result = Invoke-RestMethod -Method "POST" -ContentType $contentType -Uri $queryUri -Headers $header -Body $queryJson ;
 
    $result | ConvertTo-Json -Depth 10 
<#
    [Void][Reflection.Assembly]::LoadWithPartialName('Microsoft.Azure.DocumentDB');
    $reader = [Microsoft.Azure.Documents.Client.DocumentClient]::new($EndPoint, $MasterKey);
#>
}

Function global:generateMasterKeyAuthorizationSignature 
    ( 
        [Parameter(Mandatory=$true)][String]$verb, 
        [Parameter(Mandatory=$true)][String]$resourceLink, 
        [Parameter(Mandatory=$true)][String]$resourceType, 
        [Parameter(Mandatory=$true)][String]$dateTime, 
        [Parameter(Mandatory=$true)][String]$key, 
        [Parameter(Mandatory=$true)][String]$keyType, 
        [Parameter(Mandatory=$true)][String]$tokenVersion 
    ) 
{ 
 
    $hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256 
    $hmacSha256.Key = [System.Convert]::FromBase64String($key) 
 
    $payLoad = "$($verb.ToLowerInvariant())`n$($resourceType.ToLowerInvariant())`n$resourceLink`n$($dateTime.ToLowerInvariant())`n`n" 
    $hashPayLoad = $hmacSha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($payLoad)) 
    $signature = [System.Convert]::ToBase64String($hashPayLoad); 
 
    [System.Web.HttpUtility]::UrlEncode("type=$keyType&ver=$tokenVersion&sig=$signature") 
} 

Function global:registerResourceProvider([string]$ResourceProviderNamespace)
{
    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

function global:addType([string]$classDefinition, [string]$classFullName, [string[]]$referencedAssemblies)
{
    if (-not ($classFullName -as [type]))
    {
        $outputAssembly = (Join-Path $PSScriptRoot "$classFullName.dll");
        if (Test-Path $outputAssembly)
        {
            Import-Module $outputAssembly;
        }
        if (-not ($classFullName -as [type]))
        {
            if ($referencedAssemblies -eq $null -or $referencedAssemblies.Count -eq 0)
            {
                add-type -TypeDefinition $class -IgnoreWarnings -OutputAssembly $outputAssembly;
            }
            else
            {
                add-type -TypeDefinition $class -IgnoreWarnings -OutputAssembly $outputAssembly -ReferencedAssemblies $referencedAssemblies;
            }
        }
    }
}

function global:importModuleIfNeeded([ValidateNotNullOrEmpty()][string]$moduleName)
{
    if ($global:importedModulesInImportModuleIfNeeded -eq $null)
    {
        $global:importedModulesInImportModuleIfNeeded = @();
    }
    if ($global:importedModulesInImportModuleIfNeeded.Contains($moduleName.ToUpperInvariant()))
    {
        return $null;
    }
    $start = get-date;
    $gm = Get-Module -Name $moduleName;
    $job = $null;
    if ($gm -eq $null)
    {
        Write-Host "Importing module $moduleName,this might take some time..." -ForegroundColor Green;
        $job = Start-Job { Import-Module -Name $moduleName };
    }
    $now = Get-Date;
    $elapsed = (($now - $start).TotalMilliSeconds -as [int]).ToString().PadLeft(5);
    write-host "Elapsed $elapsed ms" -ForegroundColor Magenta;
    $global:importedModulesInImportModuleIfNeeded += $moduleName.ToUpperInvariant();
    return $job;
}

function global:importModules([string[]]$moduleNames)
{
    $jobs = @();
    foreach ($moduleName in $moduleNames)
    {
        $job = global:importModuleIfNeeded $moduleName;
        if ($job -ne $null)
        {
            $jobs = $jobs + $job;
        }
    }
    return $jobs;
}

function global:importAzureModules()
{
    Write-Host "Importing modules..." -ForegroundColor Green;
    $global:ImportAzureModulesJobs = global:importModules (
        'Azure',
        'Azure.Storage',
        'AzureRM',
        'AzureRM.Profile',
        'AzureRM.Resources',
        'AzureRM.ServiceBus',
        'AzureRm.ApiManagement',
        'AzureRm.Storage',
        'AzureRmStorageTable');
    Import-Module (join-path $PSScriptRoot 'Microsoft.ServiceBus.dll');
    Write-Host "Done with importing modules." -ForegroundColor Green;
}
 
function global:azureLoginIfNeeded([ValidateNotNullOrEmpty()][string]$subscription = $global:settings.subscription) 
{
    $loggedIn = $false;
    if ($global:AzureAccount -eq $null)  
    {
        try
        {
            Write-Host "Connecting to Azure with subscription $subscription" -ForegroundColor Green;
            Write-Host "If it's the first time you access Azure with this subscription, we will ask for credentials," -ForegroundColor Green;
            Write-Host "so pay attention!" -ForegroundColor Green;
            $global:azureProfileFilePath = (Join-Path $PSScriptRoot 'AzureProfile.json');
            if (Test-Path $global:azureProfileFilePath)
            {
                try
                {
                    $global:AzureAccount = Import-AzureRmContext -Path $global:azureProfileFilePath;
                    $loggedIn = $true;
                }
                catch{}
            }

            if (!$loggedIn)
            {
                $global:AzureAccount = Connect-AzureRmAccount  -Subscription $subscription ;
                Save-AzureRmContext -Path $global:azureProfileFilePath;
            }
            Select-AzureRmContext -Scope CurrentUser -InputObject $Global:AzureAccount.Context;
            Write-Host "Connected to Azure.`n" -ForegroundColor Green;
        }
        catch
        {
            $global:AzureAccount    = $null;
            throw $_;
        }
    }
}

function global:azurePopulateResourceResourceGroupIfNeeded()
{
    if ($global:resourceResourceGroup -eq $null)
    {
        $global:resourceResourceGroup = @{};
        $rs=Get-AzureRmResource;
        foreach ($r in $rs) 
        { 
            $global:resourceResourceGroup[$r.Name] = $r.ResourceGroupName; 
        }
    }
}

function global:azureConnectToServiceBus([ValidateNotNullOrEmpty()][string]$serviceBusConnectionString, [ValidateNotNullOrEmpty()][string]$deadLetterQueueName)
{
    if ($Global:AzureNamespaceManager -eq $null) 
    { 
        try
        {
            Write-Host "Connecting to Azure Service Bus" -ForegroundColor Green;

            Write-Host "Creating Namespace Manager" -ForegroundColor Green;
            $Global:AzureNamespaceManager     = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($ServiceBusConnectionString);
            Write-Host "Creating Messaging Factory" -ForegroundColor Green;
            $Global:AzureMessagingFactory      = [Microsoft.ServiceBus.Messaging.MessagingFactory]::CreateFromConnectionString($ServiceBusConnectionString);
            Write-Host "Connecting to Dead Letter Queue $deadLetterQueueName" -ForegroundColor Green;
            $Global:AzureDeadLetterQueueClient = [Microsoft.ServiceBus.Messaging.QueueClient]::CreateFromConnectionString($ServiceBusConnectionString, $deadLetterQueueName);
            global:azurePopulateResourceResourceGroupIfNeeded;
            $global:serviceBusNamespace = global:extractWithRegex $global:AzureNamespaceManager.Address.ToString() '.*?([A-Za-z_0-9]+)\.servicebus';
            $global:serviceBusResourceGroup = $global:resourceResourceGroup[$global:serviceBusNamespace];
            Write-Host "Connected to Azure Service Bus $($global:serviceBusNamespace) on resource group $($global:serviceBusResourceGroup) `n" -ForegroundColor Green;
        }
        catch
        {
            $Global:AzureNamespaceManager = $null;
            $Global:AzureMessagingFactory = $null;
            $Global:AzureDeadLetterQueueClient      = $null;
            throw $_;
        }
    }
}


function global:azureCreateTopicClient([ValidateNotNullOrEmpty()][string]$topicName)
{
    Write-Host "Creating topic client for $topicName" -ForegroundColor Green;

    try
    {
        $topic = Get-AzureRmServiceBusTopic -ResourceGroupName $global:serviceBusResourceGroup -Namespace $global:serviceBusNamespace -Name $topicName;
        if ($topic -eq $null)
        {
            throw "Topic $topicName does not exist."
        }
        $global:TopicClient = $Global:AzureMessagingFactory.CreateTopicClient($topicName);
    }
    catch
    {
        Write-Host "`n`nCould not create topic client for topic named [$topicName], please review data from the settings json file.`n`n" -ForegroundColor Yellow;
        $global:TopicClient = $null;
        throw $_;
    }
}

function global:azureReopenTopicSubscriptionClient()
{
    $topicName = $global:SubscriptionClient.TopicPath;
    $topicSubscriptionName = $global:SubscriptionClient.Name;
    $global:SubscriptionClient.Close();
    $global:SubscriptionClient =  $Global:AzureMessagingFactory.CreateSubscriptionClient($topicName, $topicSubscriptionName);
}

function global:azureCreateTopicSubscriptionClient(
    [ValidateNotNullOrEmpty()][string]$topicName, 
    [ValidateNotNullOrEmpty()][string]$topicSubscriptionName)
{

    Write-Host "Creating subscription client for $topicName $topicSubscriptionName" -ForegroundColor Green;

    try
    {
        if ($global:SubscriptionClient -eq $null -or $global:SubscriptionClient.TopicPath -ne $topicName -or $global:SubscriptionClient.Name -ne $topicSubscriptionName -or $global:SubscriptionClient.IsClosed)
        {
            $subs = Get-AzureRmServiceBusSubscription -ResourceGroupName $global:serviceBusResourceGroup -Namespace $global:serviceBusNamespace -Topic $topicName -Name $topicSubscriptionName;
            if ($subs -eq $null)
            {
                throw "Subscription $topicSubscriptionName does not exist for topic $topicName";
            }

            $global:SubscriptionClient =  $Global:AzureMessagingFactory.CreateSubscriptionClient($topicName, $topicSubscriptionName);
        }
    }
    catch
    {
        Write-Host "`n`nCould not create topic subcription client for topic named [$topicName] subscription [$topicSubscriptionName], please review data from the settings json file.`n`n" -ForegroundColor Yellow;
        $global:SubscriptionClient = $null;
        throw $_;
    }
}


function global:azureConnectServiceBusTopic(
    [ValidateNotNullOrEmpty()][string]$subscription,
    [ValidateNotNullOrEmpty()][string]$serviceBusConnectionString,
    [ValidateNotNullOrEmpty()][string]$deadLetterQueueName,
    [ValidateNotNullOrEmpty()][ValidateScript({ $_.Length -lt 50 })][string]$topicName,
    [ValidateNotNullOrEmpty()][ValidateScript({ $_.Length -lt 50 })][string]$topicSubscriptionName)
{
    global:importAzureModules;
    global:azureLoginIfNeeded                 $subscription;
    global:azureConnectToServiceBus   $serviceBusConnectionString $deadLetterQueueName;
    global:azureCreateTopicClient             $topicName;
    global:azureCreateTopicSubscriptionClient $topicName $topicSubscriptionName;
}

function global:loadVSTSVariableGroups()
{
    pushd .
    try
    {
        $global:vstsVariables = $null;
        $global:GetVariableGroupsPath = (global:findFile $env:GITBASEFOLDER 'GetVariableGroups.exe' $null).Where({ $_.ToLowerInvariant().Contains('bin\debug') })[0];
        if ($global:GetVariableGroupsPath -ne $null)
        {
            $d = [System.IO.Path]::GetDirectoryName($global:GetVariableGroupsPath);
            cd $d;
            $global:vstsVariables = &'.\GetVariableGroups.exe'  'parsAPI-V2*Variant*' | ConvertFrom-Json;
        }
    }
    finally
    {
        popd
    }
}

function global:loadSettings([ValidateNotNullOrEmpty()][string]$settingsFilePath = 'Settings.json')
{
    if (!(Test-Path $settingsFilePath))
    {
        $settingsFilePath = Join-Path $PSScriptRoot $settingsFilePath;
    }
    if (!(Test-Path $settingsFilePath))
    {
        throw "Could not find settings file.";
    }
    
    $errorCount = $Error.Count;
    $global:settings =  gc $settingsFilePath | ConvertFrom-Json -ErrorAction Stop;
    if ($errorCount -ne $Error.Count)
    {
        throw "Could not load $settingsFilePath.";
    }

    global:loadVSTSVariableGroups;
}

function global:azureConnectServiceBusTopicWithSettingsFile([ValidateNotNullOrEmpty()][string]$settingsFilePath)
{
    global:loadSettings $settingsFilePath;

    global:azureConnectServiceBusTopic $global:settings.subscription $global:settings.connectionString $global:settings.deadLetterQueueName $global:settings.topicName $global:settings.topicSubscription;
}

function global:azureResetNoDisconnect()
{
    if ($global:AzureMessagingFactory -ne $null)
    {
        try{$global:AzureMessagingFactory.Close();}catch{}
    }
    $global:AzureMessagingFactory = $null;
    $global:AzureNamespaceManager = $null;
    $global:settings              = $null;
    $global:SubscriptionClient    = $null;
    $global:TopicClient           = $null;
    $global:resourceResourceGroup = $null;
    $global:serviceBusNamespace   = $null;
    $Global:AzureDeadLetterQueueClient = $null;
    $global:HasAlreadyImportedAllDllsFromPSScriptRoot = $null;
}

function global:azureReset()
{
    try{Disconnect-AzureRmAccount;}catch{}
    global:azureResetNoDisconnect;
    try{del $global:azureProfileFilePath;}catch{}
}

function global:azureConnectAsAdmin([ValidateNotNullOrEmpty()][string]$settingsFilePath = 'settingsSubscriptionS00197csubnpDPAPI1.json')
{
    global:azureReset;
    $global:azureaccount = Login-AzureRmAccount;

}

if ($global:fileFinder -eq $null)
{

    [string]$findClass = 
    "
    using System;
    using System.Collections.Concurrent;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Runtime.InteropServices;
    using System.Threading.Tasks;
    using System.Text.RegularExpressions;

    public class FindClassLK
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private struct SHFILEOPSTRUCT
        {

            public IntPtr hwnd;
            [MarshalAs(UnmanagedType.U4)]
            public uint   wFunc;
            public string pFrom;
            public string pTo;
            public ushort fFlags;
            [MarshalAs(UnmanagedType.Bool)]
            public bool fAnyOperationsAborted;
            public IntPtr hNameMappings;
            public string lpszProgressTitle;
        }

        [DllImport(""shell32.dll"", CharSet = CharSet.Auto)]
        private static extern int SHFileOperation(ref SHFILEOPSTRUCT FileOp);

        string _baseFolder, _fOrD, _pattern;
        IEnumerable<string> _foundItems;

        public void Initialize(string baseFolder, string fOrD, string pattern)
        {
            _baseFolder = baseFolder;
            _fOrD = fOrD.ToUpperInvariant();
            _pattern = pattern;
            _foundItems = _fOrD == ""D""
                ? Directory.EnumerateDirectories(_baseFolder, _pattern, SearchOption.AllDirectories)
                : Directory.EnumerateFiles(_baseFolder, _pattern, SearchOption.AllDirectories);
        }

        public List<string> Find()
        {
            var l = new ConcurrentQueue<string>();
            Parallel.ForEach(_foundItems, item => l.Enqueue(item));
            return l.ToList();
        }

        public List<string> FindByText(string text)
        {
            var l = new ConcurrentQueue<string>();
            Parallel.ForEach(_foundItems, item =>
            {
                try { if (File.ReadAllText(item).Contains(text)) { l.Enqueue(item);  } }
                catch (Exception) { }
            });
            return l.ToList();        
        }

        public List<string> FindByTextRegularExpression(string regexPattern)
        {
            var re = new Regex(regexPattern);
            var l = new ConcurrentQueue<string>();
            Parallel.ForEach(_foundItems, item =>
            {
                try { if (re.Match(File.ReadAllText(item)).Success) { l.Enqueue(item); } }
                catch (Exception) { }
            });
            return l.ToList();
        }

        public void MoveToRecycleBin()
        {
            Parallel.ForEach(_foundItems, item =>
            {
                var fs = new SHFILEOPSTRUCT
                {
                    wFunc = 0x003, 
                    pFrom = item + '\0' + '\0',
                    fFlags = 0x0454 
                };
                Console.WriteLine(item);
                try
                {
                    SHFileOperation(ref fs);
                }
                catch(Exception ex)
                {
                    Console.WriteLine(ex.Message);
                }
            });
        }
    }";

    try{Add-Type $findClass}catch{};

    $global:fileFinder = [FindClassLK]::new();
}



if (!($global:HasAlreadyImportedAllDllsFromPSScriptRoot))
{
    Get-ChildItem -Path $PSScriptRoot -Filter "*.dll" | foreach { try{Import-Module $_.FullName -ErrorAction SilentlyContinue;}catch{} };
    $global:HasAlreadyImportedAllDllsFromPSScriptRoot = $true;
}


Write-Host 'AzureUtils.ps1 loaded' -ForegroundColor Green;