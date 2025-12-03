# Maze Zombie - Procedural 3D Maze Generator

A procedural 3D maze generator built with Godot 4.5.1, featuring recursive backtracking algorithm, first-person player controls, and automated CI testing.

## 🎮 Features

- **Procedural Maze Generation**: 40x40 tile maze using recursive backtracking algorithm
- **3D Visualization**: Soft green floors and grey walls with proper lighting
- **First-Person Controls**: WASD movement + mouse look
- **Modular Design**: Data-driven configuration, easy to customize
- **CI/CD Pipeline**: Automated testing with GitHub Actions

## 🚀 Quick Start

### Prerequisites
- Godot 4.5.1-stable

### Generate Maze
1. Open project in Godot 4.5.1
2. Go to **Tools > Run Script**
3. Select `generate_maze_editor.gd`
4. Click **Run**
5. Open `maze.tscn` to see the generated maze

### Play the Game
1. Press **F5** or click Play button
2. Use **WASD** to move
3. Use **Mouse** to look around
4. Press **ESC** to release mouse cursor

## 📁 Project Structure

```
maze-zombie/
├── maze_generator.gd      # Main maze generator (@tool enabled)
├── maze_config.gd          # Configuration resource
├── maze_algorithm.gd       # Recursive backtracking algorithm
├── maze_builder.gd         # 3D geometry builder
├── player_controller.gd    # FPS controller
├── main.tscn               # Main game scene
├── maze.tscn               # Maze scene
├── player.tscn             # Player character
├── floor_tile.tscn         # Floor prefab
├── wall_tile.tscn          # Wall prefab
└── scripts/                # Test scripts
    ├── test_scene_validation.gd
    ├── test_maze_generation.gd
    ├── test_runtime.gd
    └── analyze_scenes.gd
```

## ⚙️ Configuration

Maze parameters can be configured via `MazeConfig` resource:
- **Dimensions**: 40x40 tiles (default)
- **Tile Size**: 4m x 4m
- **Wall Height**: 3m
- **Wall Thickness**: 0.2m
- **Colors**: Soft green floors, soft grey walls
- **Entry/Exit**: Corners (0,0) and (39,39)

## 🧪 Testing

### Automated CI Testing
The project includes a GitHub Actions workflow that automatically:
- Downloads Godot 4.5.1 headless
- Runs all test scripts
- Generates test reports
- Shows pass/fail status

**Check CI Results**: https://github.com/mertkaval/maze-zombie/actions

### Local Testing
Run tests locally using Godot console:
```bash
godot --headless --path . --script scripts/test_scene_validation.gd
godot --headless --path . test_runner.tscn
```

## 📝 Documentation

- `TESTING_GUIDE.md` - Complete testing instructions
- `COMPLETE_STATUS.md` - Full project status report
- `FINAL_TEST_REPORT.md` - Test results and analysis

## 🐛 Known Issues Fixed

- ✅ Placeholder resource validation errors
- ✅ Async/await handling in maze generation
- ✅ Division by zero in progress logging
- ✅ CI workflow file checking logic
- ✅ Variable naming errors in test scripts

## 📊 Project Status

**Status**: ✅ **100% Complete and Ready**

- ✅ All core features implemented
- ✅ All bugs fixed
- ✅ All test scripts ready
- ✅ CI pipeline configured
- ✅ Documentation complete

## 🔗 Links

- **GitHub Repository**: https://github.com/mertkaval/maze-zombie
- **CI Pipeline**: https://github.com/mertkaval/maze-zombie/actions

## 📄 License

This project is part of a learning exercise and is available for educational purposes.

---

**Built with**: Godot 4.5.1-stable  
**Last Updated**: 2024

