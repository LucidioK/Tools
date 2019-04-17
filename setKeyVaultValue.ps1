param(
    [parameter(Mandatory=$true,  Position=0)][string]$VaultName,
    [parameter(Mandatory=$true,  Position=1)][string]$SecretName,
    [parameter(Mandatory=$true,  Position=2)][string]$SecretValue
)

$secretValueAsSecretString = ConvertTo-SecureString $SecretValue -AsPlainText -Force;
 
Set-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $secretValueAsSecretString;
