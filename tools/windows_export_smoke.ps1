param(
    [string]$Godot = "F:\GODOT\Godot_v4.7.2-stable_win64.exe",
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory = (Join-Path ([System.IO.Path]::GetTempPath()) "roar-rise-export")
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot executable was not found: $Godot" }
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "export_presets.cfg"))) { throw "Windows export preset is missing" }
$templateRoot = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$debugTemplate = Join-Path $templateRoot "windows_debug_x86_64.exe"
$releaseTemplate = Join-Path $templateRoot "windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $debugTemplate) -or -not (Test-Path -LiteralPath $releaseTemplate)) {
    throw "Windows export requires matching Godot export templates (4.7.2). Install them in Editor Settings and retry."
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$outputPath = Join-Path $OutputDirectory "RoarAndRise.exe"

Push-Location $ProjectPath
try {
    $exportOutput = (& $Godot --headless --path "." --export-release "Windows Desktop" $outputPath 2>&1 | Out-String)
    Write-Host $exportOutput
    if ($LASTEXITCODE -ne 0 -or $exportOutput -match "No export template found") {
        throw "Windows export requires matching Godot export templates (4.7.2). Install them in Editor Settings and retry."
    }
    if ($exportOutput -match "Case mismatch opening requested file") {
        throw "Windows export found case-mismatched resource paths; normalize asset references before packaging."
    }
    if (-not (Test-Path -LiteralPath $outputPath)) { throw "Windows export completed without producing $outputPath" }
    Write-Host "Windows export smoke test: PASS"
}
finally {
    Pop-Location
}
