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
    
    func registerSlotFrame(_ frame: CGRect, row: Int, slot: Int) {
        let key = "\(row)-\(slot)"
        slotFrames[key] = frame
    }
    
    func updateDragPosition(_ position: CGPoint) {
        dragPosition = position
        
        let oldTargetRow = dropTargetRow
        let oldTargetIndex = dropTargetIndex
        var newTargetRow: Int? = nil
        var newTargetIndex: Int? = nil
        
        // Only consider frames for the current active row
        let activeRowNumber = getCurrentRowNumber()
        
        for (key, frame) in slotFrames {
            if frame.contains(position) {
                let parts = key.split(separator: "-")
                if parts.count == 2, 
                   let r = Int(parts[0]), 
                   let s = Int(parts[1]),
                   r == activeRowNumber { // Strict: only allow dropping on active row
                    newTargetRow = r
                    newTargetIndex = s
                    break
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
        if let targetIndex = dropTargetIndex, let color = activeDragColor {
            if let sourceIndex = sourceSlotIndex, let sourceRow = sourceSlotRow {
                // Swapping logic: must check if target row is the active row
                let activeRowNumber = getCurrentRowNumber()
                if sourceRow == activeRowNumber && dropTargetRow == activeRowNumber {
                    if sourceIndex != targetIndex {
                        let targetColor = state.currentGuess[targetIndex]
                        state.currentGuess[sourceIndex] = targetColor
                        state.currentGuess[targetIndex] = color
                        state.activeIndex = targetIndex
                    }
                }
            } else {
                // Palette drop
                setColor(color, at: targetIndex)
            }
            SoundManager.shared.playDrop()
            SoundManager.shared.hapticMedium()
        }
        activeDragColor = nil
        dragPosition = .zero
        dropTargetRow = nil
        dropTargetIndex = nil
        sourceSlotRow = nil
        sourceSlotIndex = nil
    }

    func setColor(_ color: GameColor, at index: Int) {
        guard !state.isGameOver else { return }
        state.currentGuess[index] = color
        state.activeIndex = index
    }

    // Secret code selection state
    @Published var selectedSecretCode: [GameColor] = []
    @Published var currentSecretSlot: Int = 0

    // Timer state
    @Published var timeRemaining: Int = 60 // Default 60 seconds
    @Published var isTimerActive: Bool = false
    @Published var gameStarted: Bool = false  // Timer only runs after full setup flow
    private var timer: Timer?

    private func getLevelKey(for difficulty: GameDifficulty) -> String {
        return "WhatsColor_Level_\(difficulty.rawValue)"
    }

    init() {
        self.state = GameStateModel.initial
        
        // Load difficulty-specific level
        let key = "WhatsColor_Level_\(self.state.difficulty.rawValue)"
        let savedLevel = UserDefaults.standard.integer(forKey: key)
        self.state.level = max(1, savedLevel)
        
        gameStarted = false
        isShowingStartScreen = true
        startNewGame()
    }
    
    private func saveProgress() {
        let key = getLevelKey(for: state.difficulty)
        UserDefaults.standard.set(state.level, forKey: key)
    }

    func showToast(_ message: String, type: ToastType = .info) {
        toast = ToastInfo(message: message, type: type)
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
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
        selectedSecretCode = []
        currentSecretSlot = 0
    }

    func selectSecretColor(_ color: GameColor) {
        guard currentSecretSlot < 4 else { return }
        selectedSecretCode.append(color)
        currentSecretSlot += 1
    }

    func resetSecretCode(from index: Int) {
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
        selectedSecretCode.count == 4
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
        var indices = Array(0..<7)
        var code: [GameColor] = []

        for _ in 0..<4 {
            let randomIndex = Int.random(in: 0..<indices.count)
            code.append(GameColor(rawValue: indices[randomIndex])!)
            indices.remove(at: randomIndex)
        }

        return code
    }

    func selectColor(_ color: GameColor) {
        guard !state.isGameOver else { return }

        state.currentGuess[state.activeIndex] = color
        // Do not auto-advance to next slot - stay on current slot
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
        
        selectColor(allColors[nextIndex])
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
            showToast("FILL ALL SLOTS", type: .warning)
            return
        }

        // Check for unique colors... (rest of function)
        let colors = state.currentGuess.compactMap { $0 }
        guard Set(colors).count == 4 else {
            showToast("USE UNIQUE COLORS", type: .warning)
            return
        }

        // Calculate feedback
        let guess = colors
        let feedback = calculateFeedback(guess: guess, secret: state.secretCode)

        // Add attempt to current row
        if let currentAttemptIndex = state.attempts.firstIndex(where: { !$0.isComplete && $0.colors.allSatisfy({ $0 == nil }) }) {
            state.attempts[currentAttemptIndex].colors = state.currentGuess
            state.attempts[currentAttemptIndex].feedback = feedback
        }

        // Reset currentGuess for next row (but don't auto-advance)
        state.currentGuess = Array(repeating: nil, count: 4)
        state.activeIndex = 0
        
        // Clear slot frames for the next row to re-register
        slotFrames.removeAll()

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

        let guess = lastAttempt.colors.compactMap { $0 }
        let feedback = lastAttempt.feedback

        let isWin: Bool
        if state.mode == .advanced {
            let correctCount = feedback.filter { $0 == .correct }.count
            isWin = (correctCount == 4)
        } else {
            isWin = feedback.allSatisfy { $0 == .correct }
        }

        if isWin {
            if gameMode == .solo {
                state.level += 1
                if state.level > 500 {
                    state.level = 1 // Loop or end game? User said 500 total.
                    state.isGameOver = true
                    state.message = "ALL MISSIONS COMPLETE"
                    showGameOverDialog = true
                    stopTimer()
                } else {
                    showToast("LEVEL \(state.level - 1) CLEAR", type: .success)
                    SoundManager.shared.playSuccess()
                    SoundManager.shared.hapticSuccess()
                    stopTimer() // Stop current level timer
                    
                    // Small delay before next level
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        // Reset time for the next mission
                        self.timeRemaining = self.state.difficulty.baseTime
                        self.startNewGame()
                    }
                }
            } else {
                state.isGameOver = true
                state.message = "UNLOCKED!"
                showGameOverDialog = true
                SoundManager.shared.playSuccess()
                SoundManager.shared.hapticSuccess()
                stopTimer()
            }
            return
        }

        // Check if out of attempts
        let completedAttempts = state.attempts.filter { $0.isComplete }.count
        if completedAttempts >= 7 {
            state.isGameOver = true
            state.message = "LOCKED! FAILED"
            showGameOverDialog = true
            SoundManager.shared.playError()
            stopTimer()
        } else {
            // Show toast for incorrect guess
            showToast("TRY AGAIN", type: .info)
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
        // Find the first incomplete row
        if let currentRow = state.attempts.first(where: { !$0.isComplete }) {
            return currentRow.rowNumber
        }
        // If all rows are complete, return the last row number
        return 7
    }

    func selectSlot(at index: Int) {
        guard !state.isGameOver else { return }
        state.activeIndex = index
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
