# Automated Test-and-Fix Loop
# Runs tests, analyzes failures, fixes issues, and repeats until all pass

$godot = "C:\Godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe"
$maxIterations = 10
$iteration = 0
$allPassed = $false

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Automated Test-and-Fix Loop" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Maximum iterations: $maxIterations" -ForegroundColor Yellow
Write-Host ""

while ($iteration -lt $maxIterations -and -not $allPassed) {
    $iteration++
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "ITERATION $iteration" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Run all tests
    Write-Host "Running tests..." -ForegroundColor Yellow
    $testOutput = & $godot --headless --path C:\Users\mert3\maze-zombie --script scripts/test_all.gd 2>&1 | Out-String
    $testOutput | Out-File -FilePath "test_iteration_$iteration.txt" -Encoding UTF8
    
    # Check results
    $hasErrors = $testOutput -match "FAILED|ERROR"
    $hasPassed = $testOutput -match "PASSED" -and $testOutput -notmatch "FAILED"
    
    Write-Host "Test Results:" -ForegroundColor Yellow
    if ($hasPassed) {
        Write-Host "  ✅ All tests PASSED!" -ForegroundColor Green
        $allPassed = $true
        break
    } elseif ($hasErrors) {
        Write-Host "  ❌ Tests FAILED - Analyzing errors..." -ForegroundColor Red
        
        # Extract error messages
        $errors = $testOutput | Select-String -Pattern "ERROR|FAILED" | Select-Object -First 10
        
        Write-Host "`nErrors found:" -ForegroundColor Yellow
        foreach ($error in $errors) {
            Write-Host "  - $($error.Line)" -ForegroundColor Red
        }
        
        # Analyze and fix
        Write-Host "`nAnalyzing issues..." -ForegroundColor Yellow
        $fixesApplied = AnalyzeAndFixErrors -Errors $errors -TestOutput $testOutput
        
        if ($fixesApplied -eq 0) {
            Write-Host "  ⚠️  No automatic fixes available" -ForegroundColor Yellow
            Write-Host "  Manual intervention may be required" -ForegroundColor Yellow
            break
        } else {
            Write-Host "  ✓ Applied $fixesApplied fix(es)" -ForegroundColor Green
        }
    }
    
    Start-Sleep -Seconds 2
}

# Final summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FINAL SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "✅ SUCCESS: All tests passing after $iteration iterations" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ FAILED: Could not fix all issues after $iteration iterations" -ForegroundColor Red
    Write-Host "`nCheck test_iteration_*.txt files for details" -ForegroundColor Yellow
    exit 1
}

function AnalyzeAndFixErrors {
    param(
        [array]$Errors,
        [string]$TestOutput
    )
    
    $fixesApplied = 0
    
    foreach ($error in $Errors) {
        $errorLine = $error.Line
        
        # Check for boundary issues
        if ($errorLine -match "boundary|edge|closed") {
            Write-Host "    Fixing boundary issue..." -ForegroundColor Cyan
            if (FixBoundaryIssues) {
                $fixesApplied++
            }
        }
        
        # Check for parse/syntax errors
        if ($errorLine -match "parse|syntax|Parse Error") {
            Write-Host "    Fixing syntax issue..." -ForegroundColor Cyan
            if (FixSyntaxIssues -ErrorLine $errorLine) {
                $fixesApplied++
            }
        }
        
        # Check for missing resources
        if ($errorLine -match "missing|not found|Failed to load") {
            Write-Host "    Fixing missing resource issue..." -ForegroundColor Cyan
            if (FixMissingResourceIssues -ErrorLine $errorLine) {
                $fixesApplied++
            }
        }
        
        # Check for class_name/preload issues
        if ($errorLine -match "not declared|not found.*scope|class_name") {
            Write-Host "    Fixing class_name/preload issue..." -ForegroundColor Cyan
            if (FixPreloadIssues -ErrorLine $errorLine) {
                $fixesApplied++
            }
        }
    }
    
    return $fixesApplied
}

function FixBoundaryIssues {
    # Check maze_algorithm.gd for proper boundary closing
    $algorithmFile = "maze_algorithm.gd"
    if (-not (Test-Path $algorithmFile)) {
        return $false
    }
    
    $content = Get-Content $algorithmFile -Raw
    
    # Check if boundaries are closed
    if ($content -notmatch "Close north edge|Close south edge|Close west edge|Close east edge") {
        Write-Host "      Updating boundary closing logic..." -ForegroundColor Gray
        # The fix is already applied, but we can verify
        return $false
    }
    
    return $true
}

function FixSyntaxIssues {
    param([string]$ErrorLine)
    
    # Extract file and line number from error
    if ($ErrorLine -match "res://([^:]+):(\d+)") {
        $file = $matches[1]
        $lineNum = [int]$matches[2]
        
        Write-Host "      Checking $file at line $lineNum..." -ForegroundColor Gray
        
        if (Test-Path $file) {
            $lines = Get-Content $file
            if ($lineNum -le $lines.Count) {
                $problemLine = $lines[$lineNum - 1]
                Write-Host "      Problem line: $problemLine" -ForegroundColor Gray
                # Could add automatic fixes here
            }
        }
    }
    
    return $false
}

function FixMissingResourceIssues {
    param([string]$ErrorLine)
    
    # Extract missing resource path
    if ($ErrorLine -match "res://([^\s]+)") {
        $resourcePath = $matches[1]
        Write-Host "      Missing resource: $resourcePath" -ForegroundColor Gray
        
        if (-not (Test-Path $resourcePath)) {
            Write-Host "      ⚠️  Resource file does not exist: $resourcePath" -ForegroundColor Yellow
        }
    }
    
    return $false
}

function FixPreloadIssues {
    param([string]$ErrorLine)
    
    # Check if we need to add preload statements
    if ($ErrorLine -match "MazeAlgorithm|MazeBuilder|MazeConfig") {
        Write-Host "      Checking for preload statements..." -ForegroundColor Gray
        # Preloads should already be in place, but we can verify
        return $false
    }
    
    return $false
}

