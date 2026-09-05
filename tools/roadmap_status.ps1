param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [switch]$RunValidation,
    [switch]$RequireExportTemplates
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
$sortedCheckpoints = @($checkpointNumbers | Sort-Object)
if (($sortedCheckpoints -join ",") -ne ($checkpointNumbers -join ",")) {
    throw "Roadmap checkpoint numbers must be in ascending order"
}
$templateRoot = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$debugTemplate = Join-Path $templateRoot "windows_debug_x86_64.exe"
$releaseTemplate = Join-Path $templateRoot "windows_release_x86_64.exe"
if ((Test-Path -LiteralPath $debugTemplate) -and (Test-Path -LiteralPath $releaseTemplate)) {
    Write-Host "Windows export templates: INSTALLED"
} else {
    Write-Host "Windows export templates: MISSING (packaging gate pending)"
    if ($RequireExportTemplates) {
        throw "Windows export templates are required but missing"
    }
}

if ($RunValidation) {
    $validator = Join-Path $ProjectPath "tools\roadmap_validation.ps1"
    & $validator -ProjectPath $ProjectPath
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Roadmap validation failed ($LASTEXITCODE)"
    }
}
