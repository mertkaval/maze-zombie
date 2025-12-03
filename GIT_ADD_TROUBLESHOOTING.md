# Git Add Troubleshooting Guide

## Problem: `git add` Hangs

Unlike `git commit` (which hangs due to editor issues), `git add` hangs for different reasons. The command appears to freeze and never completes.

## Why This Happens

`git add` should be fast and shouldn't require an editor. When it hangs, it's usually due to:

1. **File locks** - Another process (Godot editor, VS Code, etc.) has the file open
2. **Antivirus scanning** - Real-time antivirus is scanning files during Git operations
3. **Git index corruption** - The `.git/index` file is corrupted or locked
4. **PowerShell delays** - Terminal appears hung but Git is actually processing (slow, not stuck)
5. **File system issues** - Network drives, permissions, or file system problems
6. **.gitattributes processing** - Line ending conversion can be slow for large files

## Quick Diagnosis

Run the diagnostic script:

```powershell
.\scripts\diagnose_git_add.ps1 maze_generator.gd
```

This will check:
- File locks
- Git index status
- File permissions
- Running Git processes
- Test `git add` with timeout
- `.gitattributes` configuration

## Quick Fixes

### Fix 1: Close File Handles

**Most common cause:** Godot editor or another program has the file open.

**Solution:**
1. Close Godot editor
2. Close VS Code or any other editor with the file open
3. Close File Explorer if the file is selected
4. Wait a few seconds
5. Try `git add` again

### Fix 2: Use Force Add

Bypass some Git checks:

```powershell
git add -f maze_generator.gd
```

The `-f` (force) flag bypasses some safety checks and may work when normal `git add` hangs.

### Fix 3: Kill Stuck Git Processes

If a previous `git add` command is still running:

```powershell
# Check for Git processes
Get-Process -Name "git"

# Kill them (if stuck)
Get-Process -Name "git" | Stop-Process -Force
```

Or use the fix script:

```powershell
.\scripts\fix_git_add_hanging.ps1 maze_generator.gd -Force
```

### Fix 4: Repair Git Index

If the Git index is corrupted:

```powershell
# Reset the file from index
git reset HEAD -- maze_generator.gd

# Refresh index
git add --refresh

# Try adding again
git add maze_generator.gd
```

### Fix 5: Use Alternative Commands

Instead of `git add`, try:

```powershell
# Add all files (sometimes faster)
git add -A

# Or commit directly (skips staging)
git commit -a -m "Your message"
```

### Fix 6: Clear Git Cache

Remove the file from Git's cache and re-add:

```powershell
# Remove from cache
git rm --cached maze_generator.gd

# Add again
git add maze_generator.gd
```

## Automated Fix Script

Run the automated fix script:

```powershell
.\scripts\fix_git_add_hanging.ps1 maze_generator.gd
```

This script will:
- Check for stuck Git processes
- Check file locks
- Repair Git index if needed
- Clear Git cache
- Try multiple `git add` methods
- Provide specific recommendations

## Prevention

### 1. Close Editors Before Git Operations

Always close Godot editor and other editors before running Git commands:

```powershell
# Close Godot first, then:
git add .
git commit -m "Changes"
```

### 2. Exclude Git from Antivirus Scanning

Add Git directories to antivirus exclusions:
- `.git` folder
- Project root directory
- Git installation directory (usually `C:\Program Files\Git`)

### 3. Use Batch Operations

Instead of multiple `git add` commands:

```powershell
# Add all files at once
git add -A

# Or add specific patterns
git add *.gd
```

### 4. Check File Status First

Always check status before adding:

```powershell
git status --short
```

This helps identify issues before they cause hangs.

## Advanced Troubleshooting

### Check File Locks

In PowerShell:

```powershell
# Try to open file exclusively
$file = [System.IO.File]::Open("maze_generator.gd", 'Open', 'ReadWrite', 'None')
$file.Close()
```

If this fails, the file is locked by another process.

### Check Git Index

```powershell
# Check index file
Get-Item .git\index | Select-Object Length, LastWriteTime

# Check if index is readable
Get-Content .git\index -Raw
```

### Monitor Git Processes

```powershell
# Watch Git processes
Get-Process -Name "git" | Format-Table Id, StartTime, CPU

# Kill specific process
Stop-Process -Id <PID> -Force
```

### Test with Timeout

Test if `git add` actually hangs:

```powershell
$job = Start-Job -ScriptBlock { git add maze_generator.gd }
$completed = $job | Wait-Job -Timeout 10
if ($completed) {
    Write-Host "Completed"
} else {
    Write-Host "Hung - kill with: Stop-Job $job"
}
```

## Common Scenarios

### Scenario 1: Godot Editor Open

**Symptom:** `git add` hangs when Godot editor is running

**Solution:**
1. Close Godot editor
2. Wait 2-3 seconds
3. Run `git add` again

**Prevention:** Always close Godot before Git operations

### Scenario 2: Antivirus Scanning

**Symptom:** `git add` hangs randomly, especially on first run

**Solution:**
1. Add Git directories to antivirus exclusions
2. Temporarily disable real-time scanning for testing
3. Use `git add -f` to bypass some checks

### Scenario 3: Large Files

**Symptom:** `git add` hangs on large files

**Solution:**
1. Check `.gitattributes` - line ending conversion can be slow
2. Use `git add -f` to skip some processing
3. Consider adding large files to `.gitignore` if not needed

### Scenario 4: Network Drive

**Symptom:** `git add` hangs on network/shared drives

**Solution:**
1. Move repository to local drive
2. Use `git add -f` to reduce network operations
3. Check network connection stability

## Related Issues

### Git Commit Hangs

If `git commit` hangs (different issue), see [`GIT_SETUP.md`](GIT_SETUP.md) for editor configuration.

### Git Status Slow

If `git status` is slow but not hanging:
- Run `git gc` to clean up repository
- Check for large files in repository
- Consider using `git status --short` for faster output

## Still Having Issues?

1. Run diagnostic script: `.\scripts\diagnose_git_add.ps1 <file>`
2. Run fix script: `.\scripts\fix_git_add_hanging.ps1 <file> -Force`
3. Check Git version: `git --version`
4. Try in Git Bash instead of PowerShell
5. Check Windows Event Viewer for file system errors

## Additional Resources

- [Git Documentation - git add](https://git-scm.com/docs/git-add)
- [Git Documentation - git config](https://git-scm.com/docs/git-config)
- [PowerShell File Operations](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/)

