# This is a Profile.ps1 file, if it is copied to C:\WINDOWS\System32\WindowsPowerShell\v1.0, it will be executed
# when you open a new Powershell command.
# 


$global:lastTime = Get-Date;
$global:azureSubscriptionNames = ('sub1','sub2','subX');

function elapsedTime([int]$number)
{
    $now = Get-Date;
    $elapsed = (($now - $global:lastTime).TotalMilliSeconds -as [int]).ToString().PadLeft(5);
    write-host "$number $elapsed ms" -ForegroundColor Magenta;
    $global:lastTime = Get-Date;
}

Write-Host 'Profile';
if (!$env:gitBaseFolder)
{
	write-host "Environment variable GITBASEFOLDER not found, will try to find your git base folder automatically..." -ForegroundColor Green;
	$class =
@"
namespace QuickFind3
{
	using System;
    using System.Collections.Concurrent;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;

    public class QuickFindDirectory
    {
        public static IEnumerable<string> Find(string initialFolder, string folderName)
        {
            var q = new ConcurrentQueue<string>();
            return FindInternal(initialFolder, q, folderName);
        }

        private static IEnumerable<string> FindInternal(string v, ConcurrentQueue<string> q, string folderName)
        {
            var options = new ParallelOptions { MaxDegreeOfParallelism = Environment.ProcessorCount * 4 };
            try
            {
                var dirs = Directory.EnumerateDirectories(v);
                Parallel.ForEach(dirs, options, path =>
                {
                    if (Path.GetFileName(path).Equals(folderName, StringComparison.InvariantCultureIgnoreCase))
                    {
                        q.Enqueue(path);
                    }
                    FindInternal(path, q, folderName);
                });
            }
            catch (Exception)
            { }
            return q;
        }
    }
}
"@;
	Add-Type -TypeDefinition $class;
	$l = [QuickFind3.QuickFindDirectory]::Find('c:\', '.git') | foreach { [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName($_)) };
	$counts = @{};
	$l.ForEach({ $counts[$_]++ });
	$maxCount = ($counts.Values | Measure -Maximum).Maximum;
	$gitBaseFolder = "";
	$counts.Keys.ForEach({ if ($counts[$_] -eq $maxCount) {$gitBaseFolder = $_}})
	[System.Environment]::SetEnvironmentVariable('GITBASEFOLDER', $gitBaseFolder, 'User');
	$env:gitBaseFolder = $gitBaseFolder;

	write-host "Found GITBASEFOLDER not found, using $gitBaseFolder" -ForegroundColor Green;

}

cd $env:gitBaseFolder;

#elapsedTime 13;
if (!(Test-Path 'PowerShellScriptDirectory.txt'))
{
	write-host "File PowerShellScriptDirectory.txt not found, searching for the AzureUtils.ps1 file..." -ForegroundColor Green;
    #elapsedTime 16;
    $x=Get-ChildItem -Path c:\dsv -Filter AzureUtils.ps1 -Force -Recurse;
    #elapsedTime 18;
    if ($x.GetType().BaseType -eq [System.Array]) { $x = $x[0] }
    #elapsedTime 20;
    $x.DirectoryName | Out-File 'PowerShellScriptDirectory.txt';
	write-host "File PowerShellScriptDirectory.txt found at $($x.DirectoryName)" -ForegroundColor Green;
    #elapsedTime 22;
}

#elapsedTime 25;
$global:powerShellScriptDirectory = gc 'PowerShellScriptDirectory.txt';
#elapsedTime 27;

if (!$env:path.ToLowerInvariant().Contains($global:powerShellScriptDirectory))
{
    $env:path = "$global:powerShellScriptDirectory;$env:path";
}
Write-Host 'LK Profile loading Utils.ps1';
&(join-path $global:powerShellScriptDirectory 'Utils.ps1');
#elapsedTime 35;

Write-Host 'LK Profile loading AzureUtils.ps1';
&(join-path $global:powerShellScriptDirectory 'AzureUtils.ps1');
#elapsedTime 39;

try
{
    #global:signAllPSMUnderFolder $global:powerShellScriptDirectory
    global:importAllPSMUnderFolder $global:powerShellScriptDirectory;
    #elapsedTime 45;
}
catch
{
    write-host "Could not import PSM modules under $global:powerShellScriptDirectory, but will continue." -ForegroundColor Yellow;
}
#elapsedTime 51;


Write-Host 'LK Profile loading settings';
global:loadSettings       'Settings.json';
$global:vstsProjectUri = "https://$($global:settings.tfsAccount).visualstudio.com/$($global:settings.tfsProject)"

#elapsedTime 55;

Write-Host 'LK Profile importing Azure Modules';
global:importAzureModules;
#elapsedTime 59;

global:importModuleIfNeeded 'VSTS';
#elapsedTime 62;

Write-Host 'LK Profile Azure log in';
Write-Host (global:toBeautifulJson $global:settings) -ForegroundColor Cyan;

#$global:settings.subscription = $global:azureSubscriptionNames | Out-GridView -OutputMode Single;
#global:azureLoginIfNeeded $global:settings.subscription;
#elapsedTime 66;
global:azureInstallCosmosDBIfNeeded;
$global:LatestPrompt = get-date;
Write-Host 'LK Profile done.';



function retrieveGitInfo($cb)
{
    $message = "";
    if (!($cb -cmatch "Not a git repo"))
    {
        $gss = (git status -s);
        $gsu = (git status -s -uno);
        $countOfAllChangedFiles = 0;
        $countOfAllChangedExceptAddedFiles = 0;
        if ($gss -ne $null)
        {
            $countOfAllChangedFiles = $gss.Split("`n").Count;
        }
        if ($gsu -ne $null)
        {
            $countOfAllChangedExceptAddedFiles = (git status -s -uno).Split("`n").Count;
        }
        $countOfUntrackedFiles = ($countOfAllChangedFiles - $countOfAllChangedExceptAddedFiles);
        $message = "Chg:$($countOfAllChangedExceptAddedFiles.ToString().PadLeft(3)) Unt:$($countOfUntrackedFiles.ToString().PadLeft(3))";        
    }

    return $message;
}

function colorForBranch($cb)
{
    $color = 'Yellow'
    if ($cb -cmatch 'master' -or $cb -cmatch 'develop')
    {
        $color = 'Red';
    }
    if ($cb -cmatch 'Not a git repo')
    {
        $color = 'Blue';
    }
    return $color;
}

function p
{
    [CmdletBinding()]
    param(
        $o, 
        [ValidateSet('red','green','blue','yellow','white')]$color = 'white')
    Write-Host $o -ForegroundColor $color;
}


function pj
{
    [CmdletBinding()]
    param(
        $o, 
        [ValidateSet('red','green','blue','yellow','white')]$color = 'white')
    Write-Host ($o | ConvertTo-Json) -ForegroundColor $color;
}

function repeat
{
    [CmdletBinding()]
    param(
        [int]$count, 
        [System.Management.Automation.ScriptBlock]$script,
        [int]$waitBetweenRepetitionsInSeconds = 0)
    for ($i = 0; $i -lt $count; $i++)
    {
        $script.Invoke();  
        Start-Sleep -Seconds $waitBetweenRepetitionsInSeconds;
    }
}

function LK-Azure-GetTopics
{
    [CmdletBinding()]
    param
    (
        
        [parameter(Mandatory=$true, Position=0)][string]$locationEnvironment
    )
    $connectionString  = $global:settings.serviceBusConnectionStrings | where { $_.Contains($locationEnvironment) };
    $namespace         = global:extractWithRegex $connectionString 'sb://([a-z0-9]+?)\.servicebus\.windows\.net';
    $resourceGroupName = ($global:resourcesAndResourceGroups | where { $_.Name -eq $namespace }).ResourceGroupName;
    return Get-AzureRmServiceBusTopic -ResourceGroupName $resourceGroupName -Namespace $namespace;
}

function LK-Azure-GetTopicSubscriptions
{
    [CmdletBinding()]
    param
    (
        
        [parameter(Mandatory=$true, Position=0)][string]$locationEnvironment,
        [parameter(Mandatory=$true, Position=1)][string]$TopicName
    )
    $connectionString  = $global:settings.serviceBusConnectionStrings | where { $_.Contains($locationEnvironment) };
    $namespace         = global:extractWithRegex $connectionString 'sb://([a-z0-9]+?)\.servicebus\.windows\.net';
    $resourceGroupName = ($global:resourcesAndResourceGroups | where { $_.Name -eq $namespace }).ResourceGroupName;
    return Get-AzureRmServiceBusSubscription  -ResourceGroupName $resourceGroupName -Namespace $namespace -Topic $TopicName;
}

function LK-Azure-GetTopicSubscriptionMessages
{
    [CmdletBinding()]
    param
    (
        
        [parameter(Mandatory=$true, Position=0)][string]$locationEnvironment,
        [ValidateNotNullOrEmpty()][string]$topicName, 
        [ValidateNotNullOrEmpty()][string]$subscriptionName
    )
    $connectionString  = $global:settings.serviceBusConnectionStrings | where { $_.Contains($locationEnvironment) };
    global:azurePeekAllServiceBusTopicSubscription $connectionString $topicName $subscriptionName;
}

function LK-getCosmosDoc
{
    [CmdletBinding()]
    param(
        
        [parameter(Mandatory=$true, Position=0)][string]$locationEnvironment,
        [parameter(Mandatory=$true, Position=1)][string]$table,
        [parameter(Mandatory=$true, Position=2)][string]$key
    )
    $connectionString = ($global:settings.cosmosDbConnectionStrings).Where({ $_.Contains($locationEnvironment) });
    $context = global:azureGetCosmosContextByConnectionString $connectionString;
    return global:azureGetCosmosDocument $context $table $key;
}

function LK-saveChangedFiles
{
    global:SaveChangedFiles;
}

function saveAzureCredentials($userName, $password)
{
    class Cred {
        [string]$userName
        [string]$password
    }
    $cred = New-Object -TypeName Cred;
    $cred.UserName = $userName;
    $cred.Password = $password;
    $fileName = Join-Path $global:powerShellScriptDirectory 'azureCredentials.json';
    ConvertTo-Json -InputObject $cred | out-file $fileName;
}

function LK-Azure-Login
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=0)]
        $subscription,
        [switch]$useAzureCredentialFileInsteadOfAskingForCredentialsInADialog = $false)

    try { Disconnect-AzureRmAccount -ErrorAction SilentlyContinue } catch {};
    try { Remove-AzureRmAccount     -ErrorAction SilentlyContinue } catch {};
    $cred = global:createCredentialFromAzureCredentialsJSONFile;
    if ($useAzureCredentialFileInsteadOfAskingForCredentialsInADialog)
    {
        $global:azureAccount = Connect-AzureRmAccount -Subscription $subscription -Credential $cred;
    }
    else
    {
        $global:azureAccount = Connect-AzureRmAccount -Subscription $subscription;
    }


    Add-AzureRmAccount -Credential $cred -TenantId $global:azureaccount.Context.Tenant.Id;
    Get-AzureRmSubscription -SubscriptionName $global:azureaccount.Context.Subscription.Name | Select-AzureRmSubscription;
    $profile = Select-AzureProfile -Default;
    Get-AzureSubscription -Profile $profile | Select-AzureSubscription ;
    $global:resourcesAndResourceGroups = (Get-AzureRmResource) | select Name,ResourceGroupName;
    $global:nonProdSubscription        = Get-AzureRmSubscription -SubscriptionName sacsubnpDPAPI1;
    $global:prodSubscription           = Get-AzureRmSubscription -SubscriptionName sacsubproddpapi2;
}

function LK-Azure-LoadSettings
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()][string]$settingsFilePath = 'Settings.json'
    )
    global:loadSettings $settingsFilePath;
}

function LK-Azure-Reset
{
    [CmdletBinding()]
    param([switch]$DisconnectFromAzure=$false)
    if ($DisconnectFromAzure)
    {
        global:azureReset;
    }
    else
    {
        global:azureResetNoDisconnect;
    }
}

function LK-ser
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]$object 
    )
    global:toBeautifulJson $object;
}

function LK-utc
{
    [CmdletBinding()]param()
    Write-Output (get-date).ToUniversalTime().ToString("u");
}

# global:findFile([string]$searchFolder, [string]$fileNamePattern, [string]$optionalTextToFindWithoutWildcards = $null)
function LK-Find
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=0)][string]$optionalTextToFindWithoutWildcards = $null,
        [parameter(Mandatory=$false, Position=1)][string]$fileNamePattern = '*.*',
        [parameter(Mandatory=$false, Position=2)][string]$searchFolder  = '.'
    )
    if ($searchFolder -eq '.')
    {
        $searchFolder = (pwd).Path;
    }
    return global:findFile $searchFolder $fileNamePattern $optionalTextToFindWithoutWildcards;
}

function LK-dirsb
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=0)][string]$fileNamePattern = '*.*'
    )
    return global:findFile (pwd).Path $fileNamePattern $null;
}

function LK-FindEdit
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=0)][string]$optionalTextToFindWithoutWildcards = $null,
        [parameter(Mandatory=$false, Position=1)][string]$fileNamePattern = '*.*',
        [parameter(Mandatory=$false, Position=2)][string]$searchFolder  = '.'
    )
    if ($searchFolder -eq '.')
    {
        $searchFolder = (pwd).Path;
    }
    $l = global:findFile $searchFolder $fileNamePattern $optionalTextToFindWithoutWildcards;
    foreach ($filename in $l)
    {
        n $filename;
    }
    Set-Clipboard $optionalTextToFindWithoutWildcards;
}

if ($global:azureCommands -eq $null)
{
    $global:azureCommands = ((get-command).Where({ $_.ModuleName.StartsWith('Azure') })).Name;
}


function LK-Get-Azure-Resource
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=0)][string]$ResourceName
    )
    Write-Verbose "Getting resource $ResourceName";
    $r = Get-AzureRmResource -Name $ResourceName;
    if ($r -eq $null)
    {
        throw "$ResourceName not found.";
    }
    Write-Verbose "Resource $ResourceName found, let's see if we can get detailed info...";
    $rtparts = $r.ResourceType.Split('./');
    if ($rtparts.Count -gt 2)
    {
        $candidates = (($rtparts[1] + $rtparts[2]), ($rtparts[1] + $rtparts[2].Substring(0, $rtparts[2].Length - 1)), $rtparts[1]);
    }
    else
    {
        $candidates = ($rtparts[1]);
    }

    foreach ($candidate in $candidates)
    {
        $pattern = "get.*$($candidate)";
        $re = [System.Text.RegularExpressions.Regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $commands = ($global:azureCommands).Where({ $re.IsMatch($_) }) | Sort-Object;
        if ($commands -ne $null -and $commands.Count -gt 0)
        {
            foreach ($command in $commands)
            {
                Write-Verbose $command;
                $expr1 = ('$ret=' + $command + " " + $ResourceName);
                $expr2 = ('$ret=' + $command + " -ResourceGroupName " + $r.ResourceGroupName +" -Name "+ $ResourceName);
                try
                {
                    Write-Verbose $expr1  -ForegroundColor Green;
                    $ev = $null;
                    Invoke-Expression -Command $expr1  -ErrorVariable 'ev' 2> NULL;
                    if ($ev -eq $null -or $ev.Count -eq 0)
                    {
                        break;
                    }
                }
                catch
                {
                    Write-Verbose "uuummm, let's try again..."
                }
                try
                {
                    Write-Verbose $expr2;
                    $ev = $null;
                    Invoke-Expression -Command $expr2  -ErrorVariable 'ev' 2> NULL;
                    if ($ev -eq $null -or $ev.Count -eq 0)
                    {
                        break;
                    }
                }
                catch
                {
                    Write-Verbose "uuummm, let's try again...";
                }
            }
        }
        if ($ret -ne $null)
        {
            break;
        }
    }
    if ($ret -ne $null)
    {
        Write-Verbose '$global:latestResource has the resource, in case you forgot to assign it to a variable...' ;
        $global:latestResource = $ret;
        return $ret;
    }
    Write-Verbose 'Could not get detailed info, returning basic resource...';
    return $r;
}

function LK-Remove-Azure-Resource
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false, Position=0)][string]$ResourceName
    )
    Write-Verbose "Getting resource $ResourceName";
    $r = Get-AzureRmResource -Name $ResourceName;
    if ($r -eq $null)
    {
        throw "$ResourceName not found.";
    }
    $ev = $null;
    Remove-AzureRmResource -ResourceName $ResourceName -ResourceGroupName $r.ResourceGroupName -ResourceType $r.ResourceType -Force -ErrorVariable 'ev' 2> NULL;
    if ($ev -ne $null)
    {
        Write-Error $ev;
    }
}

function LK-peekTopicSubscription
{
        [CmdletBinding()]
    param(
        
        [parameter(Mandatory=$true,  Position=0)][string]$locationEnvironment,
        [parameter(Mandatory=$false, Position=1)][string]$topicName        = 'parsactivated',
        [parameter(Mandatory=$false, Position=2)][string]$subscriptionName = 'defaultsubscription'
    )
    $connectionString = ($Global:settings.serviceBusConnectionStrings).Where({ $_.Contains($locationEnvironment)})
    $events = global:azurePeekAllServiceBusTopicSubscription $connectionString $topicName $subscriptionName;
    return ($events.GetEnumerator() | Sort-Object -Property EnqueuedSequenceNumber -Descending);
}

function LK-alignTextInFile
{
        [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=0)][string]$inputFilePath,
        [parameter(Mandatory=$false, Position=1)][string]$delimiter = ':',
        [parameter(Mandatory=$false, Position=2)][string]$outputFilePath  = ''
    )

    if ($outputFilePath -eq '')
    {
        $outputFilePath = $inputFilePath;
    }
    $encoding = global:getFileEncoding $inputFilePath;
    $aligned = global:alignBy (gc $inputFilePath) $delimiter;
    $aligned | Out-File $outputFilePath -Encoding $encoding;
}

function LK-Cosmos-Connect
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,  Position=0)][string]$Environment
    )
    $connectionString = $global:settings.cosmosDbConnectionStrings | where { $_.Contains($Environment) };
    $global:cosmosContext = global:azureGetCosmosContextByConnectionString $connectionString;
}

function LK-Cosmos-Database
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false,  Position=0)][string]$DatabaseName
    )

    CheckCosmosContext;

    if ($DatabaseName -eq $null -or $DatabaseName.Length -eq 0)
    {
        return Get-CosmosDbDatabase -Context $global:cosmosContext;
    }
    else
    {
        return Get-CosmosDbDatabase -Context $global:cosmosContext -id $DatabaseName;
    }
}

function LK-Cosmos-Collection
{
        [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,  Position=0)][string]$DatabaseName,
        [parameter(Mandatory=$false,  Position=1)][string]$CollectionName

    )

    CheckCosmosContext;

    if ($CollectionName -eq $null -or $CollectionName.Length -eq 0)
    {
        return Get-CosmosDbCollection -Context $global:cosmosContext -Database $DatabaseName;
    }
    else
    {
        return Get-CosmosDbCollection -Context $global:cosmosContext -Database $DatabaseName -Id $CollectionName;
    }
}

#

function LK-Cosmos-Document
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,  Position=0)][string]$DatabaseName,
        [parameter(Mandatory=$true,  Position=1)][string]$CollectionName,
        [parameter(Mandatory=$false, Position=2)][string]$Id
    )

    CheckCosmosContext;

    if ($Id -eq $null -or $Id.Length -eq 0)
    {
        return Get-CosmosDbDocument -Context $global:cosmosContext  -Database $DatabaseName -CollectionId $CollectionName ;
    }
    else
    {
        $idAsList = @($id);
        return Get-CosmosDbDocument -Context $global:cosmosContext  -Database $DatabaseName -CollectionId $CollectionName -PartitionKey $idAsList;
    }
}



function LK-Get-Cosmos-Gifting-Document
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=0)][string]$CollectionName,
        [parameter(Mandatory=$false, Position=1)][string]$Id
    )
    $docs = (LK-Cosmos-Document -DatabaseName $global:cosmosContext.Database  -CollectionName $CollectionName -Id $id);

    lk-ser $docs;
}

function LK-Cosmos-Order
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true , Position=0)][string]$OrderId,
        [parameter(Mandatory=$false, Position=1)][switch]$enableQueryOnNonPartitionColumns = $false
    )

    CheckCosmosContext;

    $orders = @{};
    $databases = (LK-Cosmos-Database).Id;
    $orderIdAsList = @($OrderId);

    foreach ($database in $databases)
    {
        $orders[$database] = @{};
        $collections = (LK-Cosmos-Collection -DatabaseName $database).Id;
        foreach ($collection in $collections)
        {
            $orders[$database][$collection] = Get-CosmosDbDocument -Context $global:cosmosContext  -Database $database -CollectionId $collection -PartitionKey $orderIdAsList;
            if ($enableQueryOnNonPartitionColumns -and $orders[$database][$collection] -eq $null)
            {
                $obj = Get-CosmosDbDocument -Context $global:cosmosContext  -Database $database -CollectionId $collection -MaxItemCount 1;
                if ((Get-Member -InputObject $obj -Name 'orderId' -MemberType NoteProperty) -ne $null)
                {
                    $query = "select * from $collection X where (X.orderId = '$OrderId')";
                    $orders[$database][$collection] = Get-CosmosDbDocument -Context $global:cosmosContext  -Database $database -CollectionId $collection -Query $query -QueryEnableCrossPartition $true;
                }
            }
        }
    }
    lk-ser $orders;
}

function LK-tool-GetAllServiceEndpoints 
{ 
    pushd .; 
    cd "$global:powerShellScriptDirectory\..\GetAllServiceEndpoints\bin\debug"; 
    $result = &'.\GetAllServiceEndpoints.exe'; 
    popd; 
    return $result; 
} 

function LK-Tool-GetReleaseDefinition
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$definitionName)
   pushd .
   cd "$global:powerShellScriptDirectory\..\GetReleaseDefinition\bin\debug";
   $result = &'.\GetReleaseDefinition.exe' $definitionName;
   popd;
   return $result;
}

function LK-Tool-GetVariableGroups
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$variableGroupFilter)
   pushd .
   cd "$global:powerShellScriptDirectory\..\GetVariableGroups\bin\debug";
   $result = &'.\GetVariableGroups.exe' $variableGroupFilter;
   popd;
   return $result;
}
function LK-Tool-SetReleaseDefinition
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$definitionJSON)
   pushd .
   cd "$global:powerShellScriptDirectory\..\SetReleaseDefinition\bin\debug";
   $result = &'.\SetReleaseDefinition.exe' $definitionJSON;
   popd;
   return $result;
}
function LK-Tool-UpdateReleaseDefinitionVariableGroups
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$releaseDefinitionName)
   pushd .
   cd "$global:powerShellScriptDirectory\..\UpdateReleaseDefinitionVariableGroups\bin\debug";
   $result = &'.\UpdateReleaseDefinitionVariableGroups.exe' $releaseDefinitionName;
   popd;
   return $result;
}
function LK-Tool-DeleteVariableGroup
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$variableGroupName)
   pushd .
   cd "$global:powerShellScriptDirectory\..\DeleteVariableGroup\bin\debug";
   $result = &'.\DeleteVariableGroup.exe' $variableGroupName;
   popd;
   return $result;
}

function LK-Tool-StartReleaseFromLatestBuild
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$ReleaseDefinitionName, 
      [parameter(Mandatory=$true, Position=1)][string]$environmentsToBeExecutedAsManual)
   pushd .
   cd "$global:powerShellScriptDirectory\..\StartReleaseFromLatestBuild\bin\debug";
   $result = &'.\StartReleaseFromLatestBuild.exe' $ReleaseDefinitionName $environmentsToBeExecutedAsManual;
   popd;
   return $result;
}
function LK-Tool-GetVariable
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$variableGroupName, 
      [parameter(Mandatory=$true, Position=1)][string]$variableName)
   pushd .
   cd "$global:powerShellScriptDirectory\..\GetVariable\bin\debug";
   $result = &'.\GetVariable.exe' $variableGroupName $variableName;
   popd;
   return $result;
}

function LK-Tool-RenameVSTSVariableGroup
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$oldVariableGroupName, 
      [parameter(Mandatory=$true, Position=1)][string]$newVariableGroupName)
   pushd .
   cd "$global:powerShellScriptDirectory\..\RenameVSTSVariableGroup\bin\debug";
   $result = &'.\RenameVSTSVariableGroup.exe' $oldVariableGroupName $newVariableGroupName;
   popd;
   return $result;
}

function LK-Tool-SetVariable
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$variableGroupName,
      [parameter(Mandatory=$true, Position=1)][string]$variableName, 
      [parameter(Mandatory=$true, Position=2)][string]$variableValue)
   pushd .
   cd "$global:powerShellScriptDirectory\..\SetVariable\bin\debug";
   $result = &'.\SetVariable.exe' $variableGroupName $variableName $variableValue;
   popd;
   return $result;
}

function LK-Tool-DeleteVariableFromVariableGroup
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$variableGroupName, 
      [parameter(Mandatory=$true, Position=1)][string]$variableName)
   pushd .
   cd "$global:powerShellScriptDirectory\..\DeleteVariableFromVariableGroup\bin\debug";
   $result = &'.\DeleteVariableFromVariableGroup.exe' $variableGroupName $variableName;
   popd;
   return $result;
}

function LK-Tool-CloneReleaseDefinition
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$sourceDefinitionName, 
      [parameter(Mandatory=$true, Position=1)][string]$destinationDefinitionName, 
      [parameter(Mandatory=$true, Position=2)][string]$environmentTranslation)
   pushd .
   cd "$global:powerShellScriptDirectory\..\CloneReleaseDefinition\bin\debug";
   $result = &'.\CloneReleaseDefinition.exe' $sourceDefinitionName $destinationDefinitionName $environmentTranslation;
   popd;
   return $result;
}

function LK-Tool-DeleteReleaseDefinitionStep
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$sourceDefinitionName, 
      [parameter(Mandatory=$true, Position=1)][string]$sourceEnvironmentRegularExpression, 
      [parameter(Mandatory=$true, Position=2)][string]$sourceTaskRegularExpression)
   pushd .
   cd "$global:powerShellScriptDirectory\..\DeleteReleaseDefinitionStep\bin\debug";
   $result = &'.\DeleteReleaseDefinitionStep.exe' $sourceDefinitionName $sourceEnvironmentRegularExpression $sourceTaskRegularExpression;
   popd;
   return $result;
}

function LK-Tool-CloneVSTSVariableGroup
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$sourceGroup, 
      [parameter(Mandatory=$true, Position=1)][string]$destGroup, 
      [parameter(Mandatory=$true, Position=2)][string]$strategy, 
      [parameter(Mandatory=$false, Position=3)][switch]$NoRepl)
   pushd .
   cd "$global:powerShellScriptDirectory\..\CloneVSTSVariableGroup\bin\debug";
   $result = &'.\CloneVSTSVariableGroup.exe' $sourceGroup $destGroup $strategy $NoRepl;
   popd;
   return $result;
}

function LK-Tool-CopyReleaseDefinitionStep
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$sourceDefinitionName, 
      [parameter(Mandatory=$true, Position=1)][string]$sourceEnvironment, 
      [parameter(Mandatory=$true, Position=2)][string]$sourceTasknameRegularExpression, 
      [parameter(Mandatory=$true, Position=3)][string]$destinationDefinitionName, 
      [parameter(Mandatory=$true, Position=4)][string]$destinationEnvironmentRegularExpression,
      [ValidateSet('After','AtPosition','Before')]
      [parameter(Mandatory=$true, Position=5)][string]$afterAtPositionOrBefore,
      [parameter(Mandatory=$true, Position=6)][string]$TasknameRegularExpressionOrPositionNumber)

   pushd .
   cd "$global:powerShellScriptDirectory\..\CopyReleaseDefinitionStep\bin\debug";
   $result = &'.\CopyReleaseDefinitionStep.exe' $sourceDefinitionName $sourceEnvironment $sourceTasknameRegularExpression $destinationDefinitionName $destinationEnvironmentRegularExpression $afterAtPositionOrBefore $TasknameRegularExpressionOrPositionNumber;
   popd;
   return $result;
}

function LK-Tool-CreateparameterJson
{
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, Position=0)][string]$vssUri, 
      [parameter(Mandatory=$true, Position=1)][string]$project, 
      [parameter(Mandatory=$true, Position=2)][string]$templateJson, 
      [parameter(Mandatory=$true, Position=3)][string]$personalToken, 
      [parameter(Mandatory=$true, Position=4)][string]$variableGroupNames, 
      [parameter(Mandatory=$false,Position=5)][string]$parameterOverrideJson)
   pushd .
   cd "$global:powerShellScriptDirectory\..\CreateparameterJson\bin\debug";
   $result = &'.\CreateparameterJson.exe' $vssUri $project $templateJson $personalToken $variableGroupNames $parameterOverrideJson;
   popd;
   return $result;
}


function CheckCosmosContext
{
    if ($global:cosmosContext -eq $null)
    {
        throw "Execute LK-Cosmos-Connect before any other Cosmos operation."
    }
}

function getSecret($kvName, $secretname)
{
    $secret = $null;
    for ($i = 0; $i -lt 8; $i++)
    {
        try
        {
            $ev = $null;
            $s = Get-AzureKeyVaultSecret -VaultName $kvname   -Name $secretname -ErrorVariable 'ev' -ErrorAction SilentlyContinue 2> NULL;
            if ($ev -ne $null)
            {
                        Start-Sleep -Seconds 2;
            }
            else
            {
                $secret = $s.SecretValueText;
                $i = 1000;
            }
        }
        catch
        {
            Start-Sleep -Seconds 2;
        }
    }
    return $secret;
}

function LK-getKeyVaultSecret
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,  Position=0)][string]$locationEnvironment,
        [parameter(Mandatory=$false, Position=1)][string]$secretName       = 'serviceBusConnectionString'
    )
    if ($locationEnvironment -eq 'all')
    {
        $dic = @{};
        if ($global:AzureAccount.Context.Subscription.Name -eq 'sacsubpddpapi2')
        {
            $envs = @('0pd', '1pd');
        }
        else
        {
            $envs = @('0ct', '0dv','0load','0ts','1ct','1dv','1load','1ts');
        }
        foreach ($env in $envs)   
        {
            $secrets = LK-getKeyVaultSecret $env $secretName;
            $dic[$env] = $secrets;
        }
        return $dic;
    }
    else
    {
        $secrets = @{};
        $secrets.Add('v1', (getSecret "uswkvt$($locationEnvironment)pars"   $secretName));
        $secrets.Add('v2', (getSecret "uswkvt$($locationEnvironment)parsv2" $secretName));
        return $secrets;
    }
}

function LK-setKeyVaultSecret
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,  Position=0)][string]$Version,
        [parameter(Mandatory=$true,  Position=1)][string]$locationEnvironment,
        [parameter(Mandatory=$true,  Position=2)][string]$SecretName,
        [parameter(Mandatory=$true,  Position=3)][string]$SecretValue
    )
    $v = $version;
    if ($v -eq 'v1')
    {
        $v = '';
    }
    $VaultName = "uswkvt$($locationEnvironment)pars$v";
    $secretValueAsSecretString = ConvertTo-SecureString $SecretValue -AsPlainText -Force;
 
    Set-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $secretValueAsSecretString;
}

function LK-getVSTSVariables
{
    [CmdletBinding()]
    param(
        [string]$locationEnvironment)
    $lec  = $locationEnvironment.Substring(1) + $locationEnvironment[0];
    $lec  = $lec.Replace('0', 'East').Replace('1', 'West');
    $env  = $lec.Replace('East','').Replace('West','');
    $res  = @{};
    $res  = global:flatObjectModelToDictionary $global:vstsVariables.'parsAPI-V2-CI-Invariants';
    $res += global:flatObjectModelToDictionary $global:vstsVariables."parsAPI-V2-CI-LocationInvariants-$env";
    $res += global:flatObjectModelToDictionary $global:vstsVariables."parsAPI-V2-CI-Variants-$lec";
    return (global:sortDictionaryByKey $res);
}

function LK-getLatestBuildArtifacts
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=0)][string]$buildDefinitionName,
        [parameter(Mandatory=$true, Position=1)][string]$outputFolder
    )

    if ($outputFolder -eq "")
    {
        $outputFolder = (pwd).Path;
    }
    global:getLatestBuildArtifacts $global:settings.tfsAccessToken $global:vstsProjectUri $buildDefinitionName $outputFolder;
}

function setBackgroundColorAccordingToSubscription($sub)
{
    $color = 'DarkCyan'
    if ($sub -match 'sacsubnpDPAPI1')
    {
        $color = 'DarkBlue';
    }
    if ($sub -match 'sacsubpddpapi2')
    {
        $color = 'DarkGreen';
    }
    if ($sub -match 'sadsubsbdpsand')
    {
        $color = 'Black';
    }
    $Host.UI.RawUI.BackgroundColor =  $color;
    $Host.PrivateData.ConsolePaneBackgroundColor = $color;
}



function prompt
{
    write-host '---------------------------------------------------------------------------------------------------' -ForegroundColor DarkYellow;
    $now = get-date;

    $cb = global:getCurrentBranch;
    $gi = retrieveGitInfo $cb;
    $azureSubscription = 'notConnectedToAzure';
    if ($global:azureAccount.Context.Subscription.Name -ne $null)
    {
        $azureSubscription = $global:azureAccount.Context.Subscription.Name;
    }
    setBackgroundColorAccordingToSubscription $azureSubscription;

    $elapsed = (($now - $global:LatestPrompt).TotalSeconds -as [int]).ToString().PadLeft(5);
    $global:LatestPrompt = $now;
    
    $color = 'Yellow';
    if ($gi -cmatch 'Chg:  0 Unt:  0') { $color = 'Green' }
    Write-Host $gi -ForegroundColor ($color) -NoNewline;
    Write-Host " Elp: $($elapsed)s $(global:shortdate) $azureSubscription " -ForegroundColor Yellow -NoNewline;
    $color = colorForBranch $cb;
    Write-Host ($cb.PadRight(32)) -ForegroundColor ($color) -NoNewline;

    Write-Host " $PWD" -ForegroundColor Cyan;
    return '] ';
}

