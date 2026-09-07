param(
    [string]$Godot = "F:\GODOT\Godot_v4.7.2-stable_win64.exe",
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [switch]$RequireExportTemplates
)

$ErrorActionPreference = "Stop"

function Invoke-CapturedProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try {
        $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $script:LastCapturedExitCode = [int]$process.ExitCode
        $stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw } else { "" }
        $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { "" }
        return ($stdout + $stderr)
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stderrPath -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable was not found: $Godot"
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
    throw "Godot project was not found: $ProjectPath"
}

Push-Location $ProjectPath
try {
    Write-Host "[1/7] Running automated gameplay tests..."
    $test_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/run_tests.gd")
    Write-Host $test_output
    $exit_code = $script:LastCapturedExitCode
    if ($exit_code -ne 0) { throw "Godot gameplay tests failed ($exit_code)" }
    if ($test_output -match "SCRIPT ERROR|Parse Error|couldn't resolve track") {
        throw "Gameplay tests reported a runtime or animation error despite their exit status"
    }
    if ($test_output -notmatch "Roar & Rise tests: PASS" -or $test_output -match "Roar & Rise tests: [1-9][0-9]* failure") {
        throw "Godot gameplay tests did not report a clean PASS marker"
    }

    Write-Host "[2/7] Checking headless project startup..."
    $startup_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--quit-after", "5")
    Write-Host $startup_output
    $exit_code = $script:LastCapturedExitCode
    if ($exit_code -ne 0) { throw "Godot startup check failed ($exit_code)" }
    if ($startup_output -match "SCRIPT ERROR|Parse Error") { throw "Godot startup reported a script or parse error" }

    Write-Host "[3/7] Exercising Adventure movement and combat over real frames..."
    $models_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/new_models_smoke.gd")
    Write-Host $models_output
    if ($script:LastCapturedExitCode -ne 0 -or $models_output -notmatch "New dinosaur models: PASS" -or $models_output -match "SCRIPT ERROR|Parse Error|couldn't resolve track") {
        throw "Supplied dinosaur model integration test failed"
    }
    $smoke_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--fixed-fps", "60", "--script", "res://tests/active_run_smoke.gd")
    Write-Host $smoke_output
    if ($script:LastCapturedExitCode -ne 0 -or $smoke_output -notmatch "Active run smoke: PASS" -or $smoke_output -match "SCRIPT ERROR|Parse Error|couldn't resolve track") {
        throw "Active Adventure movement/combat smoke test failed"
    }

    Write-Host "[4/7] Checking terrain seams, physics routes and baked navigation..."
    $reserve_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--fixed-fps", "60", "--path", ".", "--script", "res://tests/reserve_traversal_smoke.gd")
    Write-Host $reserve_output
    if ($script:LastCapturedExitCode -ne 0 -or $reserve_output -notmatch "Reserve traversal smoke: PASS" -or $reserve_output -match "SCRIPT ERROR|Parse Error") {
        throw "Full-reserve physical traversal test failed"
    }
    $impostor_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/tree_impostor_smoke.gd")
    Write-Host $impostor_output
    if ($script:LastCapturedExitCode -ne 0 -or $impostor_output -notmatch "Tree impostor smoke: PASS" -or $impostor_output -match "SCRIPT ERROR|Parse Error") {
        throw "Distant tree impostor test failed"
    }
    $token_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/token_pool_smoke.gd")
    Write-Host $token_output
    if ($script:LastCapturedExitCode -ne 0 -or $token_output -notmatch "Token pool smoke: PASS" -or $token_output -match "SCRIPT ERROR|Parse Error") {
        throw "Reward token pool lifecycle test failed"
    }
    $foliage_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/foliage_bake_smoke.gd")
    Write-Host $foliage_output
    if ($script:LastCapturedExitCode -ne 0 -or $foliage_output -notmatch "Foliage bake smoke: PASS" -or $foliage_output -match "SCRIPT ERROR|Parse Error") {
        throw "Prepared foliage parity test failed"
    }
    $habitat_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/habitat_bake_smoke.gd")
    Write-Host $habitat_output
    if ($script:LastCapturedExitCode -ne 0 -or $habitat_output -notmatch "Habitat bake smoke: PASS" -or $habitat_output -match "SCRIPT ERROR|Parse Error") {
        throw "Habitat layout parity test failed"
    }
    $pool_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/actor_pool_smoke.gd")
    Write-Host $pool_output
    if ($script:LastCapturedExitCode -ne 0 -or $pool_output -notmatch "Actor pool smoke: PASS" -or $pool_output -match "SCRIPT ERROR|Parse Error") {
        throw "Actor pool state and lifecycle test failed"
    }
    $water_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/reserve_water_smoke.gd")
    Write-Host $water_output
    if ($script:LastCapturedExitCode -ne 0 -or $water_output -notmatch "Reserve water smoke: PASS" -or $water_output -match "SCRIPT ERROR|Parse Error") {
        throw "Reserve water geometry test failed"
    }
    $clearance_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/tree_clearance_smoke.gd")
    Write-Host $clearance_output
    if ($script:LastCapturedExitCode -ne 0 -or $clearance_output -notmatch "Tree clearance smoke: PASS" -or $clearance_output -match "SCRIPT ERROR|Parse Error") {
        throw "Imported tree camera clearance test failed"
    }
    $ground_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/reserve_ground_smoke.gd")
    Write-Host $ground_output
    if ($script:LastCapturedExitCode -ne 0 -or $ground_output -notmatch "Reserve ground smoke: PASS" -or $ground_output -match "SCRIPT ERROR|Parse Error") {
        throw "Reserve ground palette test failed"
    }
    $visual_tiers_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/visual_tiers_smoke.gd")
    Write-Host $visual_tiers_output
    if ($script:LastCapturedExitCode -ne 0 -or $visual_tiers_output -notmatch "Visual tiers smoke: PASS" -or $visual_tiers_output -match "SCRIPT ERROR|Parse Error") {
        throw "Visual streaming tiers test failed"
    }
    $bake_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/terrain_bake_smoke.gd")
    Write-Host $bake_output
    if ($script:LastCapturedExitCode -ne 0 -or $bake_output -notmatch "Terrain bake smoke: PASS" -or $bake_output -match "SCRIPT ERROR|Parse Error|Missing or stale|differs from procedural") {
        throw "Baked terrain parity test failed"
    }
    $staging_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/chunk_staging_smoke.gd")
    Write-Host $staging_output
    if ($script:LastCapturedExitCode -ne 0 -or $staging_output -notmatch "Chunk staging smoke: PASS" -or $staging_output -match "SCRIPT ERROR|Parse Error") {
        throw "Chunk construction staging test failed"
    }
    $simulation_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/stream_simulation_smoke.gd")
    Write-Host $simulation_output
    if ($script:LastCapturedExitCode -ne 0 -or $simulation_output -notmatch "Stream simulation smoke: PASS" -or $simulation_output -match "SCRIPT ERROR|Parse Error") {
        throw "Stream simulation budget test failed"
    }
    $cache_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/chunk_cache_smoke.gd")
    Write-Host $cache_output
    if ($script:LastCapturedExitCode -ne 0 -or $cache_output -notmatch "Chunk cache smoke: PASS" -or $cache_output -match "SCRIPT ERROR|Parse Error") {
        throw "Chunk cache lifecycle test failed"
    }
    $lod_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/vegetation_lod_smoke.gd")
    Write-Host $lod_output
    if ($script:LastCapturedExitCode -ne 0 -or $lod_output -notmatch "Vegetation LOD smoke: PASS" -or $lod_output -match "SCRIPT ERROR|Parse Error|at: mesh_|at: _init") {
        throw "Vegetation LOD preservation test failed"
    }
    $terrain_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--fixed-fps", "60", "--script", "res://tests/terrain_smoke.gd")
    Write-Host $terrain_output
    if ($script:LastCapturedExitCode -ne 0 -or $terrain_output -notmatch "Terrain smoke: PASS" -or $terrain_output -match "SCRIPT ERROR|Parse Error|Navigation region synchronization") {
        throw "Terrain physics/navigation smoke test failed"
    }

    Write-Host "[5/7] Checking global atmosphere, biome transitions and accessibility..."
    $atmosphere_output = Invoke-CapturedProcess -FilePath $Godot -Arguments @("--headless", "--path", ".", "--script", "res://tests/atmosphere_smoke.gd")
    Write-Host $atmosphere_output
    if ($script:LastCapturedExitCode -ne 0 -or $atmosphere_output -notmatch "Atmosphere smoke: PASS" -or $atmosphere_output -match "SCRIPT ERROR|Parse Error|couldn't resolve track") {
        throw "Global atmosphere smoke test failed"
    }

    Write-Host "[6/7] Checking Git whitespace..."
    git diff --check
    $exit_code = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    if ($exit_code -ne 0) { throw "git diff --check failed ($exit_code)" }

    Write-Host "[7/7] Checking roadmap checkpoint integrity..."
    $statusArgs = @{ ProjectPath = $ProjectPath }
    if ($RequireExportTemplates) { $statusArgs.RequireExportTemplates = $true }
    & (Join-Path $ProjectPath "tools\roadmap_status.ps1") @statusArgs
    $exit_code = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    if ($exit_code -ne 0) { throw "Roadmap checkpoint integrity check failed ($exit_code)" }

    Write-Host "Roadmap validation: PASS"
}
finally {
    Pop-Location
}
