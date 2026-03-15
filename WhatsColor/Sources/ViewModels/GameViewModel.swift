import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var state: GameStateModel
    
    // Level keys are now difficulty-dependent

    // Dialog states
    @Published var showPauseDialog: Bool = false
    @Published var showSettingsDialog: Bool = false
    @Published var showSecretCodeDialog: Bool = false
    @Published var showGameOverDialog: Bool = false

    // Message/Toast state
    struct ToastInfo: Equatable {
        let message: String
        let type: ToastType
    }
    
    enum ToastType {
        case info, success, warning, error
    }
    
    @Published var toast: ToastInfo? = nil
    private var toastTimer: Timer?

    // Drag state
    @Published var activeDragColor: GameColor? = nil
    @Published var dragPosition: CGPoint = .zero
    @Published var dropTargetRow: Int? = nil      // Specify row
    @Published var dropTargetIndex: Int? = nil    // Specify slot within row
    @Published var sourceSlotRow: Int? = nil      // Specify source row
    @Published var sourceSlotIndex: Int? = nil
    
    // For smooth swapping animation
    @Published var draggedSlotOffset: CGSize = .zero
    @Published var slotOffsets: [Int: CGSize] = [:]
    
    // Game Flow State
    @Published var isShowingStartScreen: Bool = true
    
    // Frames for each slot: unique key "row-slot"
    @Published var slotFrames: [String: CGRect] = [:]
    @Published var boardFrame: CGRect = .zero
    @Published var isOverBoard: Bool = false
    
    func registerSlotFrame(_ frame: CGRect, row: Int, slot: Int) {
        let key = "\(row)-\(slot)"
        slotFrames[key] = frame
    }
    
    func registerBoardFrame(_ frame: CGRect) {
        boardFrame = frame
    }
    
    func updateDragPosition(_ position: CGPoint) {
        dragPosition = position
        
        // Check if we are over the game board region
        isOverBoard = boardFrame.contains(position)
        
        let oldTargetRow = dropTargetRow
        let oldTargetIndex = dropTargetIndex
        var newTargetRow: Int? = nil
        var newTargetIndex: Int? = nil
        
        let activeRowNumber = getCurrentRowNumber()
        
        // Improve search: look for any slot, then validate if it's in the active row
        for (key, frame) in slotFrames {
            if frame.contains(position) {
                let parts = key.split(separator: "-")
                if parts.count == 2, 
                   let r = Int(parts[0]), 
                   let s = Int(parts[1]) {
                    // Only allow dropping on the active row
                    if r == activeRowNumber {
                        newTargetRow = r
                        newTargetIndex = s
                        break
                    }
                }
            }
        }
        
        if oldTargetRow != newTargetRow || oldTargetIndex != newTargetIndex {
            dropTargetRow = newTargetRow
            dropTargetIndex = newTargetIndex
            if newTargetIndex != nil {
                SoundManager.shared.hapticLight()
            }
        }
    }
    
    func endDragging() {
        if let color = activeDragColor {
            if let targetIndex = dropTargetIndex {
                if let sourceIndex = sourceSlotIndex, let sourceRow = sourceSlotRow {
                    // Swapping logic: must check if target row is the active row
                    let activeRowNumber = getCurrentRowNumber()
                    if sourceRow == activeRowNumber && dropTargetRow == activeRowNumber {
                        if sourceIndex != targetIndex {
                            // Prevent swapping with fixed slots
                            guard !state.fixedSlots[sourceIndex] && !state.fixedSlots[targetIndex] else { return }
                            
                            let targetColor = state.currentGuess[targetIndex]
                            state.currentGuess[sourceIndex] = targetColor
                            state.currentGuess[targetIndex] = color
                            
                            // Apply same intelligent auto-advance after swap
                            if let nextEmptyRight = (targetIndex+1..<4).first(where: { state.currentGuess[$0] == nil }) {
                                state.activeIndex = nextEmptyRight
                            } else if let firstEmptyLeft = (0..<4).first(where: { state.currentGuess[$0] == nil }) {
                                state.activeIndex = firstEmptyLeft
                            }
                        }
                    }
                } else {
                    // Palette drop precisely on a slot
                    setColor(color, at: targetIndex)
                }
                SoundManager.shared.playDrop()
                SoundManager.shared.hapticMedium()
            } else if isOverBoard {
                // Drop anywhere on board -> Use currently active slot
                if sourceSlotIndex == nil { // Only palette drops can use generic board area
                    setColor(color, at: state.activeIndex)
                    SoundManager.shared.playDrop()
                    SoundManager.shared.hapticMedium()
                }
            }
        }
        
        activeDragColor = nil
        dragPosition = .zero
        dropTargetRow = nil
        dropTargetIndex = nil
        sourceSlotRow = nil
        sourceSlotIndex = nil
        isOverBoard = false
    }

    func setColor(_ color: GameColor, at index: Int, autoAdvance: Bool = true) {
        guard !state.isGameOver else { return }
        // Respect fixed slots
        guard !state.fixedSlots[index] else { return }
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            state.currentGuess[index] = color
            
            if autoAdvance {
                // Intelligence Auto-Advance Logic:
                // 1. Check for empty cells to the right
                if let nextEmptyRight = (index+1..<4).first(where: { state.currentGuess[$0] == nil }) {
                    state.activeIndex = nextEmptyRight
                } 
                // 2. If no empty right, check for empty cells to the left
                else if let firstEmptyLeft = (0..<4).first(where: { state.currentGuess[$0] == nil }) {
                    state.activeIndex = firstEmptyLeft
                }
                // 3. If no empty cells left at all, stay at current index or cycle (user preferred to stay/move to next if space)
            }
        }
    }

    // Secret code selection state
    @Published var selectedSecretCode: [GameColor] = []
    @Published var currentSecretSlot: Int = 0
    @Published var showDuplicateWarning: Bool = false
    private var duplicateWarningTimer: Timer?

    // Timer state
    @Published var timeRemaining: Int = 60 // Default 60 seconds
    @Published var isTimerActive: Bool = false
    @Published var gameStarted: Bool = false  // Timer only runs after full setup flow
    private var timer: Timer?

    private func getLevelKey(for difficulty: GameDifficulty) -> String {
        return "WhatsColor_Level_\(difficulty.rawValue)"
    }

    private let themeKey = "WhatsColor_Theme"

    init() {
        print("🛠️ System: Initializing Handheld Console...")
        self.state = GameStateModel.initial
        
        // --- BUNDLE DIAGNOSTICS ---
        let fm = FileManager.default
        let bundlePath = Bundle.main.bundlePath
        print("📁 Bundle Path: \(bundlePath)")
        
        if let items = try? fm.contentsOfDirectory(atPath: bundlePath) {
            print("📦 Bundle Root contains \(items.count) items")
            if items.contains("icon_materials") {
                print("✅ Found 'icon_materials' folder in bundle")
                let themePath = bundlePath + "/icon_materials"
                if let themes = try? fm.contentsOfDirectory(atPath: themePath) {
                    print("📁 Themes found: \(themes.joined(separator: ", "))")
                }
            } else {
                print("❌ 'icon_materials' NOT found in bundle root")
                // Check if flattened
                let hasIcons = items.contains { $0.contains("icon_") || $0.contains("boluo") }
                if hasIcons {
                    print("ℹ️ Icons appear to be FLATTENED in the bundle root")
                }
            }
        }
        // ---------------------------

        // Load difficulty-specific level
        let key = getLevelKey(for: self.state.difficulty)
        let savedLevel = UserDefaults.standard.integer(forKey: key)
        self.state.level = max(1, savedLevel)
        
        // Load theme or use a rich default (Pixel Fruit for industrial look)
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = GameTheme(rawValue: savedTheme) {
            print("🎨 Theme: Loaded '\(theme.rawValue)' from storage")
            self.state.theme = theme
        } else {
            print("🎨 Theme: No saved preference, defaulting to PIXEL FRUIT")
            self.state.theme = .pixelFruit
        }
        
        gameStarted = false
        isShowingStartScreen = true
        startNewGame()
    }
    
    private func saveProgress() {
        let key = getLevelKey(for: state.difficulty)
        UserDefaults.standard.set(state.level, forKey: key)
    }

    func saveTheme() {
        UserDefaults.standard.set(state.theme.rawValue, forKey: themeKey)
        // Explicitly notify observers to ensure UI refreshes icons immediately
        objectWillChange.send()
        print("💾 System: Theme saved and UI refreshed (\(state.theme.rawValue))")
    }

    func showToast(_ message: String, type: ToastType = .info) {
        toast = ToastInfo(message: message, type: type)
        toastTimer?.invalidate()
        // Longer duration for warning/error messages
        let duration = (type == .warning || type == .error) ? 3.5 : 2.2
        toastTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            withAnimation {
                self?.toast = nil
            }
        }
    }

    // MARK: - Timer Management

    func startTimer() {
        stopTimer()
        isTimerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickTimer()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerActive = false
    }

    func tickTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Timer expired - end game
            stopTimer()
            state.isGameOver = true
            state.message = "TIME'S UP!"
            showGameOverDialog = true
        }
    }

    func setTimeLimit(seconds: Int) {
        timeRemaining = seconds
    }

    var timerDisplay: String {
        String(format: "%03d", timeRemaining)
    }

    // MARK: - Secret Code Selection

    func startSecretCodeSelection() {
        showSettingsDialog = false
        showSecretCodeDialog = true
        selectedSecretCode = Array(repeating: .red, count: 4) // Default or empty placeholders
        // Use nil-based representation for logic clarity if possible, but the current UI uses indices.
        // Let's stick to a 4-element array with a clear 'waiting' state.
        // Better: Initialize as empty and handle indices 0-3 separately.
        selectedSecretCode = [] 
        currentSecretSlot = 0
    }

    func selectSecretColor(_ color: GameColor) {
        // Check for duplicates before adding/changing
        if selectedSecretCode.contains(color) {
            // Find which slot has this color
            if let duplicateIndex = selectedSecretCode.firstIndex(of: color) {
                // If clicking the same slot that's already selected, do nothing
                if duplicateIndex == currentSecretSlot {
                    return
                }
                // Show warning that this color is already used
                showDuplicateWarning = true
                showToast("ALREADY USED IN SLOT \(duplicateIndex + 1)", type: .warning)
                SoundManager.shared.playError()
                SoundManager.shared.hapticError()
                
                // Clear the warning after 2 seconds
                duplicateWarningTimer?.invalidate()
                duplicateWarningTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    withAnimation {
                        self?.showDuplicateWarning = false
                    }
                }
                return
            }
        }
        
        // Clear duplicate warning when a valid selection is made
        showDuplicateWarning = false
        duplicateWarningTimer?.invalidate()
        
        if selectedSecretCode.count < 4 {
            selectedSecretCode.append(color)
            // Auto-advance currentSecretSlot only if we are filling sequentially
            currentSecretSlot = selectedSecretCode.count
        } else if currentSecretSlot < 4 {
            // Replace specific slot
            selectedSecretCode[currentSecretSlot] = color
            // Do NOT auto-advance - keep current slot selected for adjustability
        }
    }

    func resetSecretCode(at index: Int) {
        guard index < selectedSecretCode.count else { return }
        // Instead of removing subrange, we just set the focus there or allow individual removal
        // If the user clicks a slot, they likely want to change it.
        currentSecretSlot = index
    }

    func swapSecretColors(from: Int, to: Int) {
        guard from < selectedSecretCode.count, to < selectedSecretCode.count else { return }
        selectedSecretCode.swapAt(from, to)
        currentSecretSlot = to // Focus follows the item or stays at target
    }

    func resetSecretCode(from index: Int) {
        // Keep this for compatibility if needed, but we'll use resetSecretCode(at:) for specific selection
        guard index < selectedSecretCode.count else { return }
        selectedSecretCode.removeSubrange(index..<selectedSecretCode.count)
        currentSecretSlot = selectedSecretCode.count
    }

    func finishSecretCodeSelection() {
        guard selectedSecretCode.count == 4 else { return }
        showSecretCodeDialog = false
        state.secretCode = selectedSecretCode
        gameStarted = true  // Mark game as started, timer will now run
        startNewGame()
    }

    func cancelSecretCodeSelection() {
        showSecretCodeDialog = false
        showSettingsDialog = true
        selectedSecretCode = []
        currentSecretSlot = 0
    }

    func dismissSecretCodeSelection() {
        // Dismiss without going back to settings - just cancel and reset timer
        showSecretCodeDialog = false
        selectedSecretCode = []
        currentSecretSlot = 0
        // Restart game with current time settings
        gameStarted = true  // Mark game as started
        startNewGame()
    }

    func dismissSettingsDialog() {
        // Dismiss settings and go back to paused state
        showSettingsDialog = false
        showPauseDialog = true
    }

    var isSecretCodeComplete: Bool {
        selectedSecretCode.count == 4 && !hasDuplicateInSecretCode
    }
    
    var hasDuplicateInSecretCode: Bool {
        Set(selectedSecretCode).count != selectedSecretCode.count
    }

    // MARK: - Game Logic

    func startNewGame() {
        // Use selected secret code if available, otherwise generate random
        if selectedSecretCode.count == 4 {
            state.secretCode = selectedSecretCode
        } else {
            state.secretCode = generateSecretCode()
        }
        // Always create 7 rows regardless of difficulty
        state.attempts = (1...7).map { GameRowModel(rowNumber: $0) }
        state.currentGuess = Array(repeating: nil, count: 4)
        state.fixedSlots = Array(repeating: false, count: 4)
        state.activeIndex = 0
        state.isGameOver = false
        state.message = "READY"
        // Start timer only if game has been started through the full setup flow
        if gameStarted && timeRemaining > 0 {
            startTimer()
        }
    }

    func pauseGame() {
        stopTimer()
        showPauseDialog = true
    }

    func resumeGame() {
        showPauseDialog = false
        if timeRemaining > 0 {
            startTimer()
        }
    }

    func confirmRestart() {
        showPauseDialog = false
        isShowingStartScreen = true
        gameStarted = false
        
        // Reset level to 1 only if we are in beginner/dual mode, otherwise keep level progress
        if gameMode == .dual {
            state.level = 1
        }
        
        timeRemaining = 120
        selectedSecretCode = [] 
        currentSecretSlot = 0
    }

    func startGame() {
        if gameMode == .dual {
            // DUAL mode: full pipeline (Time -> Color -> Play)
            showSettingsDialog = true
            isShowingStartScreen = false
            gameStarted = true
        } else {
            // SOLO mode: Skip dialogs, use predefined mission parameters
            isShowingStartScreen = false
            gameStarted = true
            timeRemaining = state.difficulty.baseTime
            selectedSecretCode = [] // Ensure a random code is generated
            startNewGame()
        }
    }

    func applySettingsAndRestart(timeLimit: Int) {
        showSettingsDialog = false
        timeRemaining = timeLimit
        // This is only called in DUAL mode now, so proceed to secret code setup
        startSecretCodeSelection()
    }

    func startNextLevel() {
        state.level += 1
        saveProgress()
        startNewGame()
    }

    func generateSecretCode() -> [GameColor] {
        // Deterministic generation for SOLO mode ensures "RETRY" keeps the same sequence
        if gameMode == .solo {
            if state.level == 1 {
                return [.red, .green, .orange, .blue]
            } else if state.level == 2 {
                return [.blue, .orange, .green, .red]
            }
            
            // Seeded selection for all other solo levels
            var indices = Array(0..<7)
            var code: [GameColor] = []
            for i in 0..<4 {
                // Simplified hash to select deterministic colors for each level
                let seed = (state.level * 197) + (i * 13) + (state.level / 3)
                let index = seed % indices.count
                code.append(GameColor(rawValue: indices[index])!)
                indices.remove(at: index)
            }
            return code
        }
        
        var indices = Array(0..<7)
        var code: [GameColor] = []

        for _ in 0..<4 {
            let randomIndex = Int.random(in: 0..<indices.count)
            code.append(GameColor(rawValue: indices[randomIndex])!)
            indices.remove(at: randomIndex)
        }

        return code
    }

    func selectColor(_ color: GameColor, autoAdvance: Bool = true) {
        guard !state.isGameOver else { return }
        setColor(color, at: state.activeIndex, autoAdvance: autoAdvance)
    }

    func cycleColor(forward: Bool = true) {
        guard !state.isGameOver else { return }
        
        let currentColor = state.currentGuess[state.activeIndex]
        let allColors = GameColor.allCases
        
        let currentIndex = allColors.firstIndex(where: { $0 == currentColor }) ?? 0
        let nextIndex: Int
        
        if forward {
            nextIndex = (currentIndex + 1) % allColors.count
        } else {
            nextIndex = (currentIndex - 1 + allColors.count) % allColors.count
        }
        
        selectColor(allColors[nextIndex], autoAdvance: false)
    }

    func moveToNextSlot() {
        if state.activeIndex < 3 {
            state.activeIndex += 1
        } else {
            state.activeIndex = 0
        }
    }

    func moveToPreviousSlot() {
        if state.activeIndex > 0 {
            state.activeIndex -= 1
        }
    }

    func submitGuess() {
        guard !state.isGameOver else { return }

        // Check if all slots are filled
        guard state.currentGuess.allSatisfy({ $0 != nil }) else {
            SoundManager.shared.playError()
            SoundManager.shared.hapticError()
            showToast("FILL ALL SLOTS", type: .warning)
            return
        }

        // Check for unique colors... (rest of function)
        let colors = state.currentGuess.compactMap { $0 }
        guard Set(colors).count == 4 else {
            SoundManager.shared.playError()
            SoundManager.shared.hapticError()
            showToast("USE UNIQUE COLORS", type: .warning)
            return
        }

        // Calculate feedback
        let guess = colors
        let feedback = calculateFeedback(guess: guess, secret: state.secretCode)

        // Find the specific row we are currently editing
        let activeRowNumber = getCurrentRowNumber()
        if let currentAttemptIndex = state.attempts.firstIndex(where: { $0.rowNumber == activeRowNumber }) {
            // LOCK IN the colors and feedback for this row
            state.attempts[currentAttemptIndex].colors = state.currentGuess
            state.attempts[currentAttemptIndex].feedback = feedback
        }

        // Reset currentGuess for next row (preserve fixed slots)
        let nextGuess: [GameColor?] = (0..<4).map { i in
            state.fixedSlots[i] ? state.currentGuess[i] : nil
        }
        state.currentGuess = nextGuess
        
        // Find next appropriate activeIndex
        if let firstEmpty = nextGuess.firstIndex(where: { $0 == nil }) {
            state.activeIndex = firstEmpty
        } else {
            state.activeIndex = 0
        }
        
        // Check win/lose condition
        checkGameStatus()
    }

    func calculateFeedback(guess: [GameColor], secret: [GameColor]) -> [FeedbackType] {
        if state.mode == .beginner {
            // Beginner mode: feedback for each position
            return guess.enumerated().map { index, color in
                if color == secret[index] {
                    return .correct
                } else if secret.contains(color) {
                    return .misplaced
                } else {
                    return .wrong
                }
            }
        } else {
            // Advanced mode: aggregate feedback
            var correct = 0
            var misplaced = 0
            var secretCopy = secret
            var guessCopy = guess

            // First pass: find correct positions
            for i in 0..<4 {
                if guessCopy[i] == secretCopy[i] {
                    correct += 1
                    secretCopy[i] = GameColor.cyan // Mark as used
                    guessCopy[i] = GameColor.cyan
                }
            }

            // Second pass: find misplaced colors
            for i in 0..<4 {
                if guessCopy[i] != GameColor.cyan {
                    if let foundIndex = secretCopy.firstIndex(of: guessCopy[i]) {
                        misplaced += 1
                        secretCopy[foundIndex] = GameColor.cyan
                    }
                }
            }

            // Build feedback array
            var feedback: [FeedbackType] = []
            for _ in 0..<correct {
                feedback.append(.correct)
            }
            for _ in 0..<misplaced {
                feedback.append(.misplaced)
            }
            while feedback.count < 4 {
                feedback.append(.wrong)
            }

            return feedback
        }
    }

    func checkGameStatus() {
        guard let lastAttempt = state.attempts.last(where: { $0.isComplete }) else {
            return
        }

        let feedback = lastAttempt.feedback

        let isWin: Bool
        if state.mode == .advanced {
            let correctCount = feedback.filter { $0 == .correct }.count
            isWin = (correctCount == 4)
        } else {
            isWin = feedback.allSatisfy { $0 == .correct }
        }

        if isWin {
            state.isGameOver = true
            state.message = "MISSION SUCCESS"
            
            if gameMode == .solo {
                // Update progress internally but don't start new game immediately
                let clearedLevel = state.level
                state.level += 1
                saveProgress()
            }
            
            SoundManager.shared.playSuccess()
            SoundManager.shared.hapticSuccess()
            stopTimer()
            showGameOverDialog = true
            return
        }

        // Check if out of attempts
        let completedAttempts = state.attempts.filter { $0.isComplete }.count
        if completedAttempts >= 7 {
            state.isGameOver = true
            state.message = "MISSION FAILED"
            showGameOverDialog = true
            SoundManager.shared.playError()
            stopTimer()
        } else {
            // Show toast for incorrect guess
            showToast("TRY AGAIN", type: .info)
            SoundManager.shared.playIncorrect()
            SoundManager.shared.hapticMedium()
        }
    }

    func changeMode(to mode: FeedbackMode) {
        state.mode = mode
        startNewGame()
    }

    func changeDifficulty(to difficulty: GameDifficulty) {
        state.difficulty = difficulty
        // Update predefined time for the selected difficulty
        timeRemaining = difficulty.baseTime
        
        // Load difficulty-specific level
        let key = getLevelKey(for: difficulty)
        let savedLevel = UserDefaults.standard.integer(forKey: key)
        state.level = max(1, savedLevel)
        
        startNewGame()
    }

    func changeTheme(to theme: GameTheme) {
        state.theme = theme
        saveTheme()
        SoundManager.shared.playSelection()
        SoundManager.shared.hapticLight()
    }

    // MARK: - Computed Properties

    enum GameMode {
        case solo
        case dual
    }

    var gameMode: GameMode {
        state.mode == .advanced ? .solo : .dual
    }

    var currentLevelString: String {
        String(format: "%03d", state.level)
    }

    var currentRank: String {
        let lv = state.level
        if lv <= 5 { return "RECRUIT" }
        if lv <= 20 { return "SPECIALIST" }
        if lv <= 50 { return "OPERATIVE" }
        if lv <= 100 { return "COMMANDER" }
        if lv <= 300 { return "ELITE" }
        return "LEGENDARY"
    }

    var activeColors: [GameColor] {
        GameColor.allCases
    }

    var isCurrentGuessComplete: Bool {
        state.currentGuess.allSatisfy { $0 != nil }
    }

    var isCurrentRowActive: Bool {
        !state.isGameOver
    }

    func getCurrentRowNumber() -> Int {
        // Find the first row that hasn't been "locked in" with feedback
        if let currentRow = state.attempts.first(where: { $0.feedback.allSatisfy { $0 == .empty } }) {
            return currentRow.rowNumber
        }
        return 7
    }

    func selectSlot(at index: Int) {
        guard !state.isGameOver else { return }
        state.activeIndex = index
    }

    func toggleFixed(at index: Int) {
        guard !state.isGameOver else { return }
        // Prevent locking empty cells
        guard state.currentGuess[index] != nil else { return }
        
        SoundManager.shared.playSelection()
        SoundManager.shared.hapticMedium()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            state.fixedSlots[index].toggle()
        }
    }

    var hasError: Bool {
        state.message == "FILL ALL SLOTS" || state.message == "USE UNIQUE COLORS"
    }

    var errorMessage: String? {
        hasError ? state.message : nil
    }

    deinit {
        stopTimer()
    }
}
