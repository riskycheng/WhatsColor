# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WhatsColor is an iOS game app that implements a "Mastermind" style color-guessing puzzle game with a retro handheld device aesthetic. The app features multiple game modes, themes, and a sophisticated UI that simulates a physical gaming device.

## Development Commands

### Building and Running
```bash
# Generate Xcode project from project.yml
xcodegen

# Build the app (after opening in Xcode)
# Use Xcode UI or command line:
xcodebuild -project WhatsColor.xcodeproj -scheme WhatsColor -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Project Generation
The project uses XcodeGen for project file management. The `project.yml` file defines:
- Target configuration for iOS 15.0+
- Bundle identifier: `com.whatscolor.app`
- Asset and resource management
- Swift 5.9 configuration

## Architecture

### MVVM Pattern
The app follows a clear MVVM architecture:
- **Models**: `GameModels.swift` contains all data structures (`GameColor`, `GameStateModel`, `GameRowModel`, etc.)
- **ViewModels**: `GameViewModel.swift` is the central state manager handling game logic, timer, UI state
- **Views**: Multiple SwiftUI views in `Sources/Views/` for different UI components

### Key Components

#### GameViewModel (Central State Manager)
- Manages game state, timer, drag interactions
- Handles two game modes: Solo (advanced/deterministic) and Dual (beginner/custom)
- Coordinates between multiple dialog states and UI flows
- Implements sophisticated drag-and-drop logic with position tracking
- Manages theme switching and persistent level progression

#### Game Flow Architecture
1. **Start Screen** → **Settings Dialog** (Dual mode) → **Secret Code Selection** → **Game Play**
2. **Start Screen** → **Direct Game Play** (Solo mode with predetermined sequences)

#### Theme System
- Multiple visual themes with icon asset management
- Complex asset loading system that handles bundle path variations
- Icons organized in folders: `pixel_fruit`, `cute_cat`, `cute_dog`, `nice_fastfood`, `nice_fruit`, `nice_vegitables`
- Fallback mechanisms for missing assets

#### Drag & Drop System
- Sophisticated coordinate-based drag system with frame registration
- Supports dragging from color palette and between slots
- Visual feedback with drag overlays and target highlighting
- Intelligent auto-advance logic after color placement

### Data Models

#### Core Enums
- `GameColor`: 7 colors with hex values and UI representations
- `FeedbackMode`: Beginner (positional hints) vs Advanced (aggregate hints)
- `GameDifficulty`: Easy/Normal/Hard with different time limits
- `GameTheme`: Multiple visual themes with asset mappings

#### Game State
- `GameStateModel`: Central state container
- Persistent level progression per difficulty
- Fixed slot system for advanced gameplay strategies

## File Organization

```
WhatsColor/Sources/
├── App/
│   └── WhatsColorApp.swift          # App entry point
├── Models/
│   └── GameModels.swift             # All data structures and enums
├── ViewModels/
│   └── GameViewModel.swift          # Central state management
├── Views/
│   ├── ContentView.swift            # Main game container and device shell
│   ├── GameStartView.swift          # Start screen and mode selection
│   ├── GameBoardView.swift          # Game grid and feedback display
│   ├── HorizontalColorPickerView.swift # Color palette component
│   ├── StatusControlPanelView.swift # Bottom control panel
│   ├── TimeWheelPicker.swift        # Time selection wheel
│   └── SecretCodeSelectionView.swift # Secret code setup (Dual mode)
└── Extensions/
    ├── Extensions.swift             # Color and utility extensions
    ├── SoundManager.swift           # Audio and haptic feedback
    └── Animations.swift             # Custom animation utilities
```

## Key Development Patterns

### State Management
- Single source of truth in `GameViewModel`
- Published properties for SwiftUI reactivity
- Explicit state transitions with animation support
- Timer management with proper lifecycle handling

### UI Coordination
- Dialog overlay system with blur effects
- Complex gesture handling for drag operations
- Frame registration system for precise drop targeting
- Toast notification system with auto-dismissal

### Interactive Tutorial System
- **TutorialManager**: Singleton `@ObservableObject` managing 13 tutorial steps (`welcome` through `complete`)
- **Auto-launch**: First-time tutorial launches automatically from `GameViewModel.init()`
- **Mid-tutorial navigation**: Tutorial transitions from start screen to gameplay automatically at the `.objective` step
- **Spotlight overlay**: Uses `SpotlightShape` with even-odd fill rule to create dimmed-screen cutout holes around highlighted elements
- **Pointer hints**: For elements prone to frame-alignment issues (dial, top buttons), `BouncingPointer` (animated arrow + dot) replaces precise rectangle spotlights
- **Non-blocking overlay**: The tutorial overlay must remain interactive underneath; dimmed layers and pointer views use `.allowsHitTesting(false)`, and `FrameReader` tracker views set `isUserInteractionEnabled = false`
- **Frame tracking**: `FrameReader` (UIKit `UIViewRepresentable` using `convert(_:to: window)`) provides reliable window-coordinate frames, bypassing SwiftUI `.global` coordinate space quirks

### Game Logic
- Deterministic secret code generation for Solo mode
- Advanced feedback calculation (aggregate vs positional)
- Intelligent auto-advance cursor logic
- Fixed slot system for strategic gameplay

### Asset Management
- Theme-based icon loading with multiple fallback strategies
- Bundle path debugging and diagnostics
- Support for both folder references and flattened assets
- Pixel-perfect rendering for pixel art themes

## Testing and Debugging

The app includes extensive bundle diagnostics in `GameViewModel.init()` that logs asset loading issues. When working with themes or assets, check the console output for path resolution details.

## Prototype Reference

The `prototype/` folder contains a JavaScript/HTML version that served as the initial design reference. This helps understand the core game mechanics and UI layout concepts that were translated to the native iOS implementation.