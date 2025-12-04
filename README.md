# Maze Zombie Game

A procedural 3D maze generator for Godot v4.5.1 with automated testing and CI pipeline.

## Features

- **Procedural Maze Generation**: 40x40 tile maze using recursive backtracking algorithm
- **3D Visualization**: Soft grey walls and soft green floors
- **Player Controller**: First-person controls with WASD and mouse look
- **Dynamic Maze Levels**: Generate multiple maze scenes with sequential naming (maze_01, maze_02, etc.)
- **Automated Testing**: CI pipeline with comprehensive test suite

## Project Structure

```
maze-zombie/
├── maze_generator.gd      # Main maze generator (@tool enabled)
├── maze_algorithm.gd      # Recursive backtracking algorithm
├── maze_builder.gd        # 3D geometry builder
├── maze_config.gd         # Configuration resource
├── generate_maze_level.gd  # Editor script to create new maze scenes
├── player_controller.gd   # First-person player controls
├── main.tscn              # Main game scene
├── player.tscn            # Player character scene
├── floor_tile.tscn        # Floor tile prefab
├── wall_tile.tscn         # Wall tile prefab
├── maze_levels/           # Generated maze scenes (maze_01.tscn, etc.)
└── scripts/               # Test scripts for CI
    ├── test_all.gd        # Main test runner
    ├── verify_maze_generation.gd
    ├── test_maze_generation.gd
    ├── test_scene_validation.gd
    ├── test_runtime.gd
    ├── test_maze_visual.gd
    ├── analyze_scenes.gd
    └── maze_scene_helper.gd
```

## Quick Start

### Generate a Maze Scene

1. Open Godot Editor
2. Go to **Tools > Run Script**
3. Select `generate_maze_level.gd`
4. Click **Run**
5. A new maze scene will be created in `maze_levels/` folder (maze_01.tscn, maze_02.tscn, etc.)

### Run the Game

1. Open `main.tscn` in the editor
2. Press **F5** or click the Play button
3. Use **WASD** to move and **Mouse** to look around

## Maze Configuration

Default configuration (in `maze_config.gd`):
- Size: 40x40 tiles
- Tile size: 4x4 meters
- Wall height: 3 meters
- Wall thickness: 0.2 meters
- Entry: (0, 0)
- Exit: (39, 39)

## Testing

### Run Tests Locally

```bash
# Run all tests
godot --headless --path . --script scripts/test_all.gd

# Run individual tests
godot --headless --path . --script scripts/verify_maze_generation.gd
godot --headless --path . --script scripts/test_maze_generation.gd
```

### CI Pipeline

The GitHub Actions workflow (`.github/workflows/test.yml`) automatically runs all tests on push/PR.

## Controls

- **W/A/S/D**: Move forward/left/backward/right
- **Mouse**: Look around (first-person camera)
- **ESC**: Release mouse cursor

## Requirements

- Godot Engine v4.5.1 or later
- Windows/Linux/macOS

## License

[Add your license here]
