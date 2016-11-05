
Start-Transcript -path "c:\buildagent\logs\StartTeamCityAgentWhenZIsAvailable.txt" -IncludeInvocationHeader -append

write-output "Starting - $(get-date)"

$timeout = new-timespan -Minutes 2
$sw = [diagnostics.stopwatch]::StartNew()
while (($sw.elapsed -lt $timeout) -and (-not(Test-Path "z:"))) {
    Write-Output "z: drive does not exist - trying again in 1 second"
    start-sleep -seconds 1
}

if (Test-Path("c:")) {
    Write-Output "Z drive exists"

    $service = Get-Service "TCBuildAgent"
    $service.Refresh()

    if ($service.Status -eq "Running") {
        Write-Output "TCBuildAgent is running, stopping"
        Stop-Service $service
    }

    while($service.Status -ne "Stopped") {
        Write-Output "Waiting, service is $($service.Status)"
        Start-Sleep 1
        $service.Refresh()
    }
    Write-Output "Starting TCBuildAgent Service"
    start-service $service
}
else {
    # modify config to point to c?
}

Write-Output "Done"
