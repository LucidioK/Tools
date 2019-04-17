if ($global:Outlook -ne $null)
{
    $global:Outlook.Quit();
    $global:Outlook = $null;
}
class IdAttRtSub
{
    [String]  $Id
    [Int]     $AttachmentCount
    [Nullable[DateTime]]$ReceivedTime
    [String]  $Subject
    [Int]     $Position
    [String]  $SenderAddress
    [String]  $Categories
    IdAttSub(){}
}

class TimedCommand
{
    [PowerShell]$ps;
    [int]       $timeoutInMilliseconds;
    [object]    $job;
    [bool]      $jobCompleted;
    [ScriptBlock]$block;
    TimedCommand([ScriptBlock]$block, [int]$timeoutInMilliseconds)
    {
        $this.block = $block;
        $this.timeoutInMilliseconds = $timeoutInMilliseconds;
        $this.jobCompleted = $false;
    }

    [bool] Run([object[]]$parameters)
    {
        $this.ps = [PowerShell]::Create().AddScript($this.block);
        foreach ($parameter in $parameters)
        {
            $this.ps.AddArgument($parameter);
        }
        $this.jobCompleted = $false;
        $start = get-date;
        $this.job = $this.ps.BeginInvoke();
        Start-Sleep -Milliseconds 1;
        $this.jobCompleted = $this.job.IsCompleted;
        while (!($this.jobCompleted) -and (((get-date) - $start).TotalMilliseconds) -lt $this.timeoutInMilliseconds)
        {
            Start-Sleep -Milliseconds 10;
            $this.jobCompleted = $this.job.IsCompleted;
        }
        return $this.jobCompleted;
    }

    [object] GetResult()
    {
        $result = $null;
        if ($this.jobCompleted) 
        {
            $result = $this.ps.EndInvoke($this.job);
        }

        return $result;
    }

    [void] Dispose()
    {
        $this.ps.Stop();
        $this.ps.Dispose();
    }
}

function IdAttSubFromItem($i, $item, $receivedTime)
{
    $iars                 = [IdAttRtSub]::new();
    $iars.AttachmentCount = $item.Attachments.Count;
    $iars.Id              = $item.EntryId;
    $iars.ReceivedTime    = $receivedTime;
    $iars.Subject         = $item.Subject;
    $iars.Position        = $i;
    if ($item.Sender -ne $null)
    {
        $exchangeUser = $item.Sender.GetExchangeUser();
        if ($exchangeUser -ne $null)
        {
            $iars.SenderAddress = $exchangeUser.PrimarySmtpAddress;
        }
    }
    if (!([string]::IsNullOrEmpty($item.Categories)))
    {
        $iars.Categories = [string]::Join(',', $item.Categories);
    }
    return $iars;
}

function addToAllItems($i, $item)
{
    if ($global:allItems.ContainsKey($item.EntryID))
    {
        $global:allItems.Remove($item.EntryID);
    }
    $global:allItems.Add($item.EntryID, $item);
}

function cleanupOutlook()
{
    Write-Host "Cleaning up Outlook components..." -ForegroundColor Green;
    get-job -Name 'GetReceivedTime' -ErrorAction Ignore | remove-job;
    $global:Outlook.Quit();
    $global:Outlook = $null;
    $global:allItems = $null;
    $global:items = $null;
    $global:Inbox = $null;
}

function startOutlook()
{
    Write-Host "Initializing Outlook components..." -ForegroundColor Green;
    Add-Type -assembly "Microsoft.Office.Interop.Outlook";
    $global:Outlook = New-Object -comobject Outlook.Application;
    $global:Namespace = $global:Outlook.GetNameSpace("MAPI");
    $global:Inbox = $global:Namespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderInbox);
}

function restartOutlookIfNeeded()
{
    if ((get-process -Name 'outlook' -ErrorAction Ignore) -eq $null)
    {
        startOutlook;
    }
}

function getReceivedDate($item)
{

}

$esc = [char]27;
$gotoFirstColumn = "$esc[0G"

get-process -Name 'outlook' -ErrorAction Ignore | Stop-Process
startOutlook;

#$global:items = $global:Inbox.Items | sort Subject, ReceivedTime -Descending
$i = 0;
$global:items = @();
$now = get-date;
$global:allItems = @{};
Write-Host "Reading items..." -ForegroundColor Green;
$left = [Console]::CursorLeft;
$top =  [Console]::CursorTop;


$global:idsToDelete = @();


foreach ($item in $global:Inbox.Items)
{
    [double]$itemCount = $global:Inbox.Items.Count;
    $TimedCommand = [TimedCommand]::new({ param($item); return $item.ReceivedTime; }, 5000);
    $commandCompleted = $TimedCommand.Run($item);

    if ($commandCompleted)
    {
        $rt = $TimedCommand.GetResult();
        [Nullable[DateTime]]$receivedTime = $null;
        if ($rt -NE $NULL -and $rt.GetType().Name.ToLowerInvariant().StartsWith('psdatacollection') -and $rt[0].GetType().Name -eq 'DateTime')
        {
            $receivedTime = $rt[0];
        }
        else
        {
            $receivedTime = $null;
        }
        if ($receivedTime -eq $null)
        {
            $global:idsToDelete += $item.EntryID;
            addToAllItems $i $item;
            Write-Host "Will erase $i [$($item.Subject)] because it does not have a received time." -ForegroundColor Magenta;
        }
        else
        {

            $elapsed = $now - $receivedTime;
            if (($elapsed).TotalDays -le 120)
            {

                $global:items += (IdAttSubFromItem $i $item $receivedTime);
            }
            addToAllItems $i $item;
        }
    }
    else
    {
        Write-Host "Could not read item at position $i ..." -ForegroundColor Magenta;
    }
    #$TimedCommand.Dispose();
    #$global:allItems += (IdAttSubFromItem $i $item);
    $i++;

    [int]$percentComplete = $i * 100 / $itemCount
    Write-Progress -Activity "Reading items (1/3)..." -Status "$i / $itemCount ($percentComplete %) ($($global:items.Count) items < 120d) Complete:" -PercentComplete $percentComplete;
}

#$global:allItems = $global:allItems | sort Subject, ReceivedTime -Descending | select Position, Subject, ReceivedTime;

Write-Host "Post processing..." -ForegroundColor Green;

$global:items = $global:items | sort Subject, ReceivedTime -Descending;

[double]$itemCount = $global:items.Count;
for ($i = 0; $i -lt $global:items.Count; $i++)
{
    $subject = $global:items[$i].Subject;
    if ($subject.Contains('UnregisterFunction and ListFunctions endpoints'))
    {
        Write-Host $global:items[$i];
    }
    for ($j = $i + 1; $j -lt $global:items.Count -and $global:items[$j].Subject -eq $subject; $j++)
    {
        if ($global:items[$j].AttachmentCount -eq 0 -or [string]::IsNullOrEmpty($global:items[$j].Categories))
        {
            $global:idsToDelete += $global:items[$j].Id;
        }
        else
        {
            write-host "Not deleting [$subject] [$($global:items[$j].Id)] because it has $($global:items[$j].AttachmentCount) attachment(s), or because it has categories [$($global:items[$j].Categories)]." -ForegroundColor Magenta;
        }
    }
    $i = $j - 1;
    [int]$percentComplete = $i * 100 / $itemCount
    Write-Progress -Activity "Post processing (2/3)..." -Status "$i / $itemCount ($percentComplete %) Complete:" -PercentComplete $percentComplete;
}

Write-Host "Deleting $($global:idsToDelete.Count) items..." -ForegroundColor Green;
$i = 0;
[double]$itemCount = $global:idsToDelete.Count;
foreach ($idToDelete in $global:idsToDelete)
{
    restartOutlookIfNeeded;
    $item = $global:allItems[$idToDelete];
    Write-Host "Deleting $($item.Subject)" -ForegroundColor Green;
    $item.Delete();
    $i++;
    $percentComplete = $i * 100 / $itemCount
    Write-Progress -Activity "Deleting (3/3)..." -Status "$i / $itemCount ($percentComplete %) Complete:" -PercentComplete $percentComplete;
}

cleanupOutlook;

