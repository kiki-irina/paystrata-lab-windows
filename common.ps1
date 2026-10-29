# Shared helpers, dot-sourced by the other scripts. Not meant to be run on its own.
Set-Location $PSScriptRoot

function Step($text) { Write-Host ""; Write-Host "=== $text ===" -ForegroundColor Cyan }

function Run($exe, [string[]]$arguments) {
    # Runs a native command and stops the script if it fails.
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "FAILED ($LASTEXITCODE): $exe $($arguments -join ' ')" }
}

function Plot($script) {
    $py = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
    if (Test-Path $py) {
        & $py $script
    } else {
        Write-Host "No .venv found. Create it once:"
        Write-Host "  py -m venv .venv"
        Write-Host "  .\.venv\Scripts\python.exe -m pip install matplotlib"
    }
}
