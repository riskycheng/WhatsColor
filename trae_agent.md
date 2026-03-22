# WhatsColor Project - Agent Knowledge Document

## Project Overview
WhatsColor is an iOS Mastermind-style code-breaking game with multiple themes (colors, dogs, cats, food, etc.) and game modes.

## Architecture

### Core Files Structure
```
WhatsColor/Sources/
├── Models/
│   └── GameModels.swift          # GameColor, GameTheme, GameState, GameDifficulty enums
├── Views/
│   ├── ContentView.swift         # Main container, HowToPlayView, DragOverlay
│   ├── GameStartView.swift       # Main menu, difficulty/mode selection
│   ├── GameBoardView.swift       # Game grid with drag-to-swap
│   ├── SecretCodeSelectionView.swift  # Dual mode code setup
│   ├── HorizontalColorPickerView.swift # Bottom item picker
│   └── StatusControlPanelView.swift    # Timer and rotary dial
├── ViewModels/
│   └── GameViewModel.swift       # Main game logic and state
├── Managers/
│   ├── GameStateManager.swift    # State persistence and management
│   └── SoundManager.swift        # Audio and haptic feedback
└── Utilities/
    └── Extensions.swift          # Color and view extensions
```

## Key Features Implemented

### 1. Difficulty System (GameDifficulty)
- **Easy**: 4 enabled colors only, position-based feedback
- **Normal**: 7 colors, position-based feedback
- **Hard**: 7 colors, aggregate feedback only (sorted: correct first, then misplaced)

```swift
enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"
    
    var enabledColorCount: Int {
        switch self {
        case .easy: return 4
        case .normal, .hard: return 7
        }
    }
}
```

### 2. Game Modes
- **Solo (Advanced)**: Player vs AI, progress through 500 levels
- **Dual (Beginner)**: Two players, one sets code, one guesses

### 3. Drag-to-Swap Implementation
Used in both GameBoardView and SecretCodeSelectionView:

```swift
// Key properties in GameViewModel
@Published var secretDragColor: GameColor?
@Published var secretDragPosition: CGPoint = .zero
@Published var secretDragSourceIndex: Int?
@Published var secretDropTargetIndex: Int?
@Published var secretSlotFrames: [Int: CGRect] = [:]

// Methods
func registerSecretSlotFrame(_ frame: CGRect, slot: Int)
func updateSecretDragPosition(_ position: CGPoint)
func endSecretDragging()
```

### 4. Theme System (GameTheme)
7 themes available:
- `.classic` - Colors (red, green, blue, yellow, purple, cyan, orange)
- `.pixelFruit` - Pixel art fruits
- `.cuteCat` - Cartoon cats
- `.cuteDog` - Cartoon dogs
- `.fastFood` - Fast food items
- `.fruit` - Realistic fruits
- `.vegetables` - Vegetables

### 5. Easy Mode Color Selection
In Easy mode, 4 random colors are selected from all 7:
```swift
@Published var enabledColorsForCurrentGame: [GameColor] = []
```
This ensures secret code and picker show the same 4 colors.

## Important Logic Patterns

### Secret Code Generation
```swift
func generateSecretCode() -> [GameColor] {
    // Uses enabledColorsForCurrentGame in Easy mode
    // Random selection from available colors
    // Ensures no duplicates
}
```

### Feedback Calculation
```swift
func calculateFeedback(guess: [GameColor], secret: [GameColor]) -> [FeedbackType] {
    // Easy/Normal: Position-based feedback
    // Hard: Aggregate feedback (sorted)
}
```

### Horizontal Picker Enabled Colors
```swift
private var enabledColors: [GameColor] {
    if !viewModel.enabledColorsForCurrentGame.isEmpty {
        return viewModel.enabledColorsForCurrentGame
    }
    // Fallback to default
}
```

## UI Components

### GameStartView Layout
- Title card with theme selector (swipeable)
- Theme preview strip (4 items)
- Difficulty selector (3 buttons)
- Mission type selector (SOLO/DUAL)
- Progress panel (Solo mode only, fixed height 76pt)
- Action buttons (RULES, ENGAGE MISSION)

### SecretCodeSelectionView
- 4 slots for secret code
- Horizontal color picker
- RANDOM button (generate random code)
- START button (confirm)
- Drag-to-swap between slots

### HowToPlayView
- MISSION BRIEFING header
- Objective description
- SOLO/DUAL mode explanation
- Feedback system (GREEN/WHITE/NONE)
- Difficulty descriptions
- Controls (DIAL/CELLS)
- Drag down to close

## Known Issues & Solutions

### 1. Layout Shift Prevention
Use fixed height containers with `minHeight` and `maxHeight`:
```swift
.frame(maxWidth: .infinity, minHeight: 76, maxHeight: 76)
```

### 2. Drag Gesture Conflicts
Remove Button wrapper when implementing drag:
```swift
// Use ZStack + gesture instead of Button
ZStack { ... }
    .gesture(DragGesture(...))
```

### 3. Frame Registration
Use GeometryReader to track slot positions:
```swift
.background(
    GeometryReader { geo in
        Color.clear
            .onAppear {
                viewModel.registerSlotFrame(geo.frame(in: .global), slot: index)
            }
    }
)
```

## Debug Features

### Secret Code Display (GameBoardView)
```swift
// Shows actual secret code for testing
Button("DEBUG: SHOW SECRET CODE") { ... }
```

## Sound & Haptic Feedback
```swift
SoundManager.shared.playSelection()  // Light tap
SoundManager.shared.playDragStart()  // Drag begin
SoundManager.shared.playDrop()       // Drag end/swap
SoundManager.shared.playSuccess()    // Success
SoundManager.shared.hapticLight()    // Light feedback
SoundManager.shared.hapticMedium()   // Medium feedback
```

## Future Tasks / Ideas

### Potential Improvements
1. Add animations for feedback circles
2. Implement hint system for stuck players
3. Add statistics tracking (win rate, avg attempts)
4. Theme unlock progression
5. Daily challenges
6. Leaderboards

### Code Cleanup
1. Remove debug code before release
2. Add `#if DEBUG` around debug features
3. Optimize drag performance
4. Add unit tests for game logic

## File Change History (This Session)

### Modified Files:
- `GameModels.swift` - Added GameDifficulty enum
- `GameStartView.swift` - Complete redesign with theme unlock indicators
- `ContentView.swift` - Added HowToPlayView, DragOverlay
- `GameBoardView.swift` - Added debug secret code display (wrapped in #if DEBUG), feedback dot animations
- `SecretCodeSelectionView.swift` - Drag-to-swap, random button
- `HorizontalColorPickerView.swift` - Even distribution, enabled colors
- `GameViewModel.swift` - Difficulty logic, drag state, random generation, statistics integration, theme unlock checks
- `GameStateManager.swift` - Secret code generation with difficulty
- `StatusControlPanelView.swift` - Timer display for difficulty, added Hint button

### New Files Added:
- `GameStatistics.swift` - Statistics models (GameStatistics, DifficultyStatistics, ModeStatistics, GameRecord)
- `StatisticsManager.swift` - Singleton for tracking game statistics
- `ThemeUnlockManager.swift` - Theme unlock progression system
- `HintManager.swift` - Hint system for stuck players
- `DailyChallengeManager.swift` - Daily challenge framework
- `StatisticsManagerTests.swift` - Unit tests for statistics system
- `ThemeUnlockManagerTests.swift` - Unit tests for theme unlock system

### Key Features Implemented:
1. **Code Cleanup**: Debug code wrapped in `#if DEBUG` conditionals
2. **Bug Fix**: Easy mode color consistency - `enabledColorsForCurrentGame` now resets properly in `startNewGame()`
3. **Statistics System**: Win rate, streaks, average attempts, best times, difficulty-specific stats
4. **Theme Unlock System**: Progressive unlock at levels 5, 10, 20, 35, 50 with visual indicators
5. **Hint System**: 3 daily hints with strategic suggestions
6. **Daily Challenge**: Framework for daily puzzles
7. **Animations**: Feedback dots with entry and glow animations
8. **Unit Tests**: Comprehensive tests for statistics and theme unlock systems

## Testing Checklist

### Easy Mode
- [ ] Only 4 items enabled in picker
- [ ] Secret code uses only those 4 items
- [ ] Position-based feedback works

### Normal Mode
- [ ] All 7 items enabled
- [ ] Position-based feedback works

### Hard Mode
- [ ] All 7 items enabled
- [ ] Aggregate feedback (sorted)

### Dual Mode
- [ ] Secret code selection works
- [ ] Drag-to-swap works
- [ ] Random generation works
- [ ] Enabled colors match in game

### General
- [ ] Sound effects play
- [ ] Haptic feedback works
- [ ] Theme switching works
- [ ] Level progression works (Solo)
