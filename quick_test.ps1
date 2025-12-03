# Quick test runner - 2 minute limit
$godot = "C:\Godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe"
$console = "C:\Godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe"

Write-Host "=== Quick Test Suite ===" -ForegroundColor Cyan
Write-Host "Using: $console" -ForegroundColor Yellow

# Test 1: Scene Validation (30 seconds max)
Write-Host "`n[1/3] Scene Validation..." -ForegroundColor Yellow
$job1 = Start-Job -ScriptBlock { param($g) & $g --headless --path C:\Users\mert3\maze-zombie --script scripts/test_scene_validation.gd 2>&1 } -ArgumentList $console
Wait-Job $job1 -Timeout 30 | Out-Null
$result1 = Receive-Job $job1
$result1 | Out-File "test_scene_validation_output.txt" -Encoding UTF8
Stop-Job $job1 -ErrorAction SilentlyContinue
Remove-Job $job1 -ErrorAction SilentlyContinue
if ($result1 -match "PASSED" -and $result1 -notmatch "FAILED") {
    Write-Host "  ✓ PASSED" -ForegroundColor Green
} else {
    Write-Host "  ✗ FAILED" -ForegroundColor Red
}

# Test 2: Test Runner Scene (30 seconds max)
Write-Host "`n[2/3] Test Runner..." -ForegroundColor Yellow
$job2 = Start-Job -ScriptBlock { param($g) & $g --headless --path C:\Users\mert3\maze-zombie test_runner.tscn 2>&1 } -ArgumentList $console
Wait-Job $job2 -Timeout 30 | Out-Null
$result2 = Receive-Job $job2
$result2 | Out-File "test_runner_output.txt" -Encoding UTF8
Stop-Job $job2 -ErrorAction SilentlyContinue
Remove-Job $job2 -ErrorAction SilentlyContinue
if ($result2 -match "PASSED" -and $result2 -notmatch "FAILED") {
    Write-Host "  ✓ PASSED" -ForegroundColor Green
} else {
    Write-Host "  ✗ FAILED" -ForegroundColor Red
}

# Test 3: Check CI workflow file
Write-Host "`n[3/3] CI Pipeline Check..." -ForegroundColor Yellow
if (Test-Path ".github\workflows\test.yml") {
    Write-Host "  ✓ CI workflow exists" -ForegroundColor Green
    $ciContent = Get-Content ".github\workflows\test.yml" -Raw
    if ($ciContent -match "godot.*4\.5\.1") {
        Write-Host "  ✓ Godot 4.5.1 configured" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ CI workflow missing" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Check output files for details" -ForegroundColor Yellow

