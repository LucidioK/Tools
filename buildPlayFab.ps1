
    $ErrorActionPreference = "Stop"
    if ($env:MS_BUILD -eq $null){
        throw "MS_BUILD environment variable must be set"
    }
    # Restore nuget packages
    Write-Host "Restoring nuget packages..."
    Server\.nuget\NuGet.exe restore Server\Server.sln
    dotnet restore Server\Server.sln

    Write-Host "Building Server.sln"
    & $env:MS_BUILD Server\Server.sln `
                    /target:Build `
                    /property:VisualStudioVersion=15.0 `
                    /property:Configuration=Debug `
                    /property:Platform="Mixed Platforms" `
                    /property:AllowedReferenceRelatedFileExtensions=.pdb `
                    /property:WarningsAsErrors=CS4014 `
                    /maxcpucount:32 `
                    /verbosity:minimal `
                    /nodeReuse:false
