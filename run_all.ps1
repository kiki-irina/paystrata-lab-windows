# Both tests, each on a freshly rebuilt environment, then destroy everything.
#   .\run_all.ps1
# Run .\monitor.ps1 in a second PowerShell window first.
. "$PSScriptRoot\common.ps1"

& "$PSScriptRoot\test1.ps1"
& "$PSScriptRoot\test2.ps1"

Step "Destroy containers and the data volume"
Run docker @("compose", "down", "-v")
Write-Host ""
Write-Host "All done. Charts: results\test1.png and results\test2.png"
