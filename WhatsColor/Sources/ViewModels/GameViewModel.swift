import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var state: GameStateModel
    @Published var showColorPicker: Bool = false

    // Dialog states
    @Published var showPauseDialog: Bool = false
    @Published var showSettingsDialog: Bool = false
    @Published var showSecretCodeDialog: Bool = false

    // Secret code selection state
    @Published var selectedSecretCode: [GameColor] = []
    @Published var currentSecretSlot: Int = 0

    // Timer state
    @Published var timeRemaining: Int = 60 // Default 60 seconds
    @Published var isTimerActive: Bool = false
    @Published var gameStarted: Bool = false  // Timer only runs after full setup flow
    private var timer: Timer?

    init() {
        self.state = GameStateModel.initial
        gameStarted = false  // Don't auto-start timer on first launch
        startNewGame()  // Initialize game board properly
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
        showSettingsDialog = true
    }

    func applySettingsAndRestart(timeLimit: Int) {
        showSettingsDialog = false
        timeRemaining = timeLimit
        gameStarted = true  // Mark game as started, timer will run after code selection
        startSecretCodeSelection()
    }

    func startNextLevel() {
        state.level += 1
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

    func moveToNextSlot() {
        if state.activeIndex < 3 {
            state.activeIndex += 1
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
            state.message = "FILL ALL SLOTS"
            return
        }

        // Check for unique colors
        let colors = state.currentGuess.compactMap { $0 }
        guard Set(colors).count == 4 else {
            state.message = "USE UNIQUE COLORS"
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
            state.message = "TRY AGAIN"
            return
        }

        let guess = lastAttempt.colors.compactMap { $0 }
        let feedback = lastAttempt.feedback

        // Check if all colors are correct
        if state.mode == .advanced {
            let correctCount = feedback.filter { $0 == .correct }.count
            if correctCount == 4 {
                state.isGameOver = true
                state.message = "UNLOCKED!"
                stopTimer()
                return
            }
        } else {
            // Beginner mode: check each position
            var allCorrect = true
            for i in 0..<4 {
                if feedback[i] != .correct {
                    allCorrect = false
                    break
                }
            }
            if allCorrect {
                state.isGameOver = true
                state.message = "UNLOCKED!"
                stopTimer()
                return
            }
        }

        // Check if out of attempts
        let completedAttempts = state.attempts.filter { $0.isComplete }.count
        if completedAttempts >= 7 {
            state.isGameOver = true
            state.message = "LOCKED! FAILED"
            stopTimer()
        } else {
            state.message = "TRY AGAIN"
        }
    }

    func changeMode(to mode: FeedbackMode) {
        state.mode = mode
        startNewGame()
    }

    func changeDifficulty(to difficulty: GameDifficulty) {
        state.difficulty = difficulty
        startNewGame()
    }

    // MARK: - Computed Properties

    var currentLevelString: String {
        String(format: "%03d", state.level)
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

    func cycleColor(at slotIndex: Int, direction: Int) {
        guard !state.isGameOver else { return }

        // Get current color index
        let currentColor = state.currentGuess[slotIndex]
        var currentIndex = currentColor?.rawValue ?? -1

        // Calculate next color index
        var nextIndex = currentIndex + direction
        if nextIndex < 0 {
            nextIndex = GameColor.allCases.count - 1
        } else if nextIndex >= GameColor.allCases.count {
            nextIndex = 0
        }

        // Set new color
        state.currentGuess[slotIndex] = GameColor(rawValue: nextIndex)
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
