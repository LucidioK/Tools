#
# Utils.ps1
#
Add-Type -AssemblyName System.IO.Compression.FileSystem;
$sqliteAssemblyPath = Join-Path $PSScriptRoot "System.Data.SQLite.dll";
if (Test-Path $sqliteAssemblyPath)
{
    Add-Type -Path $sqliteAssemblyPath;
    $global:sqliteLoaded = $true;
}
else
{
    $global:sqliteLoaded = $false;
    Write-Host "Could not find $sqliteAssemblyPath, SQLite not available..." -ForegroundColor Magenta;
}

[string]$global:docker="";
[string]$global:curl  ="";
$global:mostCommonWordsInEnglish = ('I', 'a', 'able', 'about', 'above', 'act', 'add', 'afraid', 'after', 'again', 'against', 'age', 'ago', 'agree', 'air', 'all', 'allow', 'also', 'always', 'am', 'among', 'an', 'and', 'anger', 'animal', 'answer', 'any', 'appear', 'apple', 'are', 'area', 'arm', 'arrange', 'arrive', 'art', 'as', 'ask', 'at', 'atom', 'baby', 'back', 'bad', 'ball', 'band', 'bank', 'bar', 'base', 'basic', 'bat', 'be', 'bear', 'beat', 'beauty', 'bed', 'been', 'before', 'began', 'begin', 'behind', 'believe', 'bell', 'best', 'better', 'between', 'big', 'bird', 'bit', 'black', 'block', 'blood', 'blow', 'blue', 'board', 'boat', 'body', 'bone', 'book', 'born', 'both', 'bottom', 'bought', 'box', 'boy', 'branch', 'bread', 'break', 'bright', 'bring', 'broad', 'broke', 'brother', 'brought', 'brown', 'build', 'burn', 'busy', 'but', 'buy', 'by', 'call', 'came', 'camp', 'can', 'capital', 'captain', 'car', 'card', 'care', 'carry', 'case', 'cat', 'catch', 'caught', 'cause', 'cell', 'cent', 'center', 'century', 'certain', 'chair', 'chance', 'change', 'character', 'charge', 'chart', 'check', 'chick', 'chief', 'child', 'children', 'choose', 'chord', 'circle', 'city', 'claim', 'class', 'clean', 'clear', 'climb', 'clock', 'close', 'clothe', 'cloud', 'coast', 'coat', 'cold', 'collect', 'colony', 'color', 'column', 'come', 'common', 'company', 'compare', 'complete', 'condition', 'connect', 'consider', 'consonant', 'contain', 'continent', 'continue', 'control', 'cook', 'cool', 'copy', 'corn', 'corner', 'correct', 'cost', 'cotton', 'could', 'count', 'country', 'course', 'cover', 'cow', 'crease', 'create', 'crop', 'cross', 'crowd', 'cry', 'current', 'cut', 'dad', 'dance', 'danger', 'dark', 'day', 'dead', 'deal', 'dear', 'death', 'decide', 'decimal', 'deep', 'degree', 'depend', 'describe', 'desert', 'design', 'determine', 'develop', 'dictionary', 'did', 'die', 'differ', 'difficult', 'direct', 'discuss', 'distant', 'divide', 'division', 'do', 'doctor', 'does', 'dog', 'dollar', 'dont', 'done', 'door', 'double', 'down', 'draw', 'dream', 'dress', 'drink', 'drive', 'drop', 'dry', 'duck', 'during', 'each', 'ear', 'early', 'earth', 'ease', 'east', 'eat', 'edge', 'effect', 'egg', 'eight', 'either', 'electric', 'element', 'else', 'end', 'enemy', 'energy', 'engine', 'enough', 'enter', 'equal', 'equate', 'especially', 'even', 'evening', 'event', 'ever', 'every', 'exact', 'example', 'except', 'excite', 'exercise', 'expect', 'experience', 'experiment', 'eye', 'face', 'fact', 'fair', 'fall', 'family', 'famous', 'far', 'farm', 'fast', 'fat', 'father', 'favor', 'fear', 'feed', 'feel', 'feet', 'fell', 'felt', 'few', 'field', 'fig', 'fight', 'figure', 'fill', 'final', 'find', 'fine', 'finger', 'finish', 'fire', 'first', 'fish', 'fit', 'five', 'flat', 'floor', 'flow', 'flower', 'fly', 'follow', 'food', 'foot', 'for', 'force', 'forest', 'form', 'forward', 'found', 'four', 'fraction', 'free', 'fresh', 'friend', 'from', 'front', 'fruit', 'full', 'fun', 'game', 'garden', 'gas', 'gather', 'gave', 'general', 'gentle', 'get', 'girl', 'give', 'glad', 'glass', 'go', 'gold', 'gone', 'good', 'got', 'govern', 'grand', 'grass', 'gray', 'great', 'green', 'grew', 'ground', 'group', 'grow', 'guess', 'guide', 'gun', 'had', 'hair', 'half', 'hand', 'happen', 'happy', 'hard', 'has', 'hat', 'have', 'he', 'head', 'hear', 'heard', 'heart', 'heat', 'heavy', 'held', 'help', 'her', 'here', 'high', 'hill', 'him', 'his', 'history', 'hit', 'hold', 'hole', 'home', 'hope', 'horse', 'hot', 'hot', 'hour', 'house', 'how', 'huge', 'human', 'hundred', 'hunt', 'hurry', 'ice', 'idea', 'if', 'imagine', 'in', 'inch', 'include', 'indicate', 'industry', 'insect', 'instant', 'instrument', 'interest', 'invent', 'iron', 'is', 'island', 'it', 'job', 'join', 'joy', 'jump', 'just', 'keep', 'kept', 'key', 'kill', 'kind', 'king', 'knew', 'know', 'lady', 'lake', 'land', 'language', 'large', 'last', 'late', 'laugh', 'law', 'lay', 'lead', 'learn', 'least', 'leave', 'led', 'left', 'leg', 'length', 'less', 'let', 'letter', 'level', 'lie', 'life', 'lift', 'light', 'like', 'line', 'liquid', 'list', 'listen', 'little', 'live', 'locate', 'log', 'lone', 'long', 'look', 'lost', 'lot', 'loud', 'love', 'low', 'machine', 'made', 'magnet', 'main', 'major', 'make', 'man', 'many', 'map', 'mark', 'market', 'mass', 'master', 'match', 'material', 'matter', 'may', 'me', 'mean', 'meant', 'measure', 'meat', 'meet', 'melody', 'men', 'metal', 'method', 'middle', 'might', 'mile', 'milk', 'million', 'mind', 'mine', 'minute', 'miss', 'mix', 'modern', 'molecule', 'moment', 'money', 'month', 'moon', 'more', 'morning', 'most', 'mother', 'motion', 'mount', 'mountain', 'mouth', 'move', 'much', 'multiply', 'music', 'must', 'my', 'name', 'nation', 'natural', 'nature', 'near', 'necessary', 'neck', 'need', 'neighbor', 'never', 'new', 'next', 'night', 'nine', 'no', 'noise', 'noon', 'nor', 'north', 'nose', 'note', 'nothing', 'notice', 'noun', 'now', 'number', 'numeral', 'object', 'observe', 'occur', 'ocean', 'of', 'off', 'offer', 'office', 'often', 'oh', 'oil', 'old', 'on', 'once', 'one', 'only', 'open', 'operate', 'opposite', 'or', 'order', 'organ', 'original', 'other', 'our', 'out', 'over', 'own', 'oxygen', 'page', 'paint', 'pair', 'paper', 'paragraph', 'parent', 'part', 'particular', 'party', 'pass', 'past', 'path', 'pattern', 'pay', 'people', 'perhaps', 'period', 'person', 'phrase', 'pick', 'picture', 'piece', 'pitch', 'place', 'plain', 'plan', 'plane', 'planet', 'plant', 'play', 'please', 'plural', 'poem', 'point', 'poor', 'populate', 'port', 'pose', 'position', 'possible', 'post', 'pound', 'power', 'practice', 'prepare', 'present', 'press', 'pretty', 'print', 'probable', 'problem', 'process', 'produce', 'product', 'proper', 'property', 'protect', 'prove', 'provide', 'pull', 'push', 'put', 'quart', 'question', 'quick', 'quiet', 'quite', 'quotient', 'race', 'radio', 'rail', 'rain', 'raise', 'ran', 'range', 'rather', 'reach', 'read', 'ready', 'real', 'reason', 'receive', 'record', 'red', 'region', 'remember', 'repeat', 'reply', 'represent', 'require', 'rest', 'result', 'rich', 'ride', 'right', 'ring', 'rise', 'river', 'road', 'rock', 'roll', 'room', 'root', 'rope', 'rose', 'round', 'row', 'rub', 'rule', 'run', 'safe', 'said', 'sail', 'salt', 'same', 'sand', 'sat', 'save', 'saw', 'say', 'scale', 'school', 'science', 'score', 'sea', 'search', 'season', 'seat', 'second', 'section', 'see', 'seed', 'seem', 'segment', 'select', 'self', 'sell', 'send', 'sense', 'sent', 'sentence', 'separate', 'serve', 'set', 'settle', 'seven', 'several', 'shall', 'shape', 'share', 'sharp', 'she', 'sheet', 'shell', 'shine', 'ship', 'shoe', 'shop', 'shore', 'short', 'should', 'shoulder', 'shout', 'show', 'side', 'sight', 'sign', 'silent', 'silver', 'similar', 'simple', 'since', 'sing', 'single', 'sister', 'sit', 'six', 'size', 'skill', 'skin', 'sky', 'slave', 'sleep', 'slip', 'slow', 'small', 'smell', 'smile', 'snow', 'so', 'soft', 'soil', 'soldier', 'solution', 'solve', 'some', 'son', 'song', 'soon', 'sound', 'south', 'space', 'speak', 'special', 'speech', 'speed', 'spell', 'spend', 'spoke', 'spot', 'spread', 'spring', 'square', 'stand', 'star', 'start', 'state', 'station', 'stay', 'stead', 'steam', 'steel', 'step', 'stick', 'still', 'stone', 'stood', 'stop', 'store', 'story', 'straight', 'strange', 'stream', 'street', 'stretch', 'string', 'strong', 'student', 'study', 'subject', 'substance', 'subtract', 'success', 'such', 'sudden', 'suffix', 'sugar', 'suggest', 'suit', 'summer', 'sun', 'supply', 'support', 'sure', 'surface', 'surprise', 'swim', 'syllable', 'symbol', 'system', 'table', 'tail', 'take', 'talk', 'tall', 'teach', 'team', 'teeth', 'tell', 'temperature', 'ten', 'term', 'test', 'than', 'thank', 'that', 'the', 'their', 'them', 'then', 'there', 'these', 'they', 'thick', 'thin', 'thing', 'think', 'third', 'this', 'those', 'though', 'thought', 'thousand', 'three', 'through', 'throw', 'thus', 'tie', 'time', 'tiny', 'tire', 'to', 'together', 'told', 'tone', 'too', 'took', 'tool', 'top', 'total', 'touch', 'toward', 'town', 'track', 'trade', 'train', 'travel', 'tree', 'triangle', 'trip', 'trouble', 'truck', 'true', 'try', 'tube', 'turn', 'twenty', 'two', 'type', 'under', 'unit', 'until', 'up', 'us', 'use', 'usual', 'valley', 'value', 'vary', 'verb', 'very', 'view', 'village', 'visit', 'voice', 'vowel', 'wait', 'walk', 'wall', 'want', 'war', 'warm', 'was', 'wash', 'watch', 'water', 'wave', 'way', 'we', 'wear', 'weather', 'week', 'weight', 'well', 'went', 'were', 'west', 'what', 'wheel', 'when', 'where', 'whether', 'which', 'while', 'white', 'who', 'whole', 'whose', 'why', 'wide', 'wife', 'wild', 'will', 'win', 'wind', 'window', 'wing', 'winter', 'wire', 'wish', 'with', 'woman', 'women', 'wont', 'wonder', 'wood', 'word', 'work', 'world', 'would', 'write', 'written', 'wrong', 'wrote', 'yard', 'year', 'yellow', 'yes', 'yet', 'you', 'young', 'your');

#if ((get-module pester) -eq $null)
#{
#    install-module pester -Force -SkipPublisherCheck;
#}

if ((get-command -Name 'Add-TeamAccount') -eq $null)
{
    Save-Module -Name Team  -Path C:\temp\PowerShell;
    Install-Module -Name Team ;
    Import-Module Team
}


$global:JsonBeautifierJsonBeautifyDefined = $false;

$global:MaxRetries = 8;


function global:getListOfFilesForNaniIndexInGitFolder()
{
    $undesired = '^\..*|.*_locales.*|.*\.txt|.*/external/.*|.*/assets/.*|.*\.exe.*|.*\.dll.*|.*\.png.*|.*\.ico.*|.*\.bin.*|.*\.nsi.*|.*\.gitignore.*|.*\.svg.*|.*\.map|.*/packages/.*|".*/node_modules/.*"|\.lst|test|\.xml';
    $l = git ls-files | where { $_ -notmatch $undesired };
    return $l;
}

function global:getUninstallData([string]$displayNameRegEx)
{
    gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -match $displayNameRegEx } | select -First 1;
}

function global:isApplicationInstalled([string]$displayNameRegEx)
{
    ( gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -match $displayNameRegEx } | select -First 1) -ne $null
}

function global:uninstallApplication([string]$displayNameRegEx)
{
    $ud =  gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -match $displayNameRegEx } | select -First 1;
    if ($ud -ne $null)
    {
        Write-Host "Uninstalling $($ud.DisplayName), version $($ud.DisplayVersion) " -ForegroundColor Green;
        $uninstallString = $ud.UninstallString.Replace('/I{', '/X{');
        
        if ($uninstallString -notmatch '/quiet')
        {
            $uninstallString += ' /quiet';
        }

        cmd /c $uninstallString;
        return $true;
    }
    else
    {
        Write-Host "Application $($ud.DisplayName) not found." -ForegroundColor Yellow;
        return $false;
    }
}

Function global:addToPath([string]$newDirectory)
{
    $OldPath=(Get-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINESystemCurrentControlSetControlSession ManagerEnvironment’ -Name PATH).Path

    IF (!$newDirectory)
    { 
        write-host "No Folder Supplied. $ENV:PATH Unchanged" -ForegroundColor Yellow;
        return $OldPath;
    }

    IF (!(TEST-PATH $newDirectory))
    { 
        Write-Host "Folder Does not Exist, Cannot be added to $ENV:PATH" -ForegroundColor Yellow;
        return $OldPath;
    }

    IF ($ENV:PATH | Select-String -SimpleMatch $newDirectory)
    { 
        Write-Host "Folder already within $ENV:PATH" -ForegroundColor Yellow;
        return $OldPath;
    }

    $NewPath=$OldPath+’;’+$newDirectory

    Set-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINESystemCurrentControlSetControlSession ManagerEnvironment’ -Name PATH –Value $newPath

    Return $NewPath
}


function global:executeWindowsCommand([string]$command)
{
    cmd /c $command;
}

function global:EWC($c1,$c2,$c3,$c4,$c5,$c6,$c7 )
{
    $c="";
    if ($c1 -ne $null) { $c += "$c1 "; }
    if ($c2 -ne $null) { $c += "$c2 "; }
    if ($c3 -ne $null) { $c += "$c3 "; }
    if ($c4 -ne $null) { $c += "$c4 "; }
    if ($c5 -ne $null) { $c += "$c5 "; }
    if ($c6 -ne $null) { $c += "$c6 "; }
    if ($c7 -ne $null) { $c += "$c7 "; }


    global:executeWindowsCommand $c;
}

function global:getSizeOfMaximumStringFromList([string[]]$stringList)
{
    return (($stringList | where { $_ -ne $null } | where { $_.GetType().Name -eq 'string' } | Select-Object -ExpandProperty Length | Measure-Object -Maximum).Maximum);
}

function global:gitPullAllSubfoldersOnMasterBranchUnderCurrentFolder()
{
    $dirs = (get-childitem -directory).Name;
    $padSize = (getSizeOfMaximumStringFromList $dirs) + 1;
    foreach ($dir in $dirs)
    {
        pushd .;
        Write-Host ($dir.PadRight($padSize)) -ForegroundColor Green -NoNewline;
        cd "$dir";
        $branch = global:getCurrentBranchViaGit;
        if ($branch -eq 'master')
        {
            git pull;
        }
        else
        {
            Write-Host "branch is not master, it is $branch";
        }
        popd;
    }
}

function global:gitCleanAllSubfoldersUnderCurrentFolder()
{
    $dirs = ((get-childitem -directory).Name | Resolve-Path).Path;
    $block = {
        param($dir);
        cd "$dir";
        $clean = git clean -fdx  2>&1;
        $gc = git gc --aggressive --force 2>&1;
        return ($dir + "`nClean result:`n" + $clean + "`nGC Result:" + $gc);
    };
    $r = foreachParallel $l $block
    return $r;
}

function global:getAllCommitUsersForFolder([string]$folderPath)
{
    $hs = @{};
    pushd .;
    $folderPath = Resolve-Path $folderPath;
    cd $folderPath
    $log = [string]::Join("`n",(git log --no-merges));
    while ($log -match "Author:.*<([a-z]+)@.*>")
    {
        $logCount++;
        $alias = $Matches[1];
        if (!($hs.ContainsKey($alias)))
        {
            $hs.Add($alias, 0);
        }
        $hs[$alias] = $hs[$alias] + 1;
        $p = $log.IndexOf($Matches[0]) + $Matches[0].Length;
        $log = $log.Substring($p);
    }

    popd;
    return $hs;
}


function global:deleteAllVariablesOfType([string]$typeName)
{
    $variables = get-variable;
    foreach ($variable in $variables)
    {
        $thisTypeName = $v.Value.GetType();
        if ($thisTypeName -eq $typeName)
        {
            write-host "Removing variable $($variable.Name)..." -ForegroundColor Green;
            remove-variable -Name $variable.Name;
        }
    }
}

function global:highestVersion([string[]]$versions)
{
    return ((guaranteeList $versions) | foreach { [System.Version]$_ } | sort -Descending | select -First 1).ToString();
}

function global:joinPathList([string[]]$l)
{
    $p = $l[0];
    for ($i=1;$i -lt $l.Count;$i++)
    {
        $p = Join-Path $p $l[$i];
    }
    return (Resolve-Path $p);
}


function global:loadNewtonSoftJson()
{
    loadNugetAssembly 'newtonsoft.json' 'Newtonsoft.Json.dll' $true;
    loadNugetAssembly 'newtonsoft.json.schema' 'Newtonsoft.Json.Schema.dll' $true;
}

function global:loadNugetAssembly([string]$nugetPackageName, [string]$assemblyNameWithExtension, [bool]$autoInstallIfNotFound = $false)
{
    $nugetPackageFolder = "$($env:userprofile)/.nuget/packages/$nugetPackageName";
    if (!(Test-Path $nugetPackageFolder))
    {
        if ($autoInstallIfNotFound)
        {
            nuget install $nugetPackageName;
        }
        else
        {
            throw "Please install package $nugetPackageName";
        }
    }
    $packageVersion      = highestVersion ((get-childitem -Path $nugetPackageFolder).Name);
    $libPath             = joinPathList @($nugetPackageFolder, $packageVersion, 'lib');
    $dotNetVersionFilter = "Net$([environment]::Version.Major)*";
    $dotNetVersionFolder = ((Get-ChildItem -Path $libPath -Filter $dotNetVersionFilter -Directory).Name | measure -Maximum).Maximum;
    $assemblyFullPath    = joinPathList @($nugetPackageFolder, $packageVersion, 'lib', $dotNetVersionFolder, $assemblyNameWithExtension);

    [System.Reflection.Assembly]::LoadFrom($assemblyFullPath);
}

function global:findNugetAssembly([string]$nugetPackageName, [string]$assemblyNameWithExtension)
{
    $nugetPackageFolder = "$($env:userprofile)/.nuget/packages/$nugetPackageName";
    if (!(Test-Path $nugetPackageFolder))
    {
        throw "Please install package $nugetPackageName";
    }
    $packageVersion      = highestVersion ((get-childitem -Path $nugetPackageFolder).Name);
    $libPath             = joinPathList @($nugetPackageFolder, $packageVersion, 'lib');
    $dotNetVersionFilter = "Net$([environment]::Version.Major)*";
    $dotNetVersionFolder = ((Get-ChildItem -Path $libPath -Filter $dotNetVersionFilter -Directory).Name | measure -Maximum).Maximum;
    $assemblyFullPath    = joinPathList @($nugetPackageFolder, $packageVersion, 'lib', $dotNetVersionFolder, $assemblyNameWithExtension);
    if (!(Test-Path $assemblyFullPath))
    {
        throw "$assemblyNameWithExtension not found at $assemblyFullPath ";
    }
    return $assemblyFullPath;
}

function global:sqliteConnect([string]$connectionStringOrFileName)
{
    if (Test-Path $connectionStringOrFileName)
    {
        $connectionStringOrFileName = "Data Source=$connectionStringOrFileName";
    }
    $c = [System.Data.SQLite.SQLiteConnection]::new($connectionStringOrFileName);
    $c.Open();
    return $c;
}

<#
    Example:
        class Metric
        {
	        [string]$Origin
	        [string]$RE
	        [string]$Dashboard
	        [string]$Cloud
	        [string]$Vertical
	        [string]$Application
	        [string]$Commit
	        [Nullable[DateTime]]$Time
	        [Nullable[double]]$Value
        }

    $m = [Metric]::new();
    # set values of $m...

    $c = sqliteConnect 'e:\dsv\pfMetrics.db'

    # assuming the DB pfMetrics has a table named Metric,
    # with the fields with the very same names as the class
    # Metric, above.
    $a = sqlInsert $c $m
#>
function global:sqliteInsert([System.Data.SQLite.SQLiteConnection]$connection, [Object]$rowValues)
{
    $tableName             = $rowValues.GetType().Name;
    $propertyNames         = (Get-Member -InputObject $rowValues -MemberType Property).Name;
    [string[]]$fieldNames  = @();
    [string[]]$fieldValues = @();
    foreach ($propertyName in $propertyNames)
    {
        $value             = $rowValues."$propertyName";
        if ($value -ne $null)
        {
            $fieldNames   += "[$propertyName]";
            $type          = ($value.GetType()).Name;
            $vs            = $null;
            switch -regex ($typeName)
            {
                'string' 
                { 
                    $vs    = "'$value'";
                    break;
                }
                'int*|long|short|double|float|decimal'    
                { 
                    $vs    = "$value";
                    break;
                }
                'datetime'    
                { 
                    $vs    = $value.ToUniversalTime().ToString("yyyy-MM-dd hh:mm:ss");
                    $vs    = "'$vs'"; 
                    break;
                }        
            }
            $fieldValues  += $vs;
        }
    }
    $statement             = "INSERT INTO [$tableName] ($([string]::Join(',',$fieldNames))) VALUES ($([string]::Join(',',$fieldValues)));";
    $command               = $connection.CreateCommand();
    $command.CommandText   = $statement;
    $affectedRows          = $command.ExecuteNonQuery();
    return $affectedRows;
}

function global:sqliteQuery([System.Data.SQLite.SQLiteConnection]$connection, [PSCustomObject]$rowValues)
{
    $tableName             = $rowValues.GetType().Name;
    $propertyNames         = (Get-Member -InputObject $rowValues -MemberType Property).Name;
    [string[]]$conditions  = @();
    foreach ($propertyName in $propertyNames)
    {
        $value             = $rowValues."$propertyName";
        if ($value -ne $null)
        {
            $type          = ($value.GetType()).Name;
            $vs            = $null;
            switch -regex ($type)
            {
                'string' 
                { 
                    $vs    = "'$value'";
                    break;
                }
                'int*|long|short|double|float|decimal'    
                { 
                    $vs    = "$value";
                    break;
                }
                'datetime'    
                { 
                    $vs    = $value.ToUniversalTime().ToString("yyyy-MM-dd hh:mm:ss");
                    $vs    = "'$vs'"; 
                    break;
                }        
            }
            if ($vs -ne $null)
            {
                $conditions   += "[$propertyName]=$vs";
            }
        }
    }
    $statement             = "SELECT * FROM [$tableName] WHERE $([string]::Join(" AND ", $conditions));";
    $command               = $connection.CreateCommand();
    $command.CommandText   = $statement;
    $adapter               = [System.Data.SQLite.SQLiteDataAdapter]::new($command);
    $data                  = [System.Data.DataSet]::new();
    $adapter.Fill($data);
    return ($data.Tables.Rows | select -Skip 1);
}


function global:guaranteeList([Object]$o)
{
    if ($o -ne $null -and $o.GetType().FullName -ne 'System.Object[]')
    {
        return @($o);
    }
    return $o;
}

#
# Example:
# $block = { param($p); $r = (get-random) % 2000; Start-Sleep -Milliseconds $r; return "$p,$r"; }
# $l = @('a', 'b', 'c', 'd', 'e')
# $r = foreachParallel $l $block
# [string]::Join("; ",$r)
# a,938; b,316; c,102; d,348; e,1519
function global:foreachParallel([object[]]$inputList, [ScriptBlock]$scriptBlockWithOneParam)
{
    function foreachParallelInternal([object[]]$inputList, [ScriptBlock]$scriptBlockWithOneParam)
    {
        $returnList = @();
        $jobList = @();
        foreach ($item in $inputList)
        {
            $jobList += Start-Job -ScriptBlock $scriptBlockWithOneParam -Argument $item;
        }

        Wait-Job $jobList;

        foreach ($j in $jobList)
        {
            $rj = Receive-Job $j;
            $returnList += $rj;
        }
        Remove-Job $jobList;
        return $returnList;
    }
    
    $l = foreachParallelInternal $inputList $scriptBlockWithOneParam | where { $_.GetType().Name -ne 'PSRemotingJob' };
    return (guaranteeList $l);
}

function global:randomString([int]$size = 32, [string]$baseCharacters="ABCDEFGHIJKLMNOPQRSTUVWSYZabcdefghijklmnopqrstuvwxyz0123456789-_;:,./?*~!@#$%^&*+")
{
    $s = "";
    $baseCharactersSize = $baseCharacters.Length;
    for ($i = 0; $i -lt $size; $i++)
    {
        $s += $baseCharacters[(Get-Random) % $baseCharactersSize]
    }
    return $s;

}

function global:commandsWithParameter([string]$moduleNamePattern, [string]$commandNamePattern, [string]$parameterRegexPattern)
{
    $moduleNamePattern  = $moduleNamePattern.Replace('.','');
    $commandNamePattern = $commandNamePattern.Replace('.', '');
    gcm -Module $moduleNamePattern -Name $commandNamePattern | where { ($_.Parameters.Keys | where { $_ -match $parameterRegexPattern }) -ne $null };
}

function global:sortDictionaryByValue([Hashtable]$dict, [bool]$descending = $false)
{
    if ($descending)
    {
        return $dict.GetEnumerator() | Sort-Object -Property 'Value' -Descending;
    }
    else
    {
        return $dict.GetEnumerator() | Sort-Object -Property 'Value';
    }
}

function global:toUnixTime([DateTime]$d)
{
    ([DateTimeOffset]$d).ToUnixTimeSeconds();
}

function global:selectMultipleWithListDialog($l)
{
    $l | Out-GridView -OutputMode Multiple;
}

function global:flattenObject([PSCustomObject]$o, [string]$prefix="", [PSCustomObject]$newObject = $null)
{
    if ($newObject -eq $null)
    {
        $newObject = new-object -TypeName PSCustomObject;
    }
    if ($prefix.Length -gt 0)
    {
        $prefix += "_";
    }
    $properties = get-member -InputObject $o -MemberType NoteProperty;
    foreach ($property in $properties)
    {
        $value = $o."$($property.Name)";
        $name = ($prefix + $property.Name);
        $type = if ($value -eq $null) { "null" } else { $value.GetType().Name };
        if ($value -ne $null -and $type -eq 'PSCustomObject')
        {
            $newObject = global:flattenObject $value $name $newObject;
        }
        if ($value -ne $null -and ($type -eq 'Object[]' -or $type -eq 'Hashtable'))
        {
            Add-Member -InputObject $newObject -MemberType NoteProperty -Name $name -Value ($value | convertto-json -Compress);
        }
        if ($type -ne 'PSCustomObject' -and $type -ne 'Object[]' -and $type -ne 'Hashtable')
        {
            Add-Member -InputObject $newObject -MemberType NoteProperty -Name $name -Value $value;
        }
    }
    return $newObject;
}

Function global:extractGZipFile{
    Param(
        $infile,
        $outfile = ($infile -replace '\.gz$','')
        )

    $input = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)

    $buffer = New-Object byte[](1024)
    while($true){
        $read = $gzipstream.Read($buffer, 0, 1024)
        if ($read -le 0){break}
        $output.Write($buffer, 0, $read)
        }

    $gzipStream.Close()
    $output.Close()
    $input.Close()
}

function global:removeProperties([object]$o, [string[]]$propertyNamesToBeRemoved)
{
    $n = New-Object -TypeName PSCustomObject;
    $properties = get-member -InputObject $o -MemberType NoteProperty;
    for ($i = $properties.Count - 1; $i -ge 0; $i--)
    {
        $property = $properties[$i];
        if (!($propertyNamesToBeRemoved.Contains($property.Name)))
        {
            $value = $o."$($property.Name)";
            Add-Member -InputObject $n -MemberType NoteProperty -Name $property.Name -Value $value;
        }
    }
    return $n;
}

function global:curlGetBasicAuth([string]$url, [string]$userName, [string]$password) 
{
    $cmdFileName = (([System.IO.Path]::GetTempFileName()) + ".cmd");
    "@echo off`ncurl -u $($userName):$password $url" | Out-File  -Encoding ascii $cmdFileName;
    $r = Invoke-Expression $cmdFileName 2>&1 ;
    del $cmdFileName;
    return $r;
}


function global:handleException($exceptionMessage, $count)
{
    if ($count -lt $global:MaxRetries)
    {
        Write-Host -ForegroundColor Cyan "Exception $($exceptionMessage) occurred, will wait for 2 seconds then retry $($count+1)/$($global:MaxRetries) retries.";
        Start-Sleep -Seconds 2;
    }
    else
    {
        throw $exceptionMessage;
    }
}

#
# This function treats 3 types of exceptions:
#  terminating error: will be caught by the try catch statement;
#  non-terminating error: will be listed in $Error[0]
#  error messages: will be captured by -ErrorVariable
function global:retryLogic([System.Management.Automation.ScriptBlock]$s)
{
    $v = $null;
    #write-host "`nRetryLogic $s `n$(Get-PSCallStack)" -ForegroundColor Yellow;
    for ($i = 0; $i -le $global:MaxRetries; $i++)
    {
        $savedErrorActionPreference = $ErrorActionPreference;
        try
        {
            $ErrorActionPreference = 'Stop';
            $ev = $null;
            $v = Invoke-Command -ScriptBlock $s -ErrorVariable $ev;
            $succeeded = $?;
            if ($ev -ne $null) 
            { 
                global:handleException $ev $i; 
            }
            elseif ($succeeded -eq $false)
            {
                global:handleException $Error[0] $i;
            }
            else               
            { 
                break;                  
            }
        }
        catch 
        { 
            global:handleException $_.Exception.Message $i; 
        }
        finally
        {
            $ErrorActionPreference = $savedErrorActionPreference;
        }
    }
    #write-host "RetryLogic END`n" -ForegroundColor Yellow;
    return $v;
}


function global:createCredentialFromAzureCredentialsJSONFile()
{
	$fileName = join-path $global:powerShellScriptDirectory 'azureCredentials.json';
	if (!(Test-Path $fileName))
	{
		throw "$fileName does not exist";
	}
	return (global:createCredentialFromJsonFile $fileName);
}

function global:createCredentialFromJsonFile([string]$jsonFileName)
{
	$data = gc $jsonFileName | ConvertFrom-Json;
    return (global:createCredential $data.userName $data.password);
}

function global:createCredential([string]$userName, [string]$password)
{
    $cred = New-Object System.Management.Automation.PSCredential($userName, (ConvertTo-SecureString $password -AsPlainText -Force));
	return $cred;
}

function global:openDefaultBrowser([string]$url = "")
{
    $progid = (Get-ItemProperty 'HKCU:\Software\Microsoft\windows\Shell\Associations\UrlAssociations\http\UserChoice').Progid;
    $browserPath = (Get-itemproperty "Registry::HKEY_CLASSES_ROOT\$progid\shell\open\command")."(default)";
    $browserPath = $browserPath.Replace("%1", $url);
    $startBrowserPath = Join-Path $env:temp "startbrowser.cmd";
    $browserPath | Out-File $startBrowserPath;
    start $startBrowserPath;
}

function global:jsonBeautify([string]$json)
{
    if (!($global:JsonBeautifierJsonBeautifyDefined))
    {
    $class = 
@"
namespace JsonBeautifier2
{
    using System;
    using System.Linq;
    public class JsonBeautify
    {
        public static string FormatJson(string json)
        {
            json                 = System.Text.RegularExpressions.Regex.Replace(json, "\r\n[ \t]+", "");
            json                 = System.Text.RegularExpressions.Regex.Replace(json, ":[ \t]+", ": ");
            json                 = json.Replace("\r", "").Replace("\n", "");
            int indentation      = 0;
            int quoteCount       = 0;
            var result           =
                from ch in json
                let quotes       = ch == '"' 
                    ? quoteCount++ 
                    : quoteCount
                let lineBreak    = ch == ','                && quotes % 2 == 0 
                    ? ch + Environment.NewLine + String.Concat(Enumerable.Repeat("   ", indentation)) 
                    : null
                let openChar     = (ch == '{' || ch == '[') && quotes % 2 == 0 
                    ? ch + Environment.NewLine + String.Concat(Enumerable.Repeat("   ", ++indentation)) 
                    : ch.ToString()
                let closeChar    = (ch == '}' || ch == ']') && quotes % 2 == 0 
                    ? Environment.NewLine + String.Concat(Enumerable.Repeat("   ", --indentation)) + ch 
                    : ch.ToString()
                select lineBreak == null
                            ? openChar.Length > 1
                                ? openChar
                                : closeChar
                            : lineBreak;

            return String.Concat(result).Replace(@"\u0027", "'");
        }

    }
}
"@;
        Add-Type -TypeDefinition $class;
        $global:JsonBeautifierJsonBeautifyDefined = $true;
    }
    return [JsonBeautifier2.JsonBeautify]::FormatJson($json);
}

function global:toBeautifulJson($o)
{
    $j = $o | ConvertTo-Json -Compress -Depth 100;
    return global:jsonBeautify $j;
}


function global:cloneObject($o)
{
    if ($o -eq $null)
    {
        return $null;
    }
    $t = $o.GetType();
    if ($t -eq [string] -or $t.IsValueType)
    {
        return $o;
    }
    if ($t.IsArray)
    {
        $a = @();
        foreach ($item in $o)
        {
            $a = $a + (global:cloneObject $item);
        }
        return $a;
    }
    $n = New-Object -TypeName PSCustomObject;
    $propertyNames = (Get-Member -InputObject $o -MemberType NoteProperty).Name;
    foreach ($propertyName in $propertyNames)
    {
        $n | Add-Member -MemberType NoteProperty -Name $propertyName -Value (global:cloneObject $o."$propertyName");
    }
    return $n;
}

function global:getFileEncoding([string]$path)
{
  [byte[]]$byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
  #Write-Host Bytes: $byte[0] $byte[1] $byte[2] $byte[3]
  $encoding = 'ascii';
  # EF BB BF (UTF8)
  if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
  { $encoding =  'utf8' }

  # FE FF  (UTF-16 Big-Endian)
  elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
  { $encoding =  'bigendianunicode' }

  # FF FE  (UTF-16 Little-Endian)
  elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe)
  { $encoding =  'unicode' }

  # 00 00 FE FF (UTF32 Big-Endian)
  elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
  { $encoding =  'UTF32 Big-Endian' }

  # FE FF 00 00 (UTF32 Little-Endian)
  elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff -and $byte[2] -eq 0 -and $byte[3] -eq 0)
  { $encoding =  'utf32' }

  # 2B 2F 76 (38 | 38 | 2B | 2F)
  elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76 -and ($byte[3] -eq 0x38 -or $byte[3] -eq 0x39 -or $byte[3] -eq 0x2b -or $byte[3] -eq 0x2f) )
  { $encoding =  'utf7'}

  # F7 64 4C (UTF-1)
  elseif ( $byte[0] -eq 0xf7 -and $byte[1] -eq 0x64 -and $byte[2] -eq 0x4c )
  { $encoding =  'UTF-1' }

  # DD 73 66 73 (UTF-EBCDIC)
  elseif ($byte[0] -eq 0xdd -and $byte[1] -eq 0x73 -and $byte[2] -eq 0x66 -and $byte[3] -eq 0x73)
  { $encoding =  'UTF-EBCDIC' }

  # 0E FE FF (SCSU)
  elseif ( $byte[0] -eq 0x0e -and $byte[1] -eq 0xfe -and $byte[2] -eq 0xff )
  { $encoding =  'SCSU' }

  # FB EE 28  (BOCU-1)
  elseif ( $byte[0] -eq 0xfb -and $byte[1] -eq 0xee -and $byte[2] -eq 0x28 )
  { $encoding =  'BOCU-1' }

  # 84 31 95 33 (GB-18030)
  elseif ($byte[0] -eq 0x84 -and $byte[1] -eq 0x31 -and $byte[2] -eq 0x95 -and $byte[3] -eq 0x33)
  { $encoding =  'GB-18030' }

  return $encoding;
}

function global:getNthOccurranceInString([string]$line, [string]$delimiter, [int]$colums)
{
    $searchPosition = -1;
    for ($i = 0; $i -le $columnToAlign; $i++)
    {
        $searchPosition = $line.IndexOf($delimiter, $searchPosition + 1);
    }
    return $searchPosition;
}

function global:alignBy([string[]]$lines, [string]$delimiter, [int]$columnToAlign = 0)
{
    $maxWidth = -1;
    foreach ($line in $lines)
    {
        $searchPosition = global:getNthOccurranceInString $line $delimiter $columnToAlign;
        if ($searchPosition -gt $maxWidth)
        {
            $maxWidth = $searchPosition;
        }
    }
    for ($i = 0; $i -lt $lines.Count; $i++)
    {
        $line = $lines[$i];
        $searchPosition = global:getNthOccurranceInString $line $delimiter $columnToAlign;
        if ($searchPosition -gt 0)
        {
            $line = $line.Substring(0, $searchPosition) + [string]::new(' ', $maxWidth - $searchPosition) + $line.Substring($searchPosition);
            $lines[$i] = $line;
        }
    }
    return $lines;
}

function global:isItAGuid([object]$s)
{
    if ($s.GetType() -eq [guid])
    {
        return $true;
    }
    if ($s.GetType() -eq [string])
    {
        $itIs = $true;
        try { [guid]::new($s) } catch { $itIs = $false; }
        return $ItIs;
    }
    return $false;
}

function global:basicAuthHeader([string]$userName, [string]$passwordOrAccessToken)
{
    $basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $userName,$passwordOrAccessToken)))
    return @{ Authorization = "Basic $basicAuth" }
}


function global:joinDictionaries([Hashtable]$dst, [Hashtable]$src)
{
    foreach ($key in $src.Keys)
    {
        $dst[$key] = $src[$key];
    }
    return $dst;
}


function objectModelToHierarchicalDictionaryInternal($obj, [Hashtable]$dic)
{
    $memberNames = (Get-Member -InputObject $obj -MemberType NoteProperty).Name;

    foreach ($memberName in $memberNames)
    {
        if (!($dic.ContainsKey($memberName)))
        {
            $subObj = $obj."$memberName";
            if ($subObj -ne $null -and $subObj.GetType().Name.Equals('PSCustomObject'))
            {
                $dic.Add($memberName, [Hashtable]::new());
                objectModelToHierarchicalDictionaryInternal $subObj $dic[$memberName];
            }
            else
            {
                $dic.Add($memberName, $subObj);
            }
        }
    }
    return $dic;
}

function global:objectModelToHierarchicalDictionary($obj)
{
    $dictionary = [Hashtable]::new();
    objectModelToHierarchicalDictionaryInternal $obj $dictionary;
    return $dictionary;
}

function global:sortDictionaryByKey([hashtable]$dictionary)
{
    return $dictionary.GetEnumerator() | sort -Property name;
}

function global:flatObjectModelToDictionary($obj)
{
    $dictionary = [Hashtable]::new();
    $memberNames = (Get-Member -InputObject $obj -MemberType NoteProperty).Name;

    foreach ($memberName in $memberNames)
    {
        $subObj = $obj."$memberName";
        $dictionary.Add($memberName, $subObj);
    }

    return $dictionary;

}

function global:serializeWithNewtonSoft($obj)
{
    $fh = [Newtonsoft.Json.JsonSerializerSettings]::new();
    $fh.DateFormatHandling = [Newtonsoft.Json.DateFormatHandling]::IsoDateFormat;
    $fh.Formatting = [Newtonsoft.Json.Formatting]::Indented;
    $fh.NullValueHandling = [Newtonsoft.Json.NullValueHandling]::Include;
    return [Newtonsoft.Json.JsonConvert]::SerializeObject($obj, $fh);
}


function global:findAndLoadMissingAssemblyFromExceptionText([string]$exceptionText)
{
    if ($exceptionText.Contains('Could not load file or assembly'))
    {
        $dll = (global:extractWithRegex $exceptionText '.*"Could not load file or assembly ''(.*?),') + '.dll';
        $ver = (global:extractWithRegex $exceptionText 'Version=(.*?),');
        $pbt = (global:extractWithRegex $exceptionText 'PublicKeyToken=([a-zA-Z0-9]+)');
        Write-Host "Trying to load $dll $ver $pbt" -ForegroundColor Green -NoNewline;
        $asm = global:findFirstAssembly $dll $ver $pbt;
        if ($asm -ne $null)
        {
             [System.Reflection.Assembly]::LoadFile($asm);
             Write-Host " loaded from $asm" -ForegroundColor Green;
        }
        else
        {
            Write-Host " not found!" -ForegroundColor Yellow;
        }
    }
}

function global:executeWithExceptionHandling([ScriptBlock]$script)
{
    $executed = $false;
    while (!($executed))
    {
        try
        {
            $script.Invoke();
            $executed = $true;
        }
        catch
        {
            $exceptionMessage = $_.Exception.Message;
            $handled = $false;
            if ($exceptionMessage.Contains('Could not load file or assembly'))
            {
                global:findAndLoadMissingAssemblyFromExceptionText $exceptionMessage;
                $handled = $true;
            }

            if (!($handled))
            {
                throw $exceptionMessage;
            }
        }
    }
}

function global:initializeVSS(
    [string]$path = 'C:\dsv\egift.infrastructure\GetVariableGroups\bin\Debug', 
    [string]$vsURI = '"https://sbux-dpapi.visualstudio.com',
    [string]$personalToken = 'sjd4xntbzqo6c2w4qpt5itaqzkrequd3wo4yv4zmrvkib54rlt2a')
{
    $global:vssPersonalToken = $personalToken;
    pushd .
    cd $path;
    $dlls = (Get-ChildItem -path 'C:\dsv\egift.infrastructure\GetVariableGroups\bin\Debug' -Filter '*.dll').FullName;
    foreach ($dll in $dlls) { [System.Reflection.Assembly]::LoadFile($dll); }
    $cred = [Microsoft.VisualStudio.Services.Common.VssBasicCredentials]::new('', $personalToken);
    
}

function global:getAllDirectoriesInCDrive()
{
    return [quickFindDirectory.QuickFindDirectory]::Find('c:\', '');
}

function global:extractWithRegex([string]$str, [string]$patternWithOneGroupMarker)
{
    if ($str -match $patternWithOneGroupMarker)
    {
        $ret = $matches[1];
    }
    else
    {
        $ret = $null;
    }
    return $ret;
}


function global:findAssembly([string]$assemblyDllFileName, [string]$version, [string]$publicKeyToken)
{
    $root = ($env:SystemDrive + '\');
    $dlls = global:findFile $root $assemblyDllFileName;
    $found = @();
    foreach ($dll in $dlls)
    {
        $asm = [System.Reflection.Assembly]::LoadFile($dll);
        $thisVersion = global:extractWithRegex $asm.FullName '.*Version=([0-9\.]+).*';
        $thisPublicKeyToken = global:extractWithRegex $asm.FullName '.*PublicKeyToken=([a-zA-Z0-9]+).*';
        if ($thisVersion -eq $version -and $thisPublicKeyToken -eq $publicKeyToken)
        {
            $found = $found + $dll;
        }
    }
    return $found;
}

function global:fixDotNetDllsFromFolder([string]$folder)
{
    $dlls = (Get-ChildItem -Path $folder -Filter "*.dll" -File).FullName;
    foreach ($dll in $dlls)
    {
        
    }
}

function global:findFirstAssembly([string]$assemblyDllFileName, [string]$version, [string]$publicKeyToken)
{
    $root = ($env:SystemDrive + '\');
    $dlls = global:findFile $root $assemblyDllFileName;
    $found = $null;
    foreach ($dll in $dlls)
    {
        $asm = [System.Reflection.Assembly]::LoadFile($dll);
        $thisVersion = global:extractWithRegex $asm.FullName '.*Version=([0-9\.]+).*';
        $thisPublicKeyToken = global:extractWithRegex $asm.FullName '.*PublicKeyToken=([a-zA-Z0-9]+).*';
        if ($thisVersion -eq $version -and $thisPublicKeyToken -eq $publicKeyToken)
        {
            $found = $dll;
            break;
        }
    }
    return $found;
}

function global:findFile([string]$searchFolder, [string]$fileNamePattern, [string]$optionalTextToFindWithoutWildcards = $null)
{
    $fileNamePattern = $fileNamePattern.Replace('*', '%');
    $searchFolder = $searchFolder.Replace('\', '/').Trim('/');
    
    $finalresult = @();
    $searchFolderList = @($searchFolder);
    # In case it is the root folder, need to split it in it immediate subfolders because Windows Index is not applied to the root...
    if ($searchFolder.Length -eq 2 -and $searchFolder -match '[a-zA-Z]:')
    {
        $searchFolderList = (Get-ChildItem -Path "$searchFolder\" -Directory).FullName;
    }
    $needMultipleWordPostProcessing = $false;
    foreach ($searchFolder in $searchFolderList)
    {
        $searchFolder = $searchFolder.Replace('\', '/').Trim('/');
        $searchFolder = Resolve-Path $searchFolder;
        $sql = "select System.ItemPathDisplay FROM SYSTEMINDEX WHERE System.ITEMURL like 'file:$searchFolder/%' AND System.FileName LIKE '$fileNamePattern'";
        if ($optionalTextToFindWithoutWildcards -ne $null -and $optionalTextToFindWithoutWildcards.Length -gt 0)
        {
            $seps = "";
            foreach ($c in $optionalTextToFindWithoutWildcards.ToCharArray()) { if (!([char]::IsLetterOrDigit($c)) -and !($seps.Contains($c))) { $seps += $c; } }
            $words = $optionalTextToFindWithoutWildcards.Split($seps).Where({ $_.Length -gt 0 }) | Sort-Object -Unique;
            foreach ($word in $words)
            {
                $sql += " AND Contains('*$word*')";
            }
            $needMultipleWordPostProcessing = $words.Count -gt 1;
        }
        $connector = new-object system.data.oledb.oledbdataadapter -argument $sql, "provider=search.collatordso;extended properties=’application=windows’;";
        $dataset = new-object system.data.dataset; 
        if ($connector.fill($dataset)) 
        { 
            $finalresult = $finalresult + ($dataset.tables[0]).'SYSTEM.ITEMPATHDISPLAY';
            if ($needMultipleWordPostProcessing)
            {
                $resultsWithExactMatch = @();
                foreach ($filename in $finalresult)
                {
                    if (([string]::Join("", (gc $filename))).Contains($optionalTextToFindWithoutWildcards))
                    {
                        $resultsWithExactMatch += $filename;
                    }
                }
                $finalresult = $resultsWithExactMatch;
            }
        }
        $dataset.Dispose();
        $connector.Dispose();
    }
    return $finalresult;
}


function global:readAllFilesNamedFromZip([string]$zipFilePath, [string]$fileName)
{
    $fileContents = @{};
    [Void][Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem');
    [System.IO.Compression.ZipArchive]$zip = [System.IO.Compression.ZipFile]::OpenRead($zipFilePath);
    $files = $zip.Entries.Where( { $_.Name -eq $fileName });
    foreach ($file in $files)
    {
        [System.IO.Stream]$stream = $file.Open();
        $content = "";
        while (($c=$stream.ReadByte()) -ge 0) { $content += [char]$c }
        $stream.Close();
        $fileContents.Add($file.FullName, $content);
    }
    return $fileContents;
}

function global:lastNonEmptyPiece([string]$s, [string]$separator)
{
    $split = $s.Split($separator).Where({ $_.Length -gt 0 });
    $count = $split.Count;
    return $split[$count - 1];
}

function global:getRandomWordFromMostCommonWordsInEnglish()
{
    $count = $global:mostCommonWordsInEnglish.Count;
    return $global:mostCommonWordsInEnglish[(Get-Random) % $count];
}

function global:populateVariableWithBogusValueAccordingToType($obj, [string]$name, [string]$typeName)
{
    $value = $null;

    switch -regex ($typeName)
    {
        'string' 
        { 
            $w1 = global:getRandomWordFromMostCommonWordsInEnglish;
            $w2 = global:getRandomWordFromMostCommonWordsInEnglish;
            $value = "'$w1 $w2'"; 
            Invoke-Expression "`$obj.$name = $value";
            break;
        }
        'int'    
        { 
            $v = (Get-Random) % 20;
            Invoke-Expression "`$obj.$name = $v"; 
            break;
        }
        'long'    
        { 
            $v = (Get-Random) % 20;
            Invoke-Expression "`$obj.$name = $v"; 
            break;
        }        
        'short'    
        { 
            $v = (Get-Random) % 20;
            Invoke-Expression "`$obj.$name = $v"; 
            break;
        }        
        'decimal'
        {
            $v = ((Get-Random) % 100) + (((Get-Random) % 100) / 100);
            Invoke-Expression "`$obj.$name = $v";
            break;
        }
        'float'
        {
            $v = ((Get-Random) % 1000) + (((Get-Random) % 1000) / 1000);
            Invoke-Expression "`$obj.$name = $v";
            break;
        }
        'double'
        {
            $v = ((Get-Random) % 1000) + (((Get-Random) % 1000) / 1000);
            Invoke-Expression "`$obj.$name = $v";
            break;
        }        
        'System.DateTimeOffset'
        {
            Invoke-Expression "`$obj.$name = ((Get-Date).AddMinutes(((Get-Random) % 20)))";
            break;
        }
        'System.DateTime'
        {
            Invoke-Expression "`$obj.$name = ((Get-Date).AddMinutes(((Get-Random) % 20)))";
            break;
        }
        'guid'
        {
            Invoke-Expression "`$obj.$name = (New-Guid)";
            break;
        }
        'System\.Collections\.Generic\.List.*'
        {
            Invoke-Expression "`$obj.$name = [$typeName]::new()";
            $count = ((Get-Random) % 7) + 1;
            $typeName -match 'System.Collections.Generic.List\[(.*)\]';
            $innerType = $Matches[1];
            for ($i = 0; $i -lt $count; $i++)
            {
                $v = Invoke-Expression "[$innerType]::new()";
                global:populateBogusObject $v;
                Invoke-Expression "`$obj.$($name).Add(`$v)";
            }
            break;
        }
        default
        {
            try 
            {
                $value = Invoke-Expression "[$typeName]::new()"  -ErrorAction SilentlyContinue;
            }
            catch{}
            if ($value -ne $null)
            {
                global:populateBogusObject $value;
            }
            Invoke-Expression "`$obj.$name = `$value";
        }

    }

    return $obj;
}



function global:populateBogusObject($obj)
{
    if ($obj -eq $null)
    {
        Write-Host "Null object, exiting" -ForegroundColor Yellow;
    }
    else
    {
        $objType = $obj.GetType().Name;
        $properties = Get-Member -InputObject $obj -MemberType Property;
        foreach ($property in $properties)
        {
            $name = $property.Name;
            $typeName = $property.Definition.Substring(0, $property.Definition.IndexOf(" $name")).Trim();
            Write-Host "$objType $name $typeName" -ForegroundColor Green;
            global:populateVariableWithBogusValueAccordingToType $obj $name $typeName;
        }
    }
}

function global:generateSha1Hash([string]$content, [string]$hmacKey)
{
    $class = 
@"
namespace GenerateSha1Hash
{
    using System.Linq;
    public class Sha1HashGenerator
    {
        public static string GenerateSha1Hash(string requestContent, string hmacKey)
        {
            var body = System.Text.Encoding.UTF8.GetBytes(requestContent);
            var hmacSeed = System.Text.Encoding.UTF8.GetBytes(hmacKey);
            string verificationHmac;
            using (var hmacGenerator = new System.Security.Cryptography.HMACSHA1(hmacSeed))
            {
                var hashArray = hmacGenerator.ComputeHash(body);
                verificationHmac = hashArray.Aggregate("", (s, e) => s + e.ToString("x2"), s => s);
            }

            return verificationHmac;
        }

    }
}
"@;
    Add-Type -TypeDefinition $class;
    $hash = [GenerateSha1Hash.Sha1HashGenerator]::GenerateSha1Hash($content, $hmackey);
    return $hash;
}

function getPropertyNameForSerialization($property)
{
    $serializationAttributes = @{};
    $serializationAttributes.Add('JsonPropertyAttribute', 'PropertyName');
    $serializationAttributes.Add('DataMemberAttribute'  , 'Name');
    $name = "";
    foreach ($serializationAttribute in $serializationAttributes.Keys)
    {
        if ($name -eq "")
        {
            $attribute = $property.CustomAttributes.Where({ $serializationAttribute -eq $_.AttributeType.Name });
            if ($attribute -ne $null)
            {
                $namedAttribute = $attribute[0].NamedArguments.Where({ $_.MemberName -eq $serializationAttributes[$serializationAttribute]});
                if ($namedAttribute -ne $null)
                {
                    $name = $namedAttribute[0].TypedValue.Value;
                }
            }
        }
    }
    if ($name -eq "")
    {
        $name = $property.Name;
    }
    return $name;
}

function getPropertyNameMap($type, $nameMap)
{
    foreach ($property in $type.DeclaredProperties)
    {
        $name = getPropertyNameForSerialization $property;
        if ($name -cne $property.Name -and !($nameMap.ContainsKey($property.Name)))
        {
            $nameMap.Add($property.Name, $name);
        }
        if ($property.PropertyType.Assembly.FullName -eq $type.Assembly.FullName)
        {
            $nameMap = getPropertyNameMap $property.PropertyType $nameMap;
        }
    }
    return $nameMap;
}

function global:toJson($obj)
{
    $nameMap = getPropertyNameMap $obj.GetType() @{};
    [string]$json =  $obj | ConvertTo-Json -Compress;
    foreach ($oldName in $nameMap.Keys)
    {
        $toReplace = '"' + $oldName + '":';
        $new = '"' + $nameMap[$oldName] + '":';
        $json = $json.Replace($toReplace, $new);
    }
    $newObj = $json | ConvertFrom-Json;
    $seps = ("`r", "`n");
    $j = ($newObj | ConvertTo-Json).Split($seps).Where({ $_.Length -gt 0 });
    $nj = @();
    foreach ($line in $j)
    {
        if ($nj.Count -gt 0)
        {
            $trimLine = $line.Trim();
            [string]$previousLine = "___";
            $positionLast = $nj.Count - 1;
            $lastLine = $nj[$positionLast];

            if (($trimLine.StartsWith('{') -or $trimLine.StartsWith('[')) -and $lastLine.EndsWith(','))
            {
                $nj[$positionLast] = $lastLine.Substring(0, $lastLine.LastIndexOf(','));
            }
        }
        if (!($line.EndsWith(' null,')))
        {
            $nj = $nj + $line;
        }
    }
    return $nj;
}

function global:cleanAllGitFoldersUnderCurrentFolder()
{
    $gitFolders = get-childitem -Filter '.git' -Recurse -Hidden;
    $git = global:getgit;
    foreach ($gitFolder in $gitFolders)
    {
        Write-Host $gitFolder.Parent.FullName -ForegroundColor Green;
        Start-Process -FilePath $git -WorkingDirectory $gitFolder.Parent.FullName -ArgumentList ('clean', '-fdx');
    }
}

function global:signAllPSMUnderFolder([string]$path)
{
    $cert=(Get-ChildItem cert:\CurrentUser\My -codesign)[0];

    if ($cert -eq $null)
    {
        $certificateFilePath = join-path $env:temp 'SelfSigned.cer';
        Invoke-Command 'makecert' -ArgumentList ('-n', '"CN=PowerShell Local Certificate Root"', '-a', 'sha1', '-eku', '1.3.6.1.5.5.7.3.3', '-r', '-sv', 'root.pvk', $certificateFilePath, '-ss', 'Root', '-sr', 'localMachine');
        Invoke-Command 'makecert' -ArgumentList ('-pe', '-n', '"CN=PowerShellUser"', '-ss', 'MY', '-a', 'sha1', '-eku', '1.3.6.1.5.5.7.3.3', '-iv', 'root.pvk', '-ic', $certificateFilePath);
        del $certificateFilePath;
    }

    $cert=(Get-ChildItem cert:\CurrentUser\My -codesign)[0];

    if ($cert -eq $null)
    {
        throw "Could not create the certificate, take a look at https://www.hanselman.com/blog/SigningPowerShellScripts.aspx to create a self-signed certificate manually, then run this script again.";
    }

    [string]$subject = "CN=Powershell $(Get-Date -Format 'yyyyMMddhhmmss')";
    New-SelfSignedCertificate -Type Custom -Subject $subject -CertStoreLocation 'Cert:\CurrentUser\My';

    Get-ChildItem -Recurse -File -Filter '*.psm*' -Path $Path | foreach {
        $fn = $_.FullName;
        $ac = Get-AuthenticodeSignature $fn;
        if ($ac -eq $null)
        {
            Write-Host "Signing $fn " -ForegroundColor Green;
            Set-AuthenticodeSignature $fn $cert;
        }
    }
}

function global:importAllPSMUnderFolder([string]$path)
{
    $psms = Get-ChildItem -Recurse -File -Filter '*.psm*' -Path $Path;
    foreach ($psm in $psms)
    {
        $fn = $psm.FullName;
        Write-Host "Importing module $fn " -ForegroundColor Green;
        try
        {
            Import-Module $fn;
        }
        catch
        {
            $msg = $_.Exception.Message;
            Write-Host "Oh well, $msg, but I'll continue..." -ForegroundColor Yellow;
        }
    }
}


function global:addToDictionaryOfLists([System.Collections.Hashtable]$dictionary, [string]$key, [string]$newValueToAddOnListAssociatedWithKey)
{
    if ($dictionary -eq $null)
    {
        $dictionary = @{};
    }
    if (!($dictionary.ContainsKey($key)))
    {
        $dictionary.Add($key, @());
    }
    $list = $dictionary[$key];
    $list = $list + $newValueToAddOnListAssociatedWithKey;
    $dictionary[$key] = $list;
    return $dictionary;
}

function global:gitSquashBranch()
{
    $branch = global:getCurrentBranchViaGit;
    Write-Host "Retrieving history for branch [$branch]" -ForegroundColor Green;
    $reflog = &(global:getgit) 'reflog' '--date=local';
    Write-Host "Found $($reflog.Count) commits." -ForegroundColor Green;
    $toFind = "checkout: moving from master to $branch";
    Write-Host "Trying to find first commit on branch [$branch]." -ForegroundColor Green;
    for ($i=0; $i -lt $reflog.Count -and $reflog[$i] -notmatch $toFind; $i++) {}
    Write-Host "There are $i commits we want to squash..." -ForegroundColor Green;
    &(global:getgit) 'reset' '--soft' "HEAD~$i";
    Write-Host "Committing..." -ForegroundColor Green;
    &(global:getgit) 'commit' '-m' $branch;
    Write-Host "Pushing.." -ForegroundColor Green;
    &(global:getgit) 'push' '-f';
    Write-Host "Bringing changes from master..." -ForegroundColor Green;
    &(global:getgit) 'pull' 'origin' 'master' '-X' 'theirs';

    Write-Host "Pushing again..." -ForegroundColor Green;
    &(global:getgit) 'push' '-f';
    Write-Host "Done." -ForegroundColor Green;
}

function global:gitNumberOfChangedFiles()
{
    $count = 0;
    try
    {
        $cf = &(global:getgit) 'status' '-s' '-uno';
    }
    catch
    {}
    if ($cf -ne $null -and $cf.GetType() -eq [String])
    {
        $count = 1;
    }
    if ($cf -ne $null -and $cf.GetType().BaseType -eq [System.Array])
    {
        $count = $cf.Count;
    }
    return $count;
}


function global:getCurrentBranchViaGit()
{
    $branch = "Not a git repo";
    try
    {
        $branch = &(global:GetGit) ('branch', '--contains', 'HEAD');
        $branch = $branch.Replace("* ", "");
    }
    catch
    {
    }
    return $branch;
}

function global:getCurrentBranch()
{
    $previousDirName = '';
    $dirname = $PWD.Path;
    $itIsAGitDirectory = $false;
    $branch = "Not a git repo";
    while ($dirname.Length -gt 4 -and $previousDirName -ne $dirname -and $itIsAGitDirectory -eq $false)
    {
        $g=Get-ChildItem -Path $dirname -Name '.git' -Hidden;
        $itIsAGitDirectory = $g -ne $null;
        if (!($itIsAGitDirectory))
        {
            $previousDirName = $dirname;
            $dirname = Resolve-Path (Join-Path $dirname '\..');
        }
    }
    if ($itIsAGitDirectory)
    {
        $fetchHeadFilePath = Resolve-Path (join-path $dirname '.git\FETCH_HEAD');
        if ((get-item -Path $fetchHeadFilePath).Length -lt 50) {
            git fetch --force;
        }
        $branch = (gc $fetchHeadFilePath).Split("`n")[0].Split("`t")[2].Split(" ")[1];
    }
    return $branch;
}

function global:shortDate()
{
    $dd = get-date;
    $yr = $dd.Year;
    $mo = $dd.Month.ToString('d2');
    $dy = $dd.Day.ToString('d2');
    $hr = $dd.Hour.ToString('d2');
    $mi = $dd.Minute.ToString('d2');
    $se = $dd.Second.ToString('d2');

    return "$mo/$dy $($hr):$($mi):$($se)";
}

function global:isThisAGitDirectory()
{
    $previousDirName = '';
    $dirname = $PWD;
    $itIsAGitDirectory = $false;
    while ($dirname.Length -lt 4 -and $previousDirName -ne $dirname -and $itIsAGitDirectory -eq $false)
    {
        $g=Get-ChildItem -Path $dirname -Name '.git' -Hidden;
        $itIsAGitDirectory = $g -ne $null;
        if (!($itIsAGitDirectory))
        {
            $previousDirName = $dirname;
            $dirname = Resolve-Path (Join-Path $dirname '\..');
        }
    }
    return $itIsAGitDirectory;
}

function global:installCassandraIfNeeded()
{
    global:updatePowershellIfNeeded;
    global:installChocoIfNeeded
    if (!(global:isChocoPackageInstalled 'apache-cassandra'))
    {
        choco install 'apache-cassandra' -y;
    }
}

function global:isChocoPackageInstalled([string]$packageName)
{
    $info = choco info $packageName;
    return $info -ne $null -and $info.Count -gt 4;
}

function global:updatePowershellIfNeeded()
{
    $psg=get-packageprovider | where { $_.Name -eq 'PowerShellGet' };
    $compareResult = global:compareVersions $psg.Version.ToString() "1.6.0.0";
    if ($compareResult -lt 0)
    {
        global:installChocoIfNeeded;
        choco install powershell -y;
    }
}

function global:installChocoIfNeeded()
{
    
    try
    {
        get-command -Name 'choco';
    }
    catch
    {
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));
    }
}

function global:compareVersions([string]$versionLeft, [string]$versionRight)
{
    [int]$compareResult = 0;
    $splitLeft=$versionLeft.Split('.');
    $splitRight=$versionRight.Split('.');
    [int]$count=[System.Math]::Min($splitLeft.Count, $splitRight.Count);
    for ($i=0;$i -lt $count; $i++) 
    { 
        [int]$iLeft=$splitLeft[$i]; 
        [int]$iRight=$splitRight[$i]; 
        [int]$compareResult = $iLeft.CompareTo($iRight); 
        if ($compareResult -ne 0)
        {
            break;
        }
    }
    return $compareResult;
}

function global:toBase64([string]$s)
{
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($s);
    $base64 = [System.Convert]::ToBase64String($bytes);
    return $base64;
}

function global:fromBase64([string]$s)
{
    return [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($s))
}

function global:fromBase64IfNeeded([string]$s)
{
    $r = $s;
    if ($s -match "[A-Za-z0-9]+=*" -and $Matches[0] -eq $s -and ($s.Length%4 -eq 0))
    {
        try{$r = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($s))}catch{}
    }
    return $r;
}

function global:GetBasicAuthorizationHeaderValue([string]$userName,[string]$password)
{
    $pair = "${userName}:${password}";
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair);
    $base64 = [System.Convert]::ToBase64String($bytes);
    return "Basic $base64";
}

function global:httpGetWithBasicAuth([string]$uri, [string]$userName,[string]$password, [string]$desiredFormat='application/xml')
{
    $basicAuthValue = global:GetBasicAuthorizationHeaderValue $userName $password;
    $headers = @{ Authorization = $basicAuthValue; Accept=$desiredFormat };
    $iwrr=Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers $headers;
    if ($iwrr.StatusCode -ge 200 -and $iwrr.StatusCode -lt 300)
    {
        return $iwrr.Content;
    }
    return $iwrr;
}

function global:httpGetWithBasicAuthAsXml([string]$uri, [string]$userName,[string]$password)
{
    $content = global:httpGetWithBasicAuth $uri $userName $password 'application/xml';
    if ($content -ne $null -and $content.GetTypeCode() -eq 'String')
    {
        [xml]$xml=$content;
        return $xml;
    }
    return $null;
}

function global:httpGetWithBasicAuthAsJson([string]$uri, [string]$userName,[string]$password)
{
    $content = global:httpGetWithBasicAuth $uri $userName $password 'application/json';
    if ($content -ne $null -and $content.GetTypeCode() -eq 'String')
    {
        $json=$content | ConvertFrom-Json;
        return $json;
    }
    return $null;
}


function global:getEndPointsFromAtomsPubAccordingToTitle([string]$uri, [string]$userName,[string]$password, [string]$title)
{
    $atomsPubTxt = global:httpGetWithBasicAuth $uri $userName $password;
    if ($atomsPubTxt -eq $null -or $atomsPubTxt.GetTypeCode() -ne 'String')
    {
        throw "Could not retrieve AtomsPub data from $uri";
    }
    [xml]$atomsPub = $atomsPubTxt;
    $entries=$atomsPub.feed.GetElementsByTagName('entry');
    $result=@();
    foreach ($entry in $entries)
    { 
        $links = $entry.GetElementsByTagName('link'); 
        $pal = $links | where { $_.title -eq $title };
        try
        {
            $result = $result + $pal.href;
        }
        catch{}
    }
    return $result;
}


function global:getModifiedFiles()
{
    $git = global:GetGit;
    $gr=&$git ('status', '--porcelain') | foreach { Resolve-Path ([string]$_).Substring(3).Replace('/','\').Trim('"') -ErrorAction Ignore }
    return $gr;
}

function global:SaveChangedFiles()
{
    global:RemoveDirectoryIfNeeded 'SavedFiles';

    global:CreateDirectoryIfNeded 'SavedFiles';
    [string]$destinationBasePath = Resolve-Path 'SavedFiles';
    $modified = global:getModifiedFiles;
    [string]$basePath = pwd;
    $undesired = ('packages', '.vs', 'bin', 'obj');
    foreach ($path in $modified)
    {
        $lastPiece = global:lastNonEmptyPiece $path.Path '\';
        if ($undesired.Contains($lastPiece))
        {
            continue;
        }
        $withoutBasePath = $path.Path.SubString($basePath.Length+1);
        $destinationPath = Join-Path $destinationBasePath $withoutBasePath;
        if ((Get-Item $path) -is [System.IO.DirectoryInfo])
        {
            global:CreateDirectoryIfNeded $destinationPath;
            Copy-Item -Recurse -Path $path -Destination $destinationPath -Container;
        }
        else
        {
            $destinationDirectoryPath = [System.IO.Path]::GetDirectoryName($destinationPath);
            global:CreateDirectoryIfNeded $destinationDirectoryPath;
            Copy-Item -Path $path -Destination $destinationPath;
        }
    }
    $zipFile = [System.IO.Path]::GetFileName($basePath) ;
    $zipFile = $zipFile + "_" + ((Get-Date).ToString("yyyyMMddhhmmss"));
    $zipFile = $zipFile + ".zip";
    $zipFile = join-path $env:TEMP $zipFile; 
    [System.IO.Compression.ZipFile]::CreateFromDirectory($destinationBasePath, $zipFile);
    global:RemoveDirectoryIfNeeded 'SavedFiles';
    return $zipFile;
}

function global:extractTextFromBase64GZip([string]$base64Gzip)
{
    $bytes = [System.Convert]::FromBase64String($base64Gzip);
    $msIn  = [System.IO.MemoryStream]::new($bytes);
    $gzs   = [System.IO.Compression.GZipStream]::new($msIn, [System.IO.Compression.CompressionMode]::Decompress);
    $msOut = [System.IO.MemoryStream]::new();
    $gzs.CopyTo($msOut);
    return   [System.Text.Encoding]::ASCII.GetString($msOut.ToArray());
}

function global:CreateDirectoryIfNeded($path)
{
    if (!(Test-Path $path))
    {
        md $path;
    }
}

function global:RemoveDirectoryIfNeeded($path)
{
    if (test-path $path)
    {
        Remove-Item -Path $path -Recurse -Force;
    }
}

function global:StartDockerContainerIfNeeded([string]$containerName)
{
    [string]$docker = global:GetDocker;

    &$docker ('container', 'start', $containerName) | Out-Null;
    if (!($?))
    {
        throw "Could not start docker container $containerName, please create it";
    }
}

function global:FindExecutableInPath([string]$executableName)
{
    $path=$null;
    $env:Path.Split(';') | foreach {
        if (($_ -ne $null) -and ($_.Length -gt 0) -and (Test-Path $_ -PathType Container))
        {
            [string]$fn = Join-Path $_ $executableName;
            [string]$fnExe = Join-Path $_ ($executableName + ".exe");
            [string]$fnCmd = Join-Path $_ ($executableName + ".cmd");
            [string]$fnBat = Join-Path $_ ($executableName + ".bat");
            if ($path -eq $null -and (Test-Path $fn))
            {
                $path=$fn;
            }
			if ($path -eq $null -and (Test-Path $fnExe))
            {
                $path=$fnExe;
            }   
            if ($path -eq $null -and (Test-Path $fnExe))
            {
                $path=$fnCmd;
            }            
			if ($path -eq $null -and (Test-Path $fnExe))
            {
                $path=$fnBat;
            }        
		}
    }
    return $path;
}

function global:FindExecutableInPathThrowIfNotFound([string]$executableName, [string]$messageInCaseOfNotFound)
{
    $exec=global:FindExecutableInPath $executableName;
    if ($exec -eq $null)
    {
        throw $messageInCaseOfNotFound;
    }
    return $exec;
}

function global:findFileUpAndUp([string]$filePattern)
{
    $path = $PSScriptRoot;
    while ($path -ne $null -and !(Test-Path (Join-Path $path $filePattern)))
    {
		try
		{
			$path = resolve-path(join-path $path '..');
		}
		catch
		{
			$path = $null;
		}
    }
	if ($path -ne $null)
	{
		return (Join-Path $path $filePattern);
	}
    return $null;
}


function global:IsWindows()
{
    return [System.Boolean](Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue);
}

function global:CreateDirectoriesIfNotExist($pathList)
{
    foreach ($path in $pathList)
    {
        if (!(Test-Path $path))
        {
            [System.IO.Directory]::CreateDirectory($path);
        }
    }
}

function global:GetRuntime()
{
    if (global:IsWindows)
    {
        return "win10-x64";
    }
    return "linux-x64";
}

function global:AddToPathIfNeeded([string]$folderToAdd)
{
    $found = $false;
    $folderToAdd = $folderToAdd.ToLowerInvariant();
    $env:Path.Split(';') | foreach {
        [string]$folderToTest = $_.ToLowerInvariant();
        if ($folderToTest -eq $folderToAdd)
        {
            $found = $true;
        }   
    }
    if (!($found))
    {
        $env:Path = ($env:Path + ';' + $folderToAdd);
    }
}

function global:GetClassesFromSwaggerJson([string]$swaggerFile)
{
    $json = Get-Content $swaggerFile | Out-String | ConvertFrom-Json;
    $classList =  $json.definitions | Get-Member -MemberType NoteProperty | select { $_.Name };
    [string]$classes = "";
    foreach ($class in $classList)
    {
        if ($classes.Length -gt 0)
        {
            $classes = ($classes + ',');
        }
        $classes = $classes + $class;
    }
    return $classes;
}

function global:dotnetPublish()
{
    [string]$runtime = global:GetRuntime;
    [string]$dotnet  = global:FindExecutableInPathThrowIfNotFound 'dotnet' 'Please install dotnet core from https://www.microsoft.com/net/download/windows#core';

    &$dotnet ('clean');
    &$dotnet ('publish',
                '--self-contained',
                '--runtime',       $runtime,
                '--configuration', 'Debug',
                '--verbosity',     'Minimal');
}


function global:IsUsableList($l)
{
    if ($l -ne $null)
    {
        if ($l.GetType().BaseType.ToString() -eq 'System.Array')
        {
            return $true;
        }
    }
    return $false;
}

function global:listUnion($l1, $l2)
{
    $lr=@();
    if (global:IsUsableList($l1))
    {
        $l1 | foreach { $lr += $_ };
    }
    if (global:IsUsableList($l2))
    {
        $l2 | foreach { $lr += $_ };
    }
    return $lr;
}

function global:GetGit()
{
    if ($global:git -eq $null -or $global:git.Length -eq 0)      
    { 
        $global:git      = FindExecutableInPathThrowIfNotFound 'git' 'Please install git';
    }
    return $global:git;
}

function global:GetDocker()
{
    if ($global:docker.Length -eq 0)
    {
        $global:docker = FindExecutableInPathThrowIfNotFound 'docker' 'Please install docker';
    }
    return $global:docker;
}

function global:GetCurl()
{
    if ($global:curl -eq $null -or $global:curl.Length -eq 0)
    {
        $global:curl = FindExecutableInPathThrowIfNotFound 'curl' 'Please install curl from https://curl.haxx.se/download.html';
    }
    return $global:curl;
}

function global:GetCassandraKeySpaceNamesFromDockerContainer([string]$CassandraDockerContainer)
{
    [string]$docker = global:GetDocker;
    $keySpaceNames = &$docker ('exec', '--privileged', '-it', $CassandraDockerContainer, 'cqlsh', '-e', 'describe keyspaces;');
    if (global:IsUsableList($keySpaceNames))
    {
        $keySpaceNames = [System.String]::Join(' ', $keySpaceNames);
    }
    $keySpaceNames = ($keySpaceNames -replace ' +',' ').Split(' ');
    return $keySpaceNames;
}

function global:Unzip([string]$zipfile, [string]$outpath)
{
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath);
}

function global:moveDirectoryToRecycleBin([string]$folderName)
{
    $folderName = Resolve-Path $folderName;
    $parentFolder = (resolve-path (join-path $folderName "..")).Path;
    $lastPathItem = [System.IO.Path]::GetFileName($folderName);
    if ($parentFolder -eq $folderName)
    {
        throw "Cannot move $folderName to recycle bin.";
    }
    $shell = new-object -comobject "Shell.Application";
    $folder = $shell.Namespace($parentFolder);
    $item = $folder.ParseName($lastPathItem);
    $item.InvokeVerb("delete");
}

function global:revertString([string]$s)
{
    [string]$r = "";
    foreach ($c in $s.ToCharArray()) { $r = ($c + $r); }
    return $r;
}

function global:revertAndLowerString([string]$s)
{
    $s = $s.ToLowerInvariant();
    [string]$r = "";
    foreach ($c in $s.ToCharArray()) { $r = ($c + $r); }
    return $r;
}

function global:getFileListWithoutRepeatedFiles($pathList)
{
    $fileList = @();
    foreach ($path in $pathList)
    {
        Get-ChildItem -Path $path | 
            foreach { $fileList = $fileList + (global:revertAndLowerString $_.FullName); } 
    }
    $fileList = $fileList | Sort-Object;
    $finalList = @();
    $previousInvName="!!!!";
    foreach ($file in $fileList)
    {
        [string]$fn = $file;
        $invName=$fn.Split('\')[0];work
        if ($previousInvName -ne $invName)
        {
            $finalList = ($finalList + (global:revertAndLowerString $fn));
        }
    }
    return $finalList;
}

if ($global:finder -eq $null)
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
        string _baseFolder, _pattern;
        IEnumerable<string> _foundItems;

        public void Initialize(string baseFolder, string pattern)
        {
            _baseFolder = baseFolder;
            _pattern = pattern;
            _foundItems = Directory.EnumerateFiles(_baseFolder, _pattern, SearchOption.AllDirectories);
        }

        public List<string> Find()
        {
            var l = new ConcurrentQueue<string>();
            Parallel.ForEach(_foundItems, item => l.Enqueue(item));
            return l.ToList();
        }

    }";

    Add-Type $findClass;

    $global:finder = [FindClassLK]::new();
}

if ($global:directoryFinderDefined -eq $null)
{
    [string]$directoryFinderClass = 
@"
namespace quickFindDirectory
{
    using System;
    using System.Collections.Concurrent;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;

    public class QuickFindDirectory
    {
        public static IEnumerable<string> Find(string baseFolder, string folderName)
        {
            var q = new ConcurrentQueue<string>();
            return FindInternal(baseFolder, q, folderName);
        }

        private static IEnumerable<string> FindInternal(string v, ConcurrentQueue<string> q, string folderName)
        {

            var options = new ParallelOptions { MaxDegreeOfParallelism = Environment.ProcessorCount * 4 };
            try
            {
                var dirs = Directory.EnumerateDirectories(v);
                Parallel.ForEach(dirs, options, path =>
                {
                    if (folderName == string.Empty || Path.GetFileName(path).Equals(folderName, StringComparison.InvariantCultureIgnoreCase))
                    {
                        q.Enqueue(path.ToLowerInvariant());
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
    Add-Type $directoryFinderClass;
    $global:directoryFinderDefined = $true;
}