
$branch=(git branch | where { $_.StartsWith('* ') } | select { $_.Substring(2) })[0].' $_.Substring(2) ';
git diff "master..$branch" | out-file patch.txt;
n patch.txt;
$x=Read-Host "Edit the patch file: remove diffs you do not want, save with Encode UTF-8, must have a \r\n at the last line, then hit enter to continue of Control-C to stop: ";
if ($x -eq $null)
{
    throw "Execution aborted by user.";
}

$rl = git reflog --date=local;
$toFind = "checkout: moving from master to $branch";
for ($i=0; $i -lt $rl.Count -and $rl[$i] -notmatch $toFind; $i++) {}
$toFind = ": commit: ";
for ( ; $i -gt 0 -and $rl[$i] -notmatch $toFind; $i--) {}
$rl[$i] -match ".*: commit: (.*)"
$firstCommitMessage = $matches[1];

git checkout master;
git fetch;
git pull;
git branch -D $branch;
git push origin --delete $branch;
git gc ;
git checkout -b $branch;
git apply patch.txt;

$files = git status --porcelain;
$selectedFiles =  $files | Out-GridView -OutputMode Multiple;

$x=Read-Host "Select files to be committed, then hit enter to continue of Control-C to stop: ";
if ($x -eq $null)
{
    throw "Execution aborted by user.";
}

foreach ($selectedFile in $selectedFiles)
{
    git add $selectedFile.Substring(3);
}

$x=Read-Host "Enter commit message: [$firstCommitMessage]";
if ($x.Length -eq 0) { $x = $firstCommitMessage; }
git commit '-m' ('"' + $x + '"');
git push --set-upstream origin $branch

del patch.txt;
