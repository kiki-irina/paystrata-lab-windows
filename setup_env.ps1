# Rebuilds the lab environment from scratch. It does NOT run any test.
#   .\setup_env.ps1
# Afterwards run the tests yourself (see test_commands.txt) or use .\test1.ps1 / .\test2.ps1.
. "$PSScriptRoot\common.ps1"

Step "1. Docker Desktop must be running"
docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker is not running. Start Docker Desktop, wait until it says 'Engine running', then run this again." }

Step "2. Destroy old containers, network and data volume"
Run docker @("compose", "down", "-v")

Step "3. Start the database and build the load generator"
Run docker @("compose", "up", "-d", "db")
Run docker @("compose", "build", "loadgen")

Step "4. Wait until the database is healthy"
$status = ""
for ($i = 0; $i -lt 60; $i++) {
    $status = (docker inspect -f "{{.State.Health.Status}}" paystrata-db 2>$null)
    if ($status -eq "healthy") { break }
    Start-Sleep -Seconds 3
}
if ($status -ne "healthy") { throw "Database did not become healthy. Check: docker compose logs db" }
Write-Host "healthy"

Step "5. Validate the data (expected: 19000)"
docker exec -i paystrata-db mysql -uroot -ppaystrata paystrata -e "SELECT COUNT(*) AS merchants FROM merchant_daily_stats;" 2>$null

Write-Host ""
Write-Host "Environment is ready. No test was run."
Write-Host "Next: .\monitor.ps1 in a second PowerShell window, then the commands from test_commands.txt."
