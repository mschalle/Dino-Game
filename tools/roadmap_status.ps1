param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [switch]$RunValidation
)

$ErrorActionPreference = "Stop"
$planPath = Join-Path $ProjectPath "PROJECT_PLAN.md"
if (-not (Test-Path -LiteralPath $planPath)) {
    throw "Project plan was not found: $planPath"
}

$checkpointNumbers = @(
    Get-Content -LiteralPath $planPath |
        ForEach-Object {
            if ($_ -match '^([0-9]+)\. Added ') { [int]$Matches[1] }
        }
)
if ($checkpointNumbers.Count -eq 0) {
    throw "No numbered roadmap checkpoints were found in PROJECT_PLAN.md"
}

$latest = ($checkpointNumbers | Measure-Object -Maximum).Maximum
$uniqueCount = @($checkpointNumbers | Sort-Object -Unique).Count
Write-Host "Roadmap checkpoint: $latest"
Write-Host "Recorded checkpoint entries: $($checkpointNumbers.Count) (unique $uniqueCount)"
if ($uniqueCount -ne $checkpointNumbers.Count) {
    throw "Roadmap checkpoint numbers must be unique"
}

if ($RunValidation) {
    $validator = Join-Path $ProjectPath "tools\roadmap_validation.ps1"
    & $validator -ProjectPath $ProjectPath
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Roadmap validation failed ($LASTEXITCODE)"
    }
}
