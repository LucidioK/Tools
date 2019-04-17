param(
    [string[]]$Authors         = @('nima-ap', 'audleman', 'iouri-s', 'LucidioKuhn', 'MGudgin'),
    [int]     $OlderThanInDays = 0)

if ($env:GitHubToken -eq $null)
{
    throw "Please create the environment variable GITHUBTOKEN with a token obtained from https://github.com/settings/tokens";
}



class JobParam
{
    [object]$repo
    [String[]]$authors
    [Hashtable]$header
}

$start       = get-date;
$header      = @{ Authorization = "token $($env:GitHubToken)" };
$jobParam    = [JobParam]::new();
$jobParam.authors = $Authors;
$jobParam.header  = $header;
$repos       = Invoke-RestMethod -Method Get -Uri "https://api.github.com/orgs/LK/repos" -Headers $header;
$repoCounter = 0;
$pullRequests = @();

$block = {
    param($p);

    class PullRequestSummary
    {
        [string]$ApiUrl
        [string]$HtmlUrl
        [string]$Title
        [string]$Author
        [Nullable[DateTime]]$CreatedAt
        [Nullable[DateTime]]$UpdatedAt
        [Nullable[DateTime]]$ClosedAt
        [Nullable[DateTime]]$MergedAt
        [string[]]$Reviewers

        static [Nullable[DateTime]] ParseDate([string]$s)
        {
            if ($s -ne $null -and $s -match '[0-9]+-[0-9]+-[0-9]+T[0-9]+:[0-9]+:[0-9]+')
            {
                return [DateTime]::Parse($s);
            }
            return $null;
        }

        static [PullRequestSummary] FromPullRequest($pr)
        {
            $ps           = [PullRequestSummary]::new();
            $ps.ApiUrl    = $pr.url;
            $ps.HtmlUrl   = $pr.html_url;
            $ps.Title     = $pr.title;
            $ps.Author    = $pr.user.login;
            $ps.CreatedAt = [PullRequestSummary]::ParseDate($pr.created_at);
            $ps.UpdatedAt = [PullRequestSummary]::ParseDate($pr.updated_at);
            $ps.ClosedAt  = [PullRequestSummary]::ParseDate($pr.closed_at );
            $ps.MergedAt  = [PullRequestSummary]::ParseDate($pr.merged_at );

            $ps.Reviewers = ($pr.requested_reviewers).login;
            return $ps;
        }
    
    }

    $repo   = $p.repo;
    $header = $p.header;
    $authors= $p.authors;
    $pullRequests = @();
    $pleaseContinue = $true;
    $page = 0;

    $pullsUri  = $repo.pulls_url.Replace('{/number}','');

    while ($pleaseContinue)
    {
        $uri = "$($pullsUri)?page=$page&sort=created&direction=asc";
        $pullsPage  = Invoke-RestMethod -Method Get -Headers $header -ErrorAction SilentlyContinue -Uri $uri;
        if ($pullsPage -eq $null -or $pullsPage.Length -eq 0)
        {
            $pleaseContinue = $false;
        }
        else
        {
            $ourPulls     = $pullsPage | 
                            where { $authors.Contains($_.user.login) -and ((get-date) - [DateTime]::Parse($_.created_at)).Days -gt $OlderThanInDays } |
                            foreach { [PullRequestSummary]::FromPullRequest($_) };

            $pullRequests += $ourPulls;
            $page++;
        }
    }

    return $pullRequests;
};

$jobParams = @();
foreach ($repo in $repos)
{
    $jobParam         = [JobParam]::new();
    $jobParam.authors = $Authors;
    $jobParam.header  = $header;
    $jobParam.repo    = $repo;
    $jobParams       += $jobParam;
}

$pullRequests = foreachParallel $jobParams $block;

$elapsed = ((get-date)-$start).Seconds;
write-host "$elapsed seconds" -ForegroundColor Green;
return $pullRequests;
