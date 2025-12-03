# CI Test Scripts

This directory contains test scripts for validating the maze scene generation system.

## Test Scripts

- **test_scene_validation.gd** - Validates all scenes can load and have correct structure
- **test_maze_generation.gd** - Tests maze generation works correctly
- **test_runtime.gd** - Tests scenes run without crashes
- **analyze_scenes.gd** - Deep analysis of scenes to find issues
- **fix_scene_issues.gd** - Automatically fixes common scene issues
- **run_all_tests.gd** - Master test runner (coordination script)

## Running Tests Locally

### In Editor:
1. Open any test script in Script Editor
2. Go to **File > Run** (or press `Ctrl+Shift+X`)
3. Check output for results

### From Command Line:
```bash
godot --headless --path . -s scripts/test_scene_validation.gd
```

Note: EditorScripts may require editor context. For CI, the GitHub Actions workflow handles execution.

## CI Pipeline

The GitHub Actions workflow (`.github/workflows/test.yml`) automatically:
1. Downloads Godot 4.5.1 headless
2. Runs all test scripts
3. Generates test reports
4. Fails pipeline on errors

## Test Coverage

- Scene file existence and loading
- Node structure validation
- Script attachment verification
- Resource dependency checking
- Maze generation functionality
- Prefab instantiation
- Collision shape validation
- Material and mesh validation

