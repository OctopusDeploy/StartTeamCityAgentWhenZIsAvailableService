param(
    [string]$buildVersion,
    [string]$gitHubApiKey
)
$ErrorActionPreference = 'Stop'

function Publish-ToGitHub($versionNumber, $commitId, $preRelease, $artifact, $gitHubApiKey)
{
    $data = @{
       tag_name = [string]::Format("v{0}", $versionNumber);
       target_commitish = $commitId;
       name = [string]::Format("v{0}", $versionNumber);
       body = '';
       prerelease = $preRelease;
    }

    $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($gitHubApiKey + ":x-oauth-basic"));

    $releaseParams = @{
       Uri = "https://api.github.com/repos/OctopusDeploy/StartTeamCityAgentWhenZIsAvailableService/releases";
       Method = 'POST';
       Headers = @{ Authorization = $auth; }
       ContentType = 'application/json';
       Body = ($data | ConvertTo-Json -Compress)
    }

    $result = Invoke-RestMethod @releaseParams 
    $uploadUri = $result | Select-Object -ExpandProperty upload_url
    $uploadUri = $uploadUri -creplace '\{\?name,label\}'
    $uploadUri = $uploadUri + ("?name=$artifact" -replace '.\', '')

    $params = @{
      Uri = $uploadUri;
      Method = 'POST';
      Headers = @{ Authorization = $auth; }
      ContentType = 'application/zip';
      InFile = $artifact
    }
    Invoke-RestMethod @params
}

Write-output "### Restoring packages"

. dotnet restore
if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-output "### Building"
. dotnet build
if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-output "### Packing"
. dotnet publish -o publish
if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }


Write-output "### ILMerging"
if (-not(Test-Path Merged)) {
    mkdir Merged
}
$dlls = Get-Item .\publish\*.dll
.\ILRepack.exe .\publish\StartTeamCityAgentWhenZIsAvailableService.exe $dlls /out:Merged\StartTeamCityAgentWhenZIsAvailableService.exe
if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-output "### Enabling TLS 1.2 support"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12, [System.Net.SecurityProtocolType]::Tls11, [System.Net.SecurityProtocolType]::Tls

Compress-Archive -Path .\Merged\StartTeamCityAgentWhenZIsAvailableService.exe -DestinationPath ".\StartTeamCityAgentWhenZIsAvailableService.$buildVersion.zip"

$commitId = git rev-parse HEAD
Publish-ToGitHub -versionNumber $buildVersion `
                 -commitId $commitId `
                 -preRelease $false `
                 -artifact ".\StartTeamCityAgentWhenZIsAvailableService.$buildVersion.zip" `
                 -gitHubApiKey $gitHubApiKey
