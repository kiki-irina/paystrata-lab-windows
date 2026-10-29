# TEST 2: IODKU only (no redesign), REPEATABLE READ versus READ COMMITTED, ramp 1 -> 50 sessions.
# Rebuilds the environment, runs the ramp twice and draws results\test2.png.
#   .\test2.ps1             leaves the database running at the end
#   .\test2.ps1 -Destroy    destroys the containers at the end
# Tip: run .\monitor.ps1 in a second PowerShell window before you start.
param([switch]$Destroy)
. "$PSScriptRoot\common.ps1"

Step "TEST 2, environment: rebuild from scratch"
& "$PSScriptRoot\setup_env.ps1"

Step "TEST 2a, IODKU with REPEATABLE READ (the default), 1 -> 50 sessions"
Run docker @("compose", "run", "--rm", "-T", "loadgen", "ramp", "--variants", "iodku", "--out", "test2_rr")

Step "TEST 2b, IODKU with READ COMMITTED, 1 -> 50 sessions"
Run docker @("compose", "run", "--rm", "-T", "loadgen", "ramp", "--variants", "iodku", "--isolation", "READ COMMITTED", "--out", "test2_rc")

Step "TEST 2, chart"
Plot "plot_isolation.py"

if ($Destroy) { Step "Destroy containers and volume"; Run docker @("compose", "down", "-v") }
Write-Host ""
Write-Host "Test 2 done. Numbers: results\test2_rr.csv and results\test2_rc.csv   Chart: results\test2.png"
