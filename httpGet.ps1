param(
    [parameter(Mandatory=$True, Position=0)][string]$uri
)
add-type "public class Response { public int StatusCode {get;set;} public string Content{get;set;}}";
$response=Invoke-WebRequest -Method Get -Uri $uri;
[string]$content="";
if ($response.Content.GetType().Name -eq 'Byte[]')
{
    $content = [System.Text.Encoding]::ASCII.GetString($response.Content);
}
else
{
    $content = $response.Content;
}
$returnedResponse = $foundLine = New-Object Response;

$returnedResponse.StatusCode = $response.StatusCode;
$returnedResponse.Content    = $content;

return $returnedResponse;
