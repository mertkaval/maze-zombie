# Testing Guide for Maze Zombie Game

## Quick Test Checklist

### ✅ Pre-Test Verification
- [x] All scripts are syntactically correct
- [x] All scenes exist and are properly structured
- [x] Test scripts are ready for CI execution
- [x] Maze generation logic is complete
- [x] Player controller is implemented

## How to Test

### Option 1: Test in Godot Editor

1. **Open the project in Godot 4.5.1**
   ```
   - Launch Godot
   - Click "Import" 
   - Select the project.godot file
   - Click "Import & Edit"
   ```

2. **Generate the Maze**
   - Go to **Tools > Run Script** (or press `Ctrl+Shift+X`)
   - Select `generate_maze_editor.gd`
   - Click "Run"
   - Check output for success messages
   - Open `maze.tscn` in the editor to see the generated maze

3. **Test the Game**
   - Press `F5` or click the Play button
   - The game should start with:
     - A generated maze (40x40 tiles)
     - Player character at entry point
     - First-person camera controls
     - WASD movement
     - Mouse look

4. **Verify Controls**
   - **W/A/S/D**: Move forward/left/backward/right
   - **Mouse**: Look around (first-person camera)
   - **Space**: Jump (if implemented)
   - **ESC**: Release mouse cursor

### Option 2: Run Automated Tests

If you have Godot command line access:

```bash
# Run all tests
godot --headless --path . --script scripts/test_all.gd

# Run test runner scene
godot --headless --path . test_runner.tscn

# Run individual tests
godot --headless --path . --script scripts/test_scene_validation.gd
godot --headless --path . --script scripts/test_maze_generation.gd
godot --headless --path . --script scripts/test_runtime.gd
godot --headless --path . --script scripts/analyze_scenes.gd
```

### Option 3: CI Pipeline Testing

Push to GitHub and check the Actions tab:
```bash
git push origin main
```

The CI pipeline will automatically:
1. Download Godot 4.5.1 headless
2. Run all test scripts
3. Generate test reports
4. Show pass/fail status

## What to Verify

### Visual Checks
- [ ] Maze generates when opening `maze.tscn`
- [ ] Floor tiles are green (soft green color)
- [ ] Walls are grey (soft grey color)
- [ ] Maze has proper entry/exit at corners
- [ ] Maze is 40x40 tiles (160m x 160m total)
- [ ] Walls are 3 meters high
- [ ] Player appears at entry point in main scene

### Functional Checks
- [ ] Player can move with WASD
- [ ] Mouse controls camera (first-person)
- [ ] Player collides with walls
- [ ] Player can walk on floor tiles
- [ ] Maze is solvable (path from entry to exit exists)
- [ ] No console errors when running

### Performance Checks
- [ ] Maze generates in reasonable time (< 5 seconds)
- [ ] Game runs at acceptable FPS (60+)
- [ ] No memory leaks during gameplay

## Known Issues Fixed

✅ Placeholder resource validation errors - Fixed
✅ Async/await handling - Fixed  
✅ Division by zero in progress logging - Fixed
✅ Workflow file checking - Fixed
✅ Variable naming errors - Fixed

## Troubleshooting

### Maze doesn't appear
- Run `generate_maze_editor.gd` from Tools menu
- Check console for error messages
- Verify `floor_tile.tscn` and `wall_tile.tscn` exist

### Player can't move
- Check Input Map in Project Settings
- Verify `player_controller.gd` is attached to Player node
- Check that Camera3D is child of Player

### Maze generation errors
- Check that `maze_config.gd` is properly set up
- Verify config resource in `maze.tscn` scene
- Check console for placeholder resource errors

## Test Results

After testing, you should see:
- ✅ All scenes load correctly
- ✅ Maze generates successfully
- ✅ Player controls work
- ✅ No console errors
- ✅ CI pipeline passes all tests

