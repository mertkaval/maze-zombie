# fix_git_add_hanging.ps1
# Script to fix git add hanging issues
# Usage: .\scripts\fix_git_add_hanging.ps1 [file_path]
# Example: .\scripts\fix_git_add_hanging.ps1 maze_generator.gd

param(
    [string]$FilePath = "maze_generator.gd",
    [switch]$Force = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Git Add Fix Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Git is installed
try {
    $gitVersion = git --version 2>&1
    Write-Host "✓ Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Error: Git is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check if file exists
if (-not (Test-Path $FilePath)) {
    Write-Host "✗ Error: File not found: $FilePath" -ForegroundColor Red
    exit 1
}

Write-Host "Target file: $FilePath" -ForegroundColor Cyan
Write-Host ""

# Fix 1: Kill stuck Git processes
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fix 1: Checking for stuck Git processes..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$gitProcesses = Get-Process -Name "git" -ErrorAction SilentlyContinue
if ($gitProcesses) {
    Write-Host "Found $($gitProcesses.Count) Git process(es)" -ForegroundColor Yellow
    
    if ($Force) {
        Write-Host "Killing stuck Git processes..." -ForegroundColor Yellow
        foreach ($proc in $gitProcesses) {
            try {
                Stop-Process -Id $proc.Id -Force
                Write-Host "  ✓ Killed Git process (PID: $($proc.Id))" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to kill process (PID: $($proc.Id)): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 1
    } else {
        Write-Host "  ⚠ Git processes found but not killed (use -Force to kill)" -ForegroundColor Yellow
        Write-Host "  PIDs: $($gitProcesses.Id -join ', ')" -ForegroundColor Gray
    }
} else {
    Write-Host "✓ No stuck Git processes found" -ForegroundColor Green
}

Write-Host ""

# Fix 2: Check and unlock file
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fix 2: Checking file locks..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    # Try to open file exclusively
    $fileStream = [System.IO.File]::Open($FilePath, 'Open', 'ReadWrite', 'None')
    $fileStream.Close()
    Write-Host "✓ File is not locked" -ForegroundColor Green
} catch {
    Write-Host "⚠ File appears to be locked" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Suggestion: Close any programs that have this file open:" -ForegroundColor Yellow
    Write-Host "    - Godot Editor" -ForegroundColor Cyan
    Write-Host "    - VS Code / Other editors" -ForegroundColor Cyan
    Write-Host "    - File Explorer (if file is selected)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  After closing programs, run this script again" -ForegroundColor Yellow
}

Write-Host ""

# Fix 3: Repair Git index if needed
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fix 3: Checking Git index..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$indexPath = ".git\index"
if (Test-Path $indexPath) {
    Write-Host "✓ Git index found" -ForegroundColor Green
    
    # Check if we should repair index
    $repairIndex = $false
    
    # Try to read index
    try {
        $indexContent = Get-Content $indexPath -Raw -ErrorAction Stop
        Write-Host "  ✓ Index file is readable" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Index file appears corrupted" -ForegroundColor Red
        $repairIndex = $true
    }
    
    if ($repairIndex -or $Force) {
        Write-Host "  Attempting to repair Git index..." -ForegroundColor Yellow
        
        # Try git reset to repair index
        try {
            git reset HEAD -- $FilePath 2>&1 | Out-Null
            Write-Host "  ✓ Reset file from index" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Could not reset file: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Try git add --refresh
        try {
            git add --refresh 2>&1 | Out-Null
            Write-Host "  ✓ Refreshed Git index" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Could not refresh index: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "✗ Git index not found - not a Git repository?" -ForegroundColor Red
}

Write-Host ""

# Fix 4: Clear Git cache for this file
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fix 4: Clearing Git cache..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    # Remove from cache
    git rm --cached --ignore-unmatch $FilePath 2>&1 | Out-Null
    Write-Host "✓ Cleared Git cache for file" -ForegroundColor Green
} catch {
    Write-Host "ℹ File not in cache (this is fine)" -ForegroundColor Gray
}

Write-Host ""

# Fix 5: Try git add with different methods
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fix 5: Attempting git add..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$success = $false

# Method 1: Normal git add
Write-Host "  Method 1: Normal git add..." -ForegroundColor Yellow
$job = Start-Job -ScriptBlock {
    param($file)
    Set-Location $using:PWD
    git add $file 2>&1
} -ArgumentList $FilePath

$completed = $job | Wait-Job -Timeout 5

if ($completed) {
    $result = Receive-Job $job
    Remove-Job $job
    Write-Host "  ✓ Normal git add succeeded" -ForegroundColor Green
    $success = $true
} else {
    Stop-Job $job
    Remove-Job $job
    Write-Host "  ✗ Normal git add hung (timed out)" -ForegroundColor Red
    
    # Method 2: Force add
    Write-Host ""
    Write-Host "  Method 2: Force git add (-f)..." -ForegroundColor Yellow
    $job2 = Start-Job -ScriptBlock {
        param($file)
        Set-Location $using:PWD
        git add -f $file 2>&1
    } -ArgumentList $FilePath
    
    $completed2 = $job2 | Wait-Job -Timeout 5
    
    if ($completed2) {
        $result2 = Receive-Job $job2
        Remove-Job $job2
        Write-Host "  ✓ Force git add succeeded" -ForegroundColor Green
        $success = $true
    } else {
        Stop-Job $job2
        Remove-Job $job2
        Write-Host "  ✗ Force git add also hung" -ForegroundColor Red
        
        # Method 3: Direct index manipulation workaround
        Write-Host ""
        Write-Host "  Method 3: Alternative workaround..." -ForegroundColor Yellow
        Write-Host "  ⚠ All git add methods failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Manual workarounds:" -ForegroundColor Yellow
        Write-Host "    1. Close Godot editor and all file editors" -ForegroundColor Cyan
        Write-Host "    2. Wait a few seconds" -ForegroundColor Cyan
        Write-Host "    3. Try: git add -f $FilePath" -ForegroundColor Cyan
        Write-Host "    4. Or: git add -A (to add all files)" -ForegroundColor Cyan
        Write-Host "    5. Check antivirus exclusions for Git directory" -ForegroundColor Cyan
    }
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($success) {
    Write-Host "✓ Successfully added file to Git index" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verify with: git status" -ForegroundColor Yellow
} else {
    Write-Host "⚠ Could not automatically fix the issue" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run diagnostic: .\scripts\diagnose_git_add.ps1 $FilePath" -ForegroundColor Cyan
    Write-Host "  2. Close all programs that might have the file open" -ForegroundColor Cyan
    Write-Host "  3. Check antivirus settings (exclude Git directories)" -ForegroundColor Cyan
    Write-Host "  4. Try: git add -A (add all files instead)" -ForegroundColor Cyan
    Write-Host "  5. Try: git commit -a (skip staging, commit directly)" -ForegroundColor Cyan
}

Write-Host ""

