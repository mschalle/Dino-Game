param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [string]$Godot = "F:\GODOT\Godot_v4.7.2-stable_win64.exe",
    [int]$MaxIterations = 10,
    [int]$StopAtCheckpoint = 0,
    [switch]$RequireExportTemplates
)

$ErrorActionPreference = "Stop"
if ($MaxIterations -lt 1) { throw "MaxIterations must be at least 1" }
$validation = Join-Path $ProjectPath "tools\roadmap_validation.ps1"
$status = Join-Path $ProjectPath "tools\roadmap_status.ps1"
if (-not (Test-Path -LiteralPath $validation)) { throw "Validation script was not found: $validation" }
if (-not (Test-Path -LiteralPath $status)) { throw "Status script was not found: $status" }

function Get-Checkpoint {
	$planPath = Join-Path $ProjectPath "PROJECT_PLAN.md"
	$numbers = @(Get-Content -LiteralPath $planPath | ForEach-Object {
		if ($_ -match '^([0-9]+)\. Added ') { [int]$Matches[1] }
	})
	if ($numbers.Count -eq 0) { throw "Unable to read roadmap checkpoint" }
	return [int](($numbers | Measure-Object -Maximum).Maximum)
}

$previous = Get-Checkpoint
for ($iteration = 1; $iteration -le $MaxIterations; $iteration++) {
    Write-Host "[roadmap loop $iteration/$MaxIterations] validating checkpoint $previous"
    $validationArgs = @{ ProjectPath = $ProjectPath; Godot = $Godot }
    if ($RequireExportTemplates) { $validationArgs.RequireExportTemplates = $true }
    & $validation @validationArgs
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Roadmap validation failed at checkpoint $previous" }

    $current = Get-Checkpoint
    if ($StopAtCheckpoint -gt 0 -and $current -ge $StopAtCheckpoint) {
        Write-Host "Roadmap loop reached requested checkpoint $current."
        break
    }
    if ($current -eq $previous) {
        Write-Host "No new checkpoint was recorded; stopping safely for the next development milestone."
        break
    }
    $previous = $current
}
