param(
    [string]$Godot = "F:\GODOT\Godot_v4.7.2-stable_win64.exe",
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable was not found: $Godot"
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
    throw "Godot project was not found: $ProjectPath"
}

Push-Location $ProjectPath
try {
    Write-Host "[1/3] Running automated gameplay tests..."
    & $Godot --headless --path "." --script "res://tests/run_tests.gd"
    $exit_code = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    if ($exit_code -ne 0) { throw "Godot gameplay tests failed ($exit_code)" }

    Write-Host "[2/3] Checking headless project startup..."
    & $Godot --headless --path "." --quit-after 5
    $exit_code = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    if ($exit_code -ne 0) { throw "Godot startup check failed ($exit_code)" }

    Write-Host "[3/3] Checking Git whitespace..."
    git diff --check
    $exit_code = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    if ($exit_code -ne 0) { throw "git diff --check failed ($exit_code)" }

    Write-Host "Roadmap validation: PASS"
}
finally {
    Pop-Location
}
