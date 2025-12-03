# setup_git_editor.ps1
# PowerShell script to configure Git editor and prevent hanging issues
# Run this script to set up a reliable Git editor configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Git Editor Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Git is installed
try {
    $gitVersion = git --version 2>&1
    Write-Host "✓ Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Error: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "  Please install Git first: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Configure editor (notepad is reliable on Windows)
$editor = "notepad"
Write-Host "Configuring Git editor to: $editor" -ForegroundColor Yellow

# Set local (project-specific) editor
try {
    git config core.editor $editor
    Write-Host "✓ Local Git editor configured successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Error configuring local Git editor: $_" -ForegroundColor Red
    exit 1
}

# Ask if user wants to set global editor too
Write-Host ""
$setGlobal = Read-Host "Do you want to set this as your global Git editor? (Y/n)"
if ($setGlobal -eq "" -or $setGlobal -eq "Y" -or $setGlobal -eq "y") {
    try {
        git config --global core.editor $editor
        Write-Host "✓ Global Git editor configured successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error configuring global Git editor: $_" -ForegroundColor Red
        Write-Host "  Local configuration is still set" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Skipping global configuration (only local is set)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Show current configuration
$localEditor = git config core.editor
$globalEditor = git config --global core.editor

Write-Host "Local editor:  $localEditor" -ForegroundColor Cyan
if ($globalEditor) {
    Write-Host "Global editor: $globalEditor" -ForegroundColor Cyan
} else {
    Write-Host "Global editor: (not set)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✓ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "To verify, run: git config core.editor" -ForegroundColor Yellow
Write-Host "To test, run: git commit (without -m flag)" -ForegroundColor Yellow
Write-Host ""

