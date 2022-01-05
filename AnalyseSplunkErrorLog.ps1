param([string]$splunkJsonFilePath)

$j = gc $splunkJsonFilePath | ConvertFrom-Json;

class Analysis
{
    [string]$OrderId
    [string]$TimeStamp
    [int]$StatusCode
    [string]$Reason
}

$ans = @();

foreach ($l in $j)
{
    if ($l.result.MessageTemplate -match 'Http Code: ([0-9]{3})')
    {
        $statusCode = $Matches[1];
    }
    elseif ($l.result.MessageTemplate -match 'The operation has timed out')
    {
        $statusCode = 509;
    }
    else
    {
        $statusCode = 500;
    }

    if ($l.result.MessageTemplate -match 'Your request had the following errors:[\n\r]*(.*)')
    {
        $reason = $Matches[1];
    }
    elseif ($l.result.MessageTemplate -match '(ReasonCode = .*)')
    {
        $reason = $Matches[1];
    }
    elseif ($l.result.MessageTemplate -match 'Cashstar Error: (.*)')
    {
        $reason = $Matches[1];
    }

    if ($l.result.MessageTemplate -match 'Request: ([A-Z0-9]{26})')
    {
        $orderId = $Matches[1];
    }
    $an = New-Object -TypeName 'Analysis';
    $an.StatusCode = $StatusCode;
    $an.OrderId    = $orderId;
    $an.Reason     = $reason;
    $an.TimeStamp  = $l.result.TimeStamp;
    $ans          += $an;
}

return $ans | sort OrderId,TimeStamp;

