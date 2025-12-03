# Test runner script for maze-zombie project
# Uses Godot 4.5.1 to run all tests

$godotPath = "C:\Godot\Godot_v4.5.1-stable_win64.exe"

if (-not (Test-Path $godotPath)) {
    Write-Host "ERROR: Godot not found at $godotPath" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Running Full Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Godot Path: $godotPath" -ForegroundColor Yellow
Write-Host ""

$testResults = @{}
$allPassed = $true

# Test 1: Scene Validation
Write-Host "[1/5] Running Scene Validation Test..." -ForegroundColor Yellow
$output = & $godotPath --headless --path . --script scripts/test_scene_validation.gd 2>&1 | Out-String
$output | Out-File -FilePath "test_scene_validation_output.txt" -Encoding UTF8
if ($output -match "PASSED" -and $output -notmatch "FAILED|ERROR") {
    Write-Host "  ✓ Scene Validation: PASSED" -ForegroundColor Green
    $testResults["Scene Validation"] = "PASSED"
} else {
    Write-Host "  ✗ Scene Validation: FAILED" -ForegroundColor Red
    $testResults["Scene Validation"] = "FAILED"
    $allPassed = $false
}

# Test 2: Maze Generation
Write-Host "[2/5] Running Maze Generation Test..." -ForegroundColor Yellow
$output = & $godotPath --headless --path . --script scripts/test_maze_generation.gd 2>&1 | Out-String
$output | Out-File -FilePath "test_maze_generation_output.txt" -Encoding UTF8
if ($output -match "PASSED" -and $output -notmatch "FAILED|ERROR") {
    Write-Host "  ✓ Maze Generation: PASSED" -ForegroundColor Green
    $testResults["Maze Generation"] = "PASSED"
} else {
    Write-Host "  ✗ Maze Generation: FAILED" -ForegroundColor Red
    $testResults["Maze Generation"] = "FAILED"
    $allPassed = $false
}

# Test 3: Runtime Test
Write-Host "[3/5] Running Runtime Test..." -ForegroundColor Yellow
$output = & $godotPath --headless --path . --script scripts/test_runtime.gd 2>&1 | Out-String
$output | Out-File -FilePath "test_runtime_output.txt" -Encoding UTF8
if ($output -match "PASSED" -and $output -notmatch "FAILED|ERROR") {
    Write-Host "  ✓ Runtime: PASSED" -ForegroundColor Green
    $testResults["Runtime"] = "PASSED"
} else {
    Write-Host "  ✗ Runtime: FAILED" -ForegroundColor Red
    $testResults["Runtime"] = "FAILED"
    $allPassed = $false
}

# Test 4: Scene Analysis
Write-Host "[4/5] Running Scene Analysis..." -ForegroundColor Yellow
$output = & $godotPath --headless --path . --script scripts/analyze_scenes.gd 2>&1 | Out-String
$output | Out-File -FilePath "test_analysis_output.txt" -Encoding UTF8
if ($output -match "PASSED" -and $output -notmatch "FAILED|ERROR") {
    Write-Host "  ✓ Scene Analysis: PASSED" -ForegroundColor Green
    $testResults["Scene Analysis"] = "PASSED"
} else {
    Write-Host "  ✗ Scene Analysis: FAILED" -ForegroundColor Red
    $testResults["Scene Analysis"] = "FAILED"
    $allPassed = $false
}

# Test 5: Test Runner (Master Test)
Write-Host "[5/5] Running Master Test Runner..." -ForegroundColor Yellow
$output = & $godotPath --headless --path . test_runner.tscn 2>&1 | Out-String
$output | Out-File -FilePath "test_runner_output.txt" -Encoding UTF8
if ($output -match "PASSED" -and $output -notmatch "FAILED|ERROR") {
    Write-Host "  ✓ Test Runner: PASSED" -ForegroundColor Green
    $testResults["Test Runner"] = "PASSED"
} else {
    Write-Host "  ✗ Test Runner: FAILED" -ForegroundColor Red
    $testResults["Test Runner"] = "FAILED"
    $allPassed = $false
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
foreach ($test in $testResults.Keys) {
    $status = $testResults[$test]
    $color = if ($status -eq "PASSED") { "Green" } else { "Red" }
    Write-Host "$test : $status" -ForegroundColor $color
}

Write-Host ""
if ($allPassed) {
    Write-Host "✅ ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ SOME TESTS FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check output files for details:" -ForegroundColor Yellow
    Write-Host "  - test_scene_validation_output.txt" -ForegroundColor White
    Write-Host "  - test_maze_generation_output.txt" -ForegroundColor White
    Write-Host "  - test_runtime_output.txt" -ForegroundColor White
    Write-Host "  - test_analysis_output.txt" -ForegroundColor White
    Write-Host "  - test_runner_output.txt" -ForegroundColor White
    exit 1
}

