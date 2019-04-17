if ($global:Outlook -ne $null)
{
    $global:Outlook.Quit();
    $global:Outlook = $null;
}
class IdAttRtSub
{
    [String]  $Id
    [Int]     $AttachmentCount
    [DateTime]$ReceivedTime
    [String]  $Subject
    [Int]     $Position
    [String]  $SenderAddress
    [String]  $Categories
    IdAttSub(){}
}

class TimedScript {
    [System.Timers.Timer] $Timer        = [System.Timers.Timer]::new();
    [runspace]            $Runspace     = [runspacefactory]::CreateRunspace();
    [powershell]          $PowerShell;
    [System.IAsyncResult] $IAsyncResult;

    TimedScript([ScriptBlock] $ScriptBlock, [int] $Timeout) 
    {    
        $this.PowerShell = [powershell]::Create();
        $this.PowerShell.AddScript($ScriptBlock);
        $this.PowerShell.Runspace = $this.Runspace;

        $this.Timer.Interval = $Timeout

        Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -MessageData $this -Action ({
            $Job = $event.MessageData;
            $Job.PowerShell.Stop();
            $Job.Runspace.Close();
            $Job.Timer.Enabled = $False;
        })
    }

    [void] Start() 
    {
        $this.Runspace.Open();
        $this.Timer.Start();
        $this.IAsyncResult = $this.PowerShell.BeginInvoke();
    }

    [object[]] GetResult() 
    {
        return $this.PowerShell.EndInvoke($this.IAsyncResult);
    }
}

function IdAttSubFromItem($i, $item)
{
    $iars                 = [IdAttRtSub]::new();
    $iars.AttachmentCount = $item.Attachments.Count;
    $iars.Id              = $item.EntryId;
    $iars.ReceivedTime    = $item.ReceivedTime;
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
[double]$itemCount = $global:Inbox.Items.Count;

if ((get-variable 'indexesThatGotStuckDuringCleanupOutlookEmails' -ErrorAction Ignore) -eq $null)
{
    [System.Collections.ArrayList]$global:indexesThatGotStuckDuringCleanupOutlookEmails = [System.Collections.ArrayList]::new();
    $global:indexesThatGotStuckDuringCleanupOutlookEmails.Add(-1);
}

$global:idsToDelete = @();

$receivedTimeBlock = { param($item); return $item.ReceivedTime; }

foreach ($item in $global:Inbox.Items)
{
    get-job -Name 'GetReceivedTime' -ErrorAction Ignore | remove-job;
    $j = (Start-Job -ScriptBlock $receivedTimeBlock -Name 'GetReceivedTime' -ArgumentList $item | Wait-Job -Timeout 5);
    if ($j -ne $null)
    {
        $receivedTime = Receive-Job -Job $j;

        if ($receivedTime -eq $null)
        {
            $global:idsToDelete += $item.EntryID;
            addToAllItems $i $item;
            Write-Host "Will erase $i [$($item.Subject)] because it does not have a received time." -ForegroundColor Magenta;
        }
        else
        {
            $elapsed = $now-$receivedTime;
            if (($elapsed).TotalDays -le 120)
            {

                $global:items += (IdAttSubFromItem $i $item);
            }
            addToAllItems $i $item;
        }
    }
    else
    {
        Write-Host "Could not read item at position $i ..." -ForegroundColor Magenta;
    }

    #$global:allItems += (IdAttSubFromItem $i $item);
    $i++;

    [int]$percentComplete = $i * 100 / $itemCount
    Write-Progress -Activity "Reading items (1/3)..." -Status "$i / $itemCount ($percentComplete %) ($($global:items.Count) items < 90d) Complete:" -PercentComplete $percentComplete;
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
remove-variable 'indexesThatGotStuckDuringCleanupOutlookEmails';
