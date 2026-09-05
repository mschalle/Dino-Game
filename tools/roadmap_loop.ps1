param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [string]$Godot = "F:\GODOT\Godot_v4.7.2-stable_win64.exe",
    [int]$MaxIterations = 10,
    [int]$StopAtCheckpoint = 0,
    [string]$ResultPath = "",
    [switch]$RunPackagingSmoke,
    [switch]$RequireExportTemplates
)

$ErrorActionPreference = "Stop"
if ($MaxIterations -lt 1) { throw "MaxIterations must be at least 1" }
if ($MaxIterations -gt 100) { throw "MaxIterations cannot exceed 100" }
$validation = Join-Path $ProjectPath "tools\roadmap_validation.ps1"
$status = Join-Path $ProjectPath "tools\roadmap_status.ps1"
$planPath = Join-Path $ProjectPath "PROJECT_PLAN.md"
if (-not (Test-Path -LiteralPath $validation)) { throw "Validation script was not found: $validation" }
if (-not (Test-Path -LiteralPath $status)) { throw "Status script was not found: $status" }
if (-not (Test-Path -LiteralPath $planPath)) { throw "Project plan was not found: $planPath" }

& $status -ProjectPath $ProjectPath | Out-Null
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Roadmap checkpoint integrity preflight failed" }

function Get-Checkpoint {
	$numbers = @(Get-Content -LiteralPath $planPath | ForEach-Object {
		if ($_ -match '^([0-9]+)\. Added ') { [int]$Matches[1] }
	})
	if ($numbers.Count -eq 0) { throw "Unable to read roadmap checkpoint" }
	return [int](($numbers | Measure-Object -Maximum).Maximum)
}

$previous = Get-Checkpoint
$iterationsRun = 0
$stopReason = "iteration_limit"
for ($iteration = 1; $iteration -le $MaxIterations; $iteration++) {
    $iterationsRun = $iteration
    Write-Host "[roadmap loop $iteration/$MaxIterations] validating checkpoint $previous"
    $validationArgs = @{ ProjectPath = $ProjectPath; Godot = $Godot }
    if ($RequireExportTemplates) { $validationArgs.RequireExportTemplates = $true }
    & $validation @validationArgs
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Roadmap validation failed at checkpoint $previous" }
    if ($RunPackagingSmoke) {
        $packaging = Join-Path $ProjectPath "tools\windows_export_smoke.ps1"
        & $packaging -ProjectPath $ProjectPath -Godot $Godot
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Windows packaging smoke test failed at checkpoint $previous" }
    }

    $current = Get-Checkpoint
    if ($StopAtCheckpoint -gt 0 -and $current -ge $StopAtCheckpoint) {
        Write-Host "Roadmap loop reached requested checkpoint $current."
        $stopReason = "requested_checkpoint"
        break
    }
    if ($current -eq $previous) {
        Write-Host "No new checkpoint was recorded; stopping safely for the next development milestone."
        $stopReason = "no_new_checkpoint"
        break
    }
    if ($current -ne ($previous + 1)) {
        throw "Roadmap checkpoint advanced from $previous to $current; milestones must advance sequentially"
    }
    $previous = $current
}

if (-not [string]::IsNullOrWhiteSpace($ResultPath)) {
    $result = [ordered]@{
        checkpoint = Get-Checkpoint
        iterations = $iterationsRun
        stop_reason = $stopReason
        validation = "pass"
    }
    $result | ConvertTo-Json | Set-Content -LiteralPath $ResultPath -Encoding utf8
    Write-Host "Roadmap loop result written to $ResultPath"
}
