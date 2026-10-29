# TEST 1: IODKU versus UPDATE first (the redesign), ramp 1 -> 50 sessions, REPEATABLE READ.
# Rebuilds the environment, runs the ramp for IODKU and then for the redesign, and draws
# results\test1.png (payments per second, p95, deadlocks).
#   .\test1.ps1             leaves the database running at the end
#   .\test1.ps1 -Destroy    destroys the containers at the end
# Tip: run .\monitor.ps1 in a second PowerShell window before you start.
param([switch]$Destroy)
. "$PSScriptRoot\common.ps1"

Step "TEST 1, environment: rebuild from scratch"
& "$PSScriptRoot\setup_env.ps1"

Step "TEST 1, IODKU then redesign, 1 -> 50 sessions (rows appear as each level finishes)"
Run docker @("compose", "run", "--rm", "-T", "loadgen", "ramp", "--out", "test1")

Step "TEST 1, chart"
Plot "plot.py"

if ($Destroy) { Step "Destroy containers and volume"; Run docker @("compose", "down", "-v") }
Write-Host ""
Write-Host "Test 1 done. Numbers: results\test1.csv   Chart: results\test1.png"
