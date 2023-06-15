param([string]$searchFolder, [string]$fileNamePattern, [string]$optionalTextToFindWithoutWildcards = $null)


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
        $sql = "select System.ItemPathDisplay FROM SYSTEMINDEX WHERE System.ITEMURL like 'file:$searchFolder/%' AND System.FileName LIKE '$fileNamePattern'";
        if ($optionalTextToFindWithoutWildcards -ne $null -and $optionalTextToFindWithoutWildcards.Length -gt 0)
        {
            $sql += " AND Contains('*$optionalTextToFindWithoutWildcards*')";
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
                    if (([string]::Join("", (Get-Content $filename))).Contains($optionalTextToFindWithoutWildcards))
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

