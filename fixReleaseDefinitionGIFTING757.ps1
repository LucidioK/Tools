param($releaseDefinitionName)
LK-Tool-DeleteReleaseDefinitionStep -sourceDefinitionName $releaseDefinitionName -sourceEnvironmentRegularExpression .* -sourceTaskRegularExpression ".*prepare eGiftServiceBusTopics.*"
LK-Tool-DeleteReleaseDefinitionStep -sourceDefinitionName $releaseDefinitionName -sourceEnvironmentRegularExpression .* -sourceTaskRegularExpression ".*waitForAllSubscriptionsToBeCreated.*"
LK-Tool-DeleteReleaseDefinitionStep -sourceDefinitionName $releaseDefinitionName -sourceEnvironmentRegularExpression .* -sourceTaskRegularExpression ".*Wait 30 secs.*"
LK-Tool-DeleteReleaseDefinitionStep -sourceDefinitionName $releaseDefinitionName -sourceEnvironmentRegularExpression .* -sourceTaskRegularExpression ".*Create Subscription Filters.*"
LK-Tool-DeleteReleaseDefinitionStep -sourceDefinitionName $releaseDefinitionName -sourceEnvironmentRegularExpression .* -sourceTaskRegularExpression ".*Show all build variables in build output.*"
LK-Tool-DeleteReleaseDefinitionStep -sourceDefinitionName $releaseDefinitionName -sourceEnvironmentRegularExpression .* -sourceTaskRegularExpression ".*Show all build variables in build output.*"

LK-Tool-CopyReleaseDefinitionStep -sourceDefinitionName 'eGift.Infrastructure.Develop.Release' -sourceEnvironment 'DevWest' -sourceTasknameRegularExpression 'Azure Key Vault.*keyVaultName.*' -destinationDefinitionName $releaseDefinitionName -destinationEnvironmentRegularExpression '.*' -afterAtPositionOrBefore AtPosition -TasknameRegularExpressionOrPositionNumber 1  


