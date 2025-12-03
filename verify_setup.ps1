# Quick verification script for maze-zombie project
# Checks that all required files exist and are properly structured

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Maze Zombie Project Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# Check required files
$requiredFiles = @(
    "project.godot",
    "main.tscn",
    "maze.tscn",
    "player.tscn",
    "floor_tile.tscn",
    "wall_tile.tscn",
    "maze_generator.gd",
    "maze_config.gd",
    "maze_algorithm.gd",
    "maze_builder.gd",
    "player_controller.gd",
    "generate_maze_editor.gd"
)

Write-Host "Checking required files..." -ForegroundColor Yellow
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: $file" -ForegroundColor Red
        $errors++
    }
}

# Check test scripts
Write-Host ""
Write-Host "Checking test scripts..." -ForegroundColor Yellow
$testScripts = @(
    "scripts/test_scene_validation.gd",
    "scripts/test_maze_generation.gd",
    "scripts/test_runtime.gd",
    "scripts/analyze_scenes.gd",
    "scripts/test_runner.gd",
    "test_runner.tscn"
)

foreach ($script in $testScripts) {
    if (Test-Path $script) {
        Write-Host "  ✓ $script" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: $script" -ForegroundColor Red
        $errors++
    }
}

# Check CI workflow
Write-Host ""
Write-Host "Checking CI pipeline..." -ForegroundColor Yellow
if (Test-Path ".github/workflows/test.yml") {
    Write-Host "  ✓ CI workflow exists" -ForegroundColor Green
} else {
    Write-Host "  ✗ Missing CI workflow" -ForegroundColor Red
    $errors++
}

# Check project.godot for main scene
Write-Host ""
Write-Host "Checking project configuration..." -ForegroundColor Yellow
if (Test-Path "project.godot") {
    $content = Get-Content "project.godot" -Raw
    if ($content -match 'run/main_scene="res://main\.tscn"') {
        Write-Host "  ✓ Main scene configured correctly" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Main scene may not be configured" -ForegroundColor Yellow
        $warnings++
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($errors -eq 0) {
    Write-Host "Errors: $errors" -ForegroundColor Green
} else {
    Write-Host "Errors: $errors" -ForegroundColor Red
}
if ($warnings -eq 0) {
    Write-Host "Warnings: $warnings" -ForegroundColor Green
} else {
    Write-Host "Warnings: $warnings" -ForegroundColor Yellow
}
Write-Host ""

if ($errors -eq 0) {
    Write-Host "✅ Project structure looks good!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Open project in Godot 4.5.1" -ForegroundColor White
    Write-Host "2. Run Tools > Run Script > generate_maze_editor.gd" -ForegroundColor White
    Write-Host "3. Press F5 to play the game" -ForegroundColor White
    Write-Host "4. Or push to GitHub to run CI tests" -ForegroundColor White
} else {
    Write-Host "❌ Found $errors error(s) - please fix before testing" -ForegroundColor Red
}
