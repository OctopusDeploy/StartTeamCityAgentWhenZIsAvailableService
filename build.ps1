. dotnet restore
. dotnet build
. dotnet publish -o publish
if($LASTEXITCODE -ne 0) {
    throw
}

if(-not(Test-Path Merged)) {
    mkdir Merged
}
$dlls = Get-Item .\publish\*.dll
.\ILRepack.exe .\publish\StartTeamCityAgentWhenZIsAvailableService.exe $dlls /out:Merged\StartTeamCityAgentWhenZIsAvailableService.exe
if($LASTEXITCODE -ne 0) {
    throw
}
