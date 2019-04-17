
if (!(Test-Path 'Deployment\pf_cloud\dynamodb\dynamodb.template'))
{
    throw 'You must be in the root of a pf-main repository.';
}
$templateInTempPath = (join-path $env:TEMP 'dynamodb.template');
if (!(Test-Path $templateInTempPath))
{
    throw "$templateInTempPath not found.";
}


copy $templateInTempPath 'Deployment\pf_cloud\dynamodb\dynamodb.template';
git add 'Deployment/pf_cloud/dynamodb/dynamodb.template';
git commit -m "Restating tables after fixing dynamodb deployment.";
git push;
Write-Host "`n`n`nNow go to https://pf-jenkins.LK.com/view/all/job/update-cloud-data/ and Build with Parameters." -ForegroundColor Green; 
Write-Host "If the job finishes fine, we're done here." -ForegroundColor Green; 
del $templateInTempPath;