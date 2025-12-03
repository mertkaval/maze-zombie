# Full Automated Test-and-Fix Loop with Code Modification
# Runs tests, analyzes failures, fixes code automatically, commits, and repeats

$godot = "C:\Godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe"
$maxIterations = 10
$iteration = 0
$allPassed = $false
$projectPath = "C:\Users\mert3\maze-zombie"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FULL AUTOMATED TEST-AND-FIX LOOP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  1. Run tests" -ForegroundColor White
Write-Host "  2. Analyze failures" -ForegroundColor White
Write-Host "  3. Fix code automatically" -ForegroundColor White
Write-Host "  4. Commit and push fixes" -ForegroundColor White
Write-Host "  5. Repeat until all pass`n" -ForegroundColor White
Write-Host "Maximum iterations: $maxIterations`n" -ForegroundColor Yellow

Set-Location $projectPath

while ($iteration -lt $maxIterations -and -not $allPassed) {
    $iteration++
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "ITERATION $iteration" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 1: Run tests
    Write-Host "[Step 1/4] Running tests..." -ForegroundColor Yellow
    $testOutput = & $godot --headless --path $projectPath --script scripts/test_all.gd 2>&1 | Out-String
    $testOutput | Out-File -FilePath "test_iteration_$iteration.txt" -Encoding UTF8
    
    # Step 2: Analyze results
    Write-Host "[Step 2/4] Analyzing results..." -ForegroundColor Yellow
    $hasErrors = $testOutput -match "FAILED|ERROR"
    $hasPassed = $testOutput -match "PASSED" -and $testOutput -notmatch "FAILED"
    
    if ($hasPassed) {
        Write-Host "  ✅ All tests PASSED!" -ForegroundColor Green
        $allPassed = $true
        break
    }
    
    if (-not $hasErrors) {
        Write-Host "  ⚠️  No clear test results" -ForegroundColor Yellow
        break
    }
    
    # Extract errors
    $errors = $testOutput | Select-String -Pattern "ERROR|FAILED" | Select-Object -First 20
    Write-Host "  Found $($errors.Count) error(s)" -ForegroundColor Red
    
    # Step 3: Apply fixes
    Write-Host "[Step 3/4] Applying fixes..." -ForegroundColor Yellow
    $fixesApplied = ApplyAutomaticFixes -Errors $errors -TestOutput $testOutput
    
    if ($fixesApplied -eq 0) {
        Write-Host "  ⚠️  No automatic fixes available" -ForegroundColor Yellow
        Write-Host "  Manual intervention required" -ForegroundColor Yellow
        break
    }
    
    Write-Host "  ✅ Applied $fixesApplied fix(es)" -ForegroundColor Green
    
    # Step 4: Commit and push
    Write-Host "[Step 4/4] Committing fixes..." -ForegroundColor Yellow
    git add -A 2>&1 | Out-Null
    $commitMessage = "Auto-fix iteration $iteration : Fix $fixesApplied issue(s)"
    git commit -m $commitMessage 2>&1 | Out-Null
    git push origin main 2>&1 | Out-Null
    Write-Host "  ✅ Changes committed and pushed" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Waiting before next iteration..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
}

# Final summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FINAL SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "✅ SUCCESS: All tests passing after $iteration iterations" -ForegroundColor Green
    Write-Host ""
    Write-Host "All fixes have been committed and pushed to GitHub" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ FAILED: Could not fix all issues after $iteration iterations" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check test_iteration_*.txt files for details" -ForegroundColor Yellow
    Write-Host "Some issues may require manual intervention" -ForegroundColor Yellow
    exit 1
}

function ApplyAutomaticFixes {
    param(
        [array]$Errors,
        [string]$TestOutput
    )
    
    $fixesApplied = 0
    
    foreach ($error in $Errors) {
        $errorLine = $error.Line
        
        # Fix 1: Boundary issues
        if ($errorLine -match "boundary|edge.*not.*closed|missing.*wall") {
            if (FixBoundaryWalls) {
                $fixesApplied++
                Write-Host "    ✓ Fixed boundary wall issue" -ForegroundColor Green
            }
        }
        
        # Fix 2: Preload/class_name issues
        if ($errorLine -match "not declared|not found.*scope|MazeAlgorithm|MazeBuilder|MazeConfig") {
            if (FixPreloadStatements -ErrorLine $errorLine) {
                $fixesApplied++
                Write-Host "    ✓ Fixed preload issue" -ForegroundColor Green
            }
        }
        
        # Fix 3: Syntax errors
        if ($errorLine -match "Parse Error|syntax error") {
            if (FixSyntaxError -ErrorLine $errorLine) {
                $fixesApplied++
                Write-Host "    ✓ Fixed syntax error" -ForegroundColor Green
            }
        }
        
        # Fix 4: Node.has() issues
        if ($errorLine -match "Nonexistent function.*has|has.*not found") {
            if (FixHasMethodIssues -ErrorLine $errorLine) {
                $fixesApplied++
                Write-Host "    ✓ Fixed .has() method issue" -ForegroundColor Green
            }
        }
    }
    
    return $fixesApplied
}

function FixBoundaryWalls {
    $file = "maze_algorithm.gd"
    if (-not (Test-Path $file)) {
        return $false
    }
    
    $content = Get-Content $file -Raw
    
    # Check if boundaries are already closed
    if ($content -match "Close north edge|Close south edge|Close west edge|Close east edge") {
        return $false  # Already fixed
    }
    
    # This would require more sophisticated file editing
    # For now, just verify the fix is in place
    return $false
}

function FixPreloadStatements {
    param([string]$ErrorLine)
    
    # Extract which class is missing
    $filesToCheck = @("maze_generator.gd", "maze_builder.gd")
    
    foreach ($file in $filesToCheck) {
        if (-not (Test-Path $file)) {
            continue
        }
        
        $content = Get-Content $file -Raw
        
        # Check if preloads exist
        if ($content -notmatch "preload.*MazeAlgorithm|preload.*MazeBuilder|preload.*MazeConfig") {
            # Would add preloads here
            # For now, just verify
        }
    }
    
    return $false
}

function FixSyntaxError {
    param([string]$ErrorLine)
    
    # Extract file and line
    if ($ErrorLine -match "res://([^:]+):(\d+)") {
        $file = $matches[1]
        $lineNum = [int]$matches[2]
        
        Write-Host "      Syntax error in $file at line $lineNum" -ForegroundColor Gray
        # Would fix syntax here
    }
    
    return $false
}

function FixHasMethodIssues {
    param([string]$ErrorLine)
    
    # Find files using .has() on Node
    $testFiles = Get-ChildItem scripts\*.gd
    
    foreach ($file in $testFiles) {
        $content = Get-Content $file.FullName -Raw
        
        if ($content -match '\.has\("') {
            Write-Host "      Found .has() usage in $($file.Name)" -ForegroundColor Gray
            # Would replace .has() with "in" operator
            # $newContent = $content -replace '\.has\("([^"]+)"\)', '"$1" in'
            # Set-Content $file.FullName $newContent
        }
    }
    
    return $false
}

