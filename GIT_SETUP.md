# Git Editor Setup Guide

## Problem: Git Editor Hanging

When running Git commands that require an editor (like `git commit` without the `-m` flag), Git may hang indefinitely if the editor is not properly configured. This happens because:

- `$env:GIT_EDITOR` environment variable is missing or misconfigured
- Git's fallback editor configuration doesn't work on Windows
- The configured editor doesn't exist or isn't accessible

## Solution

Configure Git to use a reliable editor. On Windows, `notepad` is a safe default that always works.

## Quick Fix

### Option 1: Run the Setup Script (Recommended)

Run the provided PowerShell script:

```powershell
.\scripts\setup_git_editor.ps1
```

This script will:
- Check if Git is installed
- Configure `notepad` as your Git editor (local and optionally global)
- Verify the configuration

### Option 2: Manual Configuration

#### Local (Project-Specific) Configuration

```powershell
git config core.editor notepad
```

This only affects this repository.

#### Global Configuration

```powershell
git config --global core.editor notepad
```

This affects all Git repositories on your system.

### Option 3: Use Environment Variable

Set the environment variable in PowerShell:

```powershell
$env:GIT_EDITOR = "notepad"
```

Note: This only lasts for the current PowerShell session. For persistence, add it to your PowerShell profile.

## Alternative Editors

If you prefer a different editor, you can use:

### Visual Studio Code

```powershell
git config --global core.editor "code --wait"
```

### Nano (if using Git Bash)

```powershell
git config --global core.editor "nano"
```

### Vim

```powershell
git config --global core.editor "vim"
```

### Custom Editor

```powershell
git config --global core.editor "path\to\your\editor.exe"
```

## Verify Configuration

Check your current Git editor setting:

```powershell
# Check local (project) setting
git config core.editor

# Check global setting
git config --global core.editor

# Check all Git config
git config --list
```

## Test the Fix

To verify the editor works correctly:

1. Make a change to a file
2. Stage it: `git add <file>`
3. Commit without `-m`: `git commit`
4. Notepad should open with the commit message template
5. Save and close Notepad
6. The commit should complete successfully

## Troubleshooting

### Git Still Hangs

1. Verify Git editor is set:
   ```powershell
   git config core.editor
   ```

2. If it shows an incorrect path, reset it:
   ```powershell
   git config --unset core.editor
   git config core.editor notepad
   ```

3. Check if notepad exists:
   ```powershell
   Test-Path C:\Windows\System32\notepad.exe
   ```

### Editor Opens But Commit Doesn't Complete

- Make sure you save and close the editor
- The editor must exit for Git to continue
- If using VS Code, ensure you use `code --wait` flag

### Using Git Bash Instead of PowerShell

If you're using Git Bash, you can use:

```bash
git config core.editor "notepad.exe"
```

Or use a Unix-style editor:

```bash
git config core.editor "nano"
```

## Project-Specific Configuration

This repository has `core.editor = notepad` configured in `.git/config`, so it should work out of the box. If you want to override it for this project only:

```powershell
git config core.editor "your-preferred-editor"
```

## Additional Resources

- [Git Configuration Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
- [Git Editor Configuration](https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreeditor)

