# diagnose_git_add.ps1
# Diagnostic script to identify why git add hangs
# Usage: .\scripts\diagnose_git_add.ps1 [file_path]
# Example: .\scripts\diagnose_git_add.ps1 maze_generator.gd

param(
    [string]$FilePath = "maze_generator.gd"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Git Add Diagnostic Tool" -ForegroundColor Cyan
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
    Write-Host "  Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ File found: $FilePath" -ForegroundColor Green
Write-Host ""

# 1. Check if file is locked by another process
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  1. Checking for file locks..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$fileLocked = $false
$lockingProcesses = @()

try {
    # Try to open file exclusively to check for locks
    $fileStream = [System.IO.File]::Open($FilePath, 'Open', 'ReadWrite', 'None')
    $fileStream.Close()
    Write-Host "✓ File is not locked" -ForegroundColor Green
} catch {
    $fileLocked = $true
    Write-Host "⚠ File appears to be locked or inaccessible" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
    
    # Try to find processes using the file
    Write-Host ""
    Write-Host "  Checking for processes that might be using this file..." -ForegroundColor Yellow
    
    # Check for common editors/processes
    $commonProcesses = @("Godot", "code", "notepad", "notepad++", "gvim", "vim")
    foreach ($procName in $commonProcesses) {
        $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($procs) {
            $lockingProcesses += $procName
            Write-Host "  ⚠ Found process: $procName" -ForegroundColor Yellow
        }
    }
    
    if ($lockingProcesses.Count -eq 0) {
        Write-Host "  ℹ No obvious editor processes found" -ForegroundColor Gray
        Write-Host "  Suggestion: Close any programs that might have this file open" -ForegroundColor Yellow
    }
}

Write-Host ""

# 2. Check Git index status
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  2. Checking Git index..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$indexPath = ".git\index"
if (Test-Path $indexPath) {
    $indexSize = (Get-Item $indexPath).Length
    $indexModified = (Get-Item $indexPath).LastWriteTime
    
    Write-Host "✓ Git index found" -ForegroundColor Green
    Write-Host "  Size: $indexSize bytes" -ForegroundColor Gray
    Write-Host "  Last modified: $indexModified" -ForegroundColor Gray
    
    # Check if index is suspiciously large or old
    if ($indexSize -gt 10MB) {
        Write-Host "  ⚠ Index file is unusually large (>10MB)" -ForegroundColor Yellow
        Write-Host "  Suggestion: Consider running 'git gc' to clean up" -ForegroundColor Yellow
    }
    
    # Try to read index (basic corruption check)
    try {
        $indexContent = Get-Content $indexPath -Raw -ErrorAction Stop
        Write-Host "  ✓ Index file is readable" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Index file appears corrupted or unreadable" -ForegroundColor Red
        Write-Host "  Suggestion: Run 'git reset' or 'git add --fix' to repair" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Git index file not found" -ForegroundColor Red
    Write-Host "  Suggestion: Run 'git init' or check if you're in a Git repository" -ForegroundColor Yellow
}

Write-Host ""

# 3. Check file permissions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  3. Checking file permissions..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    $fileInfo = Get-Item $FilePath
    $acl = Get-Acl $FilePath
    
    Write-Host "✓ File permissions check passed" -ForegroundColor Green
    Write-Host "  File size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    Write-Host "  Read-only: $($fileInfo.IsReadOnly)" -ForegroundColor Gray
    
    if ($fileInfo.IsReadOnly) {
        Write-Host "  ⚠ File is read-only" -ForegroundColor Yellow
        Write-Host "  Suggestion: Remove read-only attribute: attrib -r $FilePath" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Error checking file permissions: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 4. Check if Git process is running
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  4. Checking Git processes..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$gitProcesses = Get-Process -Name "git" -ErrorAction SilentlyContinue
if ($gitProcesses) {
    Write-Host "⚠ Found $($gitProcesses.Count) Git process(es) running:" -ForegroundColor Yellow
    foreach ($proc in $gitProcesses) {
        Write-Host "  - PID: $($proc.Id), Started: $($proc.StartTime)" -ForegroundColor Gray
    }
    Write-Host "  Suggestion: Wait for these processes to complete or kill them if stuck" -ForegroundColor Yellow
} else {
    Write-Host "✓ No Git processes currently running" -ForegroundColor Green
}

Write-Host ""

# 5. Test git add with timeout
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  5. Testing git add (with 10 second timeout)..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "  Running: git add $FilePath" -ForegroundColor Gray
Write-Host "  (This will timeout after 10 seconds if it hangs)" -ForegroundColor Gray
Write-Host ""

# First, unstage the file if it's already staged
git reset HEAD -- $FilePath 2>&1 | Out-Null

# Try git add with timeout
$job = Start-Job -ScriptBlock {
    param($file)
    Set-Location $using:PWD
    git add $file 2>&1
} -ArgumentList $FilePath

$completed = $job | Wait-Job -Timeout 10

if ($completed) {
    $result = Receive-Job $job
    Remove-Job $job
    
    if ($LASTEXITCODE -eq 0 -or -not $result) {
        Write-Host "✓ git add completed successfully" -ForegroundColor Green
        # Unstage for testing
        git reset HEAD -- $FilePath 2>&1 | Out-Null
    } else {
        Write-Host "⚠ git add completed but may have warnings:" -ForegroundColor Yellow
        Write-Host $result -ForegroundColor Gray
    }
} else {
    Write-Host "✗ git add HUNG - did not complete within 10 seconds" -ForegroundColor Red
    Write-Host "  This confirms the hanging issue" -ForegroundColor Yellow
    Stop-Job $job
    Remove-Job $job
}

Write-Host ""

# 6. Check .gitattributes
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  6. Checking .gitattributes..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path ".gitattributes") {
    $gitattrs = Get-Content ".gitattributes"
    Write-Host "✓ .gitattributes found" -ForegroundColor Green
    Write-Host "  Content:" -ForegroundColor Gray
    foreach ($line in $gitattrs) {
        Write-Host "    $line" -ForegroundColor Gray
    }
    
    # Check if file matches any patterns
    if ($gitattrs -match "text|eol|crlf") {
        Write-Host "  ⚠ .gitattributes contains text/eol conversion rules" -ForegroundColor Yellow
        Write-Host "  This may cause delays during git add" -ForegroundColor Yellow
        Write-Host "  Suggestion: This is usually fine, but can be slow for large files" -ForegroundColor Gray
    }
} else {
    Write-Host "ℹ No .gitattributes file found" -ForegroundColor Gray
}

Write-Host ""

# Summary and recommendations
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Diagnostic Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issuesFound = @()

if ($fileLocked) {
    $issuesFound += "File is locked by another process"
}

if ($lockingProcesses.Count -gt 0) {
    $issuesFound += "Editor processes found: $($lockingProcesses -join ', ')"
}

if ($gitProcesses) {
    $issuesFound += "Git processes are running"
}

if (-not $completed) {
    $issuesFound += "git add confirmed to hang"
}

if ($issuesFound.Count -eq 0) {
    Write-Host "✓ No obvious issues detected" -ForegroundColor Green
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Yellow
    Write-Host "  - Antivirus real-time scanning" -ForegroundColor Gray
    Write-Host "  - Network file system delays" -ForegroundColor Gray
    Write-Host "  - PowerShell terminal delays (not actually hung)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Try running:" -ForegroundColor Yellow
    Write-Host "  .\scripts\fix_git_add_hanging.ps1 $FilePath" -ForegroundColor Cyan
} else {
    Write-Host "Issues found:" -ForegroundColor Yellow
    foreach ($issue in $issuesFound) {
        Write-Host "  ✗ $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Recommended fixes:" -ForegroundColor Yellow
    Write-Host "  1. Close any programs that have the file open" -ForegroundColor Cyan
    Write-Host "  2. Run: .\scripts\fix_git_add_hanging.ps1 $FilePath" -ForegroundColor Cyan
    Write-Host "  3. Try: git add -f $FilePath (force add)" -ForegroundColor Cyan
}

Write-Host ""

