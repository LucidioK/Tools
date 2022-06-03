<#
.SYNOPSIS
  Downloads the text of a Microsoft Teams chat.
  Important: this works only for Chats. Unfortunately, it does not work for Channels...
  
.DESCRIPTION
  This script downloads the text of a Microsoft Teams chat by sending keys: Up Arrow, then Control-C.
  So, if the chat is rather long, this might take an extensive time. It takes around 0.3s per line.
  
  It will download to a file. Next time you download the same chat to the same file, it will only append
  the new messages to the file.

  Important: this script will stop execution, display the following message and wait until you hit Enter:

    Important!
    Before starting this script, do this:
    1. Open Teams.
    2. Open the Chat or Channel named '$ChatOrChannelName'
    3. Click on the last message.
    
    Press Enter to continue:
  
  Important: Since this script performs an "ActivateWindows" for each line to be downloaded,
  you will not be able to do much while the download process is running.

.PARAMETER <ChatOrChannelName>
  Mandatory, string. The name of the Chat or the Channel to be downloaded. It is the title of the window.

.PARAMETER <OutputFilePath>
  Optional, string. Output path for the chat text.
  Default value is the ChatOrChannelName, on the current folder.
  If using the default value, the script will replace all non-alphanumeric characters to _ (underscore)
  and append the extension .txt

.PARAMETER <MaximumNumberOfLines>
  Optional, int, default value is 8192. Maximum number of chat messages to be downloaded.

.OUTPUTS
  Returns the output file full path.
  
.EXAMPLE
  # This will download the first 8192 messages of chat "Good Ol' Friends"
  # into file Good_Ol__Friends.txt.
  DownloadTeamsChat.ps1 "Good Ol' Friends"

  # If you run it a second time, some days later, it will append the messages from the last days only.
#>

param(
    [parameter(
        Mandatory   = $true , 
        Position    = 0,
        HelpMessage = "Mandatory, string. The name of the Chat or the Channel to be downloaded. It is the title of the window.")]
    [string]$ChatOrChannelName, 

    [parameter(
        Mandatory   = $false, 
        Position    = 1,
        HelpMessage = "Optional, string. Output path for the chat text. Default value is the ChatOrChannelName, on the current folder. If using the default value, the script will replace all non-alphanumeric characters to _ (underscore) and append the extension .txt")]
    [string]$OutputFilePath = ($ChatOrChannelName + ".txt"), 

    [parameter(
        Mandatory=$false, 
        Position = 2,
        HelpMessage = "Optional, int, default value is 8192. Maximum number of chat messages to be downloaded.")]
    [int]$MaximumNumberOfLines = (8 * 1024)    
)

function CopyPreviousLineFromTeams([int]$processId)
{
    $wshell.AppActivate($processId) | out-null;
    Start-Sleep -Milliseconds 100;
    $ocb = '{'; $ccb = '}';
    [System.Windows.Forms.SendKeys]::SendWait("$($ocb)UP$ccb")
    Start-Sleep -Milliseconds 100;
    $text = $null;
    for ($i = 0; $i -lt 4 -and [string]::IsNullOrEmpty($text); $i++)
    {
        [System.Windows.Forms.SendKeys]::SendWait('^(c)');
        Start-Sleep -Milliseconds (($i+1)*100);
        $text = Get-Clipboard;
    }

    if (!([string]::IsNullOrEmpty($text)))
    {
        # the text comes in the format UserName TimeStamp Message. However, the timestamp is not separated from
        # the UserName and Message, so I am adding spaces here.
        $timeStampPattern = '[0-9]{1,2}/[0-9]{1,2}/[0-9]{1,4} [0-9]{1,2}:[0-9]{1,2} [AP]M';
        # First, try with full date time format.
        $timeStamp = extractWithRegex $text "($timeStampPattern)";
        if ([string]::IsNullOrEmpty($timeStamp))
        {
            $timeStampPattern = '[0-9]{1,2}:[0-9]{1,2} [AP]M';
            $timeStamp = extractWithRegex $text "($timeStampPattern)";
            if ([string]::IsNullOrEmpty($timeStamp))
            {
                return '';
            }
            [int]$year   = (get-date).Year;
            [int]$month  = (get-date).Month;
            [int]$day    = (get-date).Day;
            [int]$hour   = extractwithregex $timeStamp  '([0-9]{1,2}):[0-9]{1,2}';
            if ($timeStamp -match 'PM') { $hour += 12; }
            [int]$minute = extractwithregex $timeStamp  '[0-9]{1,2}:([0-9]{1,2})';
            $timeStamp = [DateTime]::new($year, $month, $day, $hour, $minute, 0);
        }
        else
        {
            $timeStamp = [DateTime]::Parse((extractWithRegex $text "($timeStampPattern)"));
        }
        $timeStamp = $timeStamp.ToString('yyyy/MM/dd HH:mm')
        $userName  = extractWithRegex $text "(.*?)$timeStampPattern";
        $message   = extractWithRegex $text ".*?$timeStampPattern(.*)";
        $text = "$timeStamp $($userName): $message";
    }
    return $text;  
}

function extractWithRegex([string]$str, [string]$patternWithOneGroupMarker)
{
    if ($str -match $patternWithOneGroupMarker)
    {
        return $matches[1];
    }
    return $null;
}

function getMessageTimestamp([string]$msg)
{
    if ([string]::IsNullOrEmpty($msg) -or $msg -notmatch '[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}')
    {
        return $null;
    }

    $ts        = extractwithregex $msg '([0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2})';
    $year      = extractwithregex $ts  '([0-9]{4})/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}';
    $month     = extractwithregex $ts  '[0-9]{4}/([0-9]{2})/[0-9]{2} [0-9]{2}:[0-9]{2}';
    $day       = extractwithregex $ts  '[0-9]{4}/[0-9]{2}/([0-9]{2}) [0-9]{2}:[0-9]{2}';
    $hour      = extractwithregex $ts  '[0-9]{4}/[0-9]{2}/[0-9]{2} ([0-9]{2}):[0-9]{2}';
    $minute    = extractwithregex $ts  '[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:([0-9]{2})';
    $timeStamp = [DateTime]::new($year, $month, $day, $hour, $minute, 0);

    return $timeStamp;
}

$FileName = [System.IO.Path]::GetFileName($OutputFilePath);
# Convert all weird character on the file name characters to _
$FileName = $FileName  -replace '[^A-Za-z0-9\.]','_';
$Directory = [System.IO.Path]::GetDirectoryName($OutputFilePath);
if ([string]::IsNullOrEmpty($Directory))
{
    $OutputFilePath = $FileName;
}
else 
{
    $OutputFilePath = Join-Path $Directory $FileName;
}

if (Test-Path $OutputFilePath)
{
    $previousLines = Get-Content $OutputFilePath;
    $latestDate    = ($previousLines | ForEach-Object { getMessageTimestamp $_; } | Measure-Object -Maximum).Maximum;
}
else 
{
    $previousLines = @();
    $latestDate    = [DateTime]::MaxValue;
}

Write-Host "Important!" -ForegroundColor Yellow;
Write-Host "Before starting this script, do this:" -ForegroundColor Yellow;
Write-Host "1. Open Teams." -ForegroundColor Yellow;
Write-Host "2. Open the Chat or Channel named '$ChatOrChannelName'"  -ForegroundColor Yellow;
Write-Host "3. Click on the last message." -ForegroundColor Yellow;
Write-Host "4. Disable sleep or lock screen." -ForegroundColor Yellow;
Write-Host "";
Write-Host "Press Enter to continue:" -ForegroundColor Yellow;
Read-Host;

[string]$ChatOrChannelNameClean = "";
for ($i = 0; $i -lt $ChatOrChannelName.Length; $i++)
{
    $c = $ChatOrChannelName[$i];
    if ($c -notmatch '[A-Za-z0-9 ]') { $c = ('\' + $c); }
    $ChatOrChannelNameClean += $c;
}

$processId =  (Get-Process *teams*  | Where-Object { $_.MainWindowTitle -match $ChatOrChannelNameClean} ).id;
if ($null -eq $processId)
{
    throw "Could not find a teams process with main window title '$ChatOrChannelName'";
}

Add-Type -AssemblyName System.Windows.Forms;
$wshell = New-Object -ComObject WScript.Shell;
$previousMessage = "<NONE>";
$sameMessageCounter = 0;
$lines = @();
for ($i = 0; $i -lt $MaximumNumberOfLines; $i++) 
{
    [string]$messageText = CopyPreviousLineFromTeams $processId;
    Write-Progress -Activity $messageText.PadRight(64).Substring(0, 64) -PercentComplete 0;
    $timeStamp = getMessageTimestamp $messageText;
    if ($null -ne $timeStamp -and $timeStamp -ge $latestDate)
    {
        break;
    }

    if ($messageText -eq $previousMessage -or $null -eq $messageText)
    {
        $sameMessageCounter++;
        Start-Sleep -Milliseconds ($sameMessageCounter*200);
    }
    else 
    {
        $sameMessageCounter = 0;
    }

    if ($sameMessageCounter -gt 8)
    {
        break;
    }

    if ($sameMessageCounter -eq 0)
    {
        $lines = @($messageText) + $lines;
    }

    $previousMessage = $messageText;
}

$lines = $previousLines + $lines;
$lines | Out-File $OutputFilePath;

Write-Host "$i messages captured into $(Resolve-Path $OutputFilePath)" -ForegroundColor Green;

return $OutputFilePath;
