. dotnet restore
if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
. dotnet build
if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
. dotnet publish -o publish
if($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not(Test-Path Merged)) {
    mkdir Merged
}

$dlls = Get-Item .\publish\*.dll
.\ILRepack.exe .\publish\StartTeamCityAgentWhenZIsAvailableService.exe $dlls /out:Merged\StartTeamCityAgentWhenZIsAvailableService.exe
exit $LASTEXITCODE
