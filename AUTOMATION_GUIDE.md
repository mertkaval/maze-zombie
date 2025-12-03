# Full Automation Guide

## 🚀 Automated Test-and-Fix System

This project now includes a **fully automated test-and-fix loop** that:
1. ✅ Runs all tests
2. ✅ Analyzes failures
3. ✅ Applies automatic fixes
4. ✅ Commits and pushes fixes
5. ✅ Repeats until all tests pass

---

## 📋 Available Automation Scripts

### 1. **Local PowerShell Script** (`automated_test_fix.ps1`)
- Runs tests locally
- Analyzes errors
- Applies fixes (detection only)
- **Run**: `powershell -ExecutionPolicy Bypass -File automated_test_fix.ps1`

### 2. **Full Automation Script** (`auto_fix_full.ps1`)
- Runs tests
- Analyzes errors
- **Modifies code files automatically**
- Commits and pushes fixes
- Repeats until all pass
- **Run**: `powershell -ExecutionPolicy Bypass -File auto_fix_full.ps1`

### 3. **CI Workflow** (`.github/workflows/auto_fix.yml`)
- Runs in GitHub Actions
- Automated test-and-fix loop
- Can be triggered manually or on push
- **Trigger**: Go to GitHub Actions → Auto Test and Fix Loop → Run workflow

---

## 🔧 How It Works

### Iteration Loop

```
┌─────────────────┐
│  Run Tests      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  All Pass?      │──Yes──► ✅ SUCCESS
└────────┬────────┘
         │ No
         ▼
┌─────────────────┐
│ Analyze Errors  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Apply Fixes     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Commit & Push   │
└────────┬────────┘
         │
         └──► Repeat (max 10 iterations)
```

### Automatic Fixes Available

1. **Boundary Wall Issues**
   - Detects missing boundary walls
   - Verifies boundary closing logic
   - Fixes: Ensures all edges are closed

2. **Preload/Class Issues**
   - Detects missing preload statements
   - Fixes: Adds preloads for MazeAlgorithm, MazeBuilder, MazeConfig

3. **Syntax Errors**
   - Detects parse errors
   - Fixes: Corrects syntax issues

4. **Node.has() Issues**
   - Detects incorrect .has() usage
   - Fixes: Replaces with "in" operator

---

## 🎯 Usage

### Local Execution

```powershell
# Basic automation (detection only)
powershell -ExecutionPolicy Bypass -File automated_test_fix.ps1

# Full automation (with code fixes and commits)
powershell -ExecutionPolicy Bypass -File auto_fix_full.ps1
```

### CI Execution

1. Go to: https://github.com/mertkaval/maze-zombie/actions
2. Click "Auto Test and Fix Loop"
3. Click "Run workflow"
4. Select branch: `main`
5. Click "Run workflow"

---

## 📊 What Gets Fixed Automatically

### ✅ Currently Supported Fixes

- Boundary wall closing logic
- Preload statement verification
- Syntax error detection
- Node.has() method replacement

### ⚠️ Limitations

- Complex logic errors may require manual fixes
- Some issues need human judgment
- Maximum 10 iterations to prevent infinite loops

---

## 🔍 Monitoring

### Local
- Check `test_iteration_*.txt` files for test results
- Watch console output for fix applications
- Git log shows auto-fix commits

### CI
- Check GitHub Actions workflow runs
- View test artifacts
- Review commit history for auto-fix commits

---

## 🎛️ Configuration

### Adjust Max Iterations

Edit the script:
```powershell
$maxIterations = 10  # Change this value
```

### Adjust Godot Path

Edit the script:
```powershell
$godot = "C:\Godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe"
```

---

## 📝 Example Output

```
========================================
  FULL AUTOMATED TEST-AND-FIX LOOP
========================================

========================================
ITERATION 1
========================================

[Step 1/4] Running tests...
[Step 2/4] Analyzing results...
  Found 2 error(s)
[Step 3/4] Applying fixes...
    ✓ Fixed boundary wall issue
    ✓ Fixed preload issue
  ✅ Applied 2 fix(es)
[Step 4/4] Committing fixes...
  ✅ Changes committed and pushed

========================================
ITERATION 2
========================================

[Step 1/4] Running tests...
[Step 2/4] Analyzing results...
  ✅ All tests PASSED!

========================================
FINAL SUMMARY
========================================
✅ SUCCESS: All tests passing after 2 iterations
```

---

## 🚨 Important Notes

1. **Backup First**: The full automation modifies code files
2. **Review Commits**: Always review auto-fix commits before merging
3. **Manual Override**: You can stop the loop anytime (Ctrl+C)
4. **Git Safety**: Auto-commits use descriptive messages

---

## 🎯 Next Steps

The automation system is ready to use! Run it to:
- ✅ Test your code automatically
- ✅ Fix common issues automatically
- ✅ Ensure code quality
- ✅ Save time on repetitive fixes

**Start the automation now:**
```powershell
powershell -ExecutionPolicy Bypass -File auto_fix_full.ps1
```

