


<#
.SYNOPSIS
  Enables an Azure Function.

.DESCRIPTION
  Enables an Azure Function.

.PARAMETER <ResourceGroupName>
  Name of Resource Group where the Function App is located.

.PARAMETER <FunctionAppName>
  Name of Function App that hosts the function.

.PARAMETER <FunctionName>
  Name of Function to be enabled.

.OUTPUTS
  Generic Function properties.
  
.EXAMPLE

 Enable-AzureFunction -ResourceGroupName lk01rgr01 -FunctionAppName lk01fap01 -FunctionName transformfunction | ConvertTo-Json
{
    "id":  "/subscriptions/a08fca8b-e7e8-445a-94e1-6bf714ce5ba4/resourceGroups/lk01rgr01/providers/Microsoft.Web/sites/lk01fap01/config/appsettings",
    "name":  "appsettings",
    "type":  "Microsoft.Web/sites/config",
    "location":  "West US",
    "tags":  {

             },
    "properties":  {
                       "FUNCTIONS_EXTENSION_VERSION":  "~3",
                       "FUNCTIONS_WORKER_RUNTIME":  "powershell",
                       "AzureWebJobsStorage":  "DefaultEndpointsProtocol=https;AccountName=XXXX;AccountKey=YYYY;EndpointSuffix=core.windows.net",
                       "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING":  "DefaultEndpointsProtocol=https;AccountName=AAAAAA;AccountKey=BBBBBBB;EndpointSuffix=core.windows.net",
                       "WEBSITE_CONTENTSHARE":  "lk01fap01b79e",
                       "AzureWebJobs.HttpTrigger1.Disabled":  "true",
                       "AzureWebJobs.transformfunction.Disabled":  "False"
                   }
}
#>
function global:Enable-AzureFunction
{
    param(
        [parameter(Mandatory=$true)][string]$ResourceGroupName,
        [parameter(Mandatory=$true)][string]$FunctionAppName,
        [parameter(Mandatory=$true)][string]$FunctionName)
    enableDisableAzureFunction -ResourceGroupName $ResourceGroupName -FunctionAppName $FunctionAppName -FunctionName $FunctionName -EnableOrDisable Enable;
}

<#
.SYNOPSIS
  Disables an Azure Function.

.DESCRIPTION
  Disables an Azure Function.

.PARAMETER <ResourceGroupName>
  Name of Resource Group where the Function App is located.

.PARAMETER <FunctionAppName>
  Name of Function App that hosts the function.

.PARAMETER <FunctionName>
  Name of Function to be disabled.

.OUTPUTS
  Generic Function properties.
  
.EXAMPLE
 
 Disable-AzureFunction -ResourceGroupName lk01rgr01 -FunctionAppName lk01fap01 -FunctionName transformfunction | ConvertTo-Json
{
    "id":  "/subscriptions/a08fca8b-e7e8-445a-94e1-6bf714ce5ba4/resourceGroups/lk01rgr01/providers/Microsoft.Web/sites/lk01fap01/config/appsettings",
    "name":  "appsettings",
    "type":  "Microsoft.Web/sites/config",
    "location":  "West US",
    "tags":  {

             },
    "properties":  {
                       "FUNCTIONS_EXTENSION_VERSION":  "~3",
                       "FUNCTIONS_WORKER_RUNTIME":  "powershell",
                       "AzureWebJobsStorage":  "DefaultEndpointsProtocol=https;AccountName=XXXX;AccountKey=YYYY;EndpointSuffix=core.windows.net",
                       "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING":  "DefaultEndpointsProtocol=https;AccountName=AAAAAA;AccountKey=BBBBBBB;EndpointSuffix=core.windows.net",
                       "WEBSITE_CONTENTSHARE":  "lk01fap01b79e",
                       "AzureWebJobs.HttpTrigger1.Disabled":  "true",
                       "AzureWebJobs.transformfunction.Disabled":  "True"
                   }
}
#>
function global:Disable-AzureFunction
{
param(
    [parameter(Mandatory=$true)][string]$ResourceGroupName,
    [parameter(Mandatory=$true)][string]$FunctionAppName,
    [parameter(Mandatory=$true)][string]$FunctionName)
    enableDisableAzureFunction -ResourceGroupName $ResourceGroupName -FunctionAppName $FunctionAppName -FunctionName $FunctionName -EnableOrDisable Disable;
}


<#
.SYNOPSIS
  Enables or Disables an Azure Function.

.DESCRIPTION
  Enables or Disables an Azure Function.

.PARAMETER <ResourceGroupName>
  Name of Resource Group where the Function App is located.

.PARAMETER <FunctionAppName>
  Name of Function App that hosts the function.

.PARAMETER <FunctionName>
  Name of Function to be enabled / disabled.

.PARAMETER <EnableOrDisable>
  Must be either 'Enable' or 'Disable'.

.OUTPUTS
  Generic Function properties.
  
.EXAMPLE
 
 enableDisableAzureFunction -ResourceGroupName lk01rgr01 -FunctionAppName lk01fap01 -FunctionName transformfunction -EnableOrDisable Disable | ConvertTo-Json
{
    "id":  "/subscriptions/a08fca8b-e7e8-445a-94e1-6bf714ce5ba4/resourceGroups/lk01rgr01/providers/Microsoft.Web/sites/lk01fap01/config/appsettings",
    "name":  "appsettings",
    "type":  "Microsoft.Web/sites/config",
    "location":  "West US",
    "tags":  {

             },
    "properties":  {
                       "FUNCTIONS_EXTENSION_VERSION":  "~3",
                       "FUNCTIONS_WORKER_RUNTIME":  "powershell",
                       "AzureWebJobsStorage":  "DefaultEndpointsProtocol=https;AccountName=XXXX;AccountKey=YYYY;EndpointSuffix=core.windows.net",
                       "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING":  "DefaultEndpointsProtocol=https;AccountName=AAAAAA;AccountKey=BBBBBBB;EndpointSuffix=core.windows.net",
                       "WEBSITE_CONTENTSHARE":  "lk01fap01b79e",
                       "AzureWebJobs.HttpTrigger1.Disabled":  "true",
                       "AzureWebJobs.transformfunction.Disabled":  "True"
                   }
}
#>
# enableDisableAzureFunction
function global:enableDisableAzureFunction
{
    param(
        [parameter(Mandatory=$true)][string]$ResourceGroupName,
        [parameter(Mandatory=$true)][string]$FunctionAppName,
        [parameter(Mandatory=$true)][string]$FunctionName,
        [parameter(Mandatory=$true)][ValidateSet('Enable','Disable')][string]$EnableOrDisable)

    if ((get-module Az.Resources) -eq $null) { Install-Module -Name Az.Resources -Force -AllowClobber; }
    
    $header = Get-AzureBasicHeader;
    $url = "https://management.azure.com/subscriptions/$global:AzureSubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/config/appSettings/list?api-version=2018-11-01";
    $rsp = Invoke-RestMethod -Method Post -Uri $url -Headers $header;
    $propertyName = "AzureWebJobs.$($FunctionName).Disabled";
    $isDisabled = ($EnableOrDisable -eq 'Disable');

    if ($rsp.Properties."$propertyName" -eq $null)
    {
        Add-Member -InputObject $fap.Properties -MemberType NoteProperty -Name $propertyName -Value $isDisabled;
    }
    else
    {
        $rsp.Properties."$propertyName" = $isDisabled;
    }

    $body = $rsp | ConvertTo-Json;
    $url = "https://management.azure.com/subscriptions/$global:AzureSubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/config/appSettings?api-version=2018-11-01";
    return Invoke-RestMethod -Method Put -Uri $url -Headers $header -Body $body;
}

#https://dev.azure.com/skype/_apis/distributedtask/pools/243/jobrequests
