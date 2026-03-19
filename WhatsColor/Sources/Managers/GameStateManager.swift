import Foundation
import SwiftUI
import Combine

/// Manages core game state and logic
@MainActor
class GameStateManager: ObservableObject {
    @Published var state: GameStateModel

    // Fixed slots and current guess state
    @Published var currentGuess: [GameColor?] = Array(repeating: nil, count: 4)
    @Published var fixedSlots: [Bool] = Array(repeating: false, count: 4)
    @Published var activeIndex: Int = 0

    // Game completion state
    @Published var isGameOver: Bool = false
    @Published var message: String = "READY"

    // Level persistence
    private let userDefaults = UserDefaults.standard

    // Callbacks for external coordination
    var onGameWon: ((Int) -> Void)?  // Pass current level
    var onGameLost: (() -> Void)?
    var onToastMessage: ((String, ToastType) -> Void)?

    enum ToastType {
        case info, success, warning, error
    }

    init() {
        self.state = GameStateModel.initial
        loadProgress()
    }

    // MARK: - Level Management

    private func getLevelKey(for difficulty: GameDifficulty) -> String {
        return "WhatsColor_Level_\(difficulty.rawValue)"
    }

    private func loadProgress() {
        let key = getLevelKey(for: state.difficulty)
        let savedLevel = userDefaults.integer(forKey: key)
        state.level = max(1, savedLevel)
    }

    private func saveProgress() {
        let key = getLevelKey(for: state.difficulty)
        userDefaults.set(state.level, forKey: key)
    }

    // MARK: - Game Flow Management

    func startNewGame() {
        // Reset game state
        state.attempts = (1...7).map { GameRowModel(rowNumber: $0) }
        currentGuess = Array(repeating: nil, count: 4)
        fixedSlots = Array(repeating: false, count: 4)
        activeIndex = 0
        isGameOver = false
        message = "READY"

        // Generate or use existing secret code
        if state.secretCode.isEmpty {
            state.secretCode = generateSecretCode()
        }
    }

    func changeMode(to mode: FeedbackMode) {
        state.mode = mode
        startNewGame()
    }

    func changeDifficulty(to difficulty: GameDifficulty) {
        state.difficulty = difficulty
        loadProgress() // Load level for new difficulty
        startNewGame()
    }

    func setSecretCode(_ code: [GameColor]) {
        state.secretCode = code
    }

    func startNextLevel() {
        state.level += 1
        saveProgress()
        startNewGame()
    }

    // MARK: - Secret Code Generation

    func generateSecretCode() -> [GameColor] {
        // Get the number of enabled colors based on difficulty
        let enabledCount = state.difficulty.enabledColorCount
        
        // Deterministic generation for SOLO mode ensures "RETRY" keeps the same sequence
        if state.mode == .advanced { // Solo mode
            if state.level == 1 {
                // Use only enabled colors (first 4 for easy mode)
                let enabledColors = Array(GameColor.allCases.prefix(enabledCount))
                return Array(enabledColors.prefix(4))
            } else if state.level == 2 {
                let enabledColors = Array(GameColor.allCases.prefix(enabledCount))
                return [enabledColors[1], enabledColors[2], enabledColors[0], enabledColors[3]]
            }

            // Seeded selection for all other solo levels - only from enabled colors
            var indices = Array(0..<enabledCount)
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

        // Random generation for dual/beginner mode - only from enabled colors
        var indices = Array(0..<enabledCount)
        var code: [GameColor] = []

        for _ in 0..<4 {
            let randomIndex = Int.random(in: 0..<indices.count)
            code.append(GameColor(rawValue: indices[randomIndex])!)
            indices.remove(at: randomIndex)
        }

        return code
    }

    // MARK: - Color Placement Logic

    func setColor(_ color: GameColor, at index: Int, autoAdvance: Bool = true) {
        guard !isGameOver else { return }
        guard !fixedSlots[index] else { return }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            currentGuess[index] = color

            if autoAdvance {
                // Intelligent Auto-Advance Logic:
                // 1. Check for empty cells to the right
                if let nextEmptyRight = (index+1..<4).first(where: { currentGuess[$0] == nil }) {
                    activeIndex = nextEmptyRight
                }
                // 2. If no empty right, check for empty cells to the left
                else if let firstEmptyLeft = (0..<4).first(where: { currentGuess[$0] == nil }) {
                    activeIndex = firstEmptyLeft
                }
                // 3. If all filled, stay at current position
            }
        }
    }

    func selectColor(_ color: GameColor, autoAdvance: Bool = true) {
        guard !isGameOver else { return }
        setColor(color, at: activeIndex, autoAdvance: autoAdvance)
    }

    func cycleColor(forward: Bool = true) {
        guard !isGameOver else { return }

        let currentColor = currentGuess[activeIndex]
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

    // MARK: - Slot Management

    func selectSlot(at index: Int) {
        guard !isGameOver else { return }
        activeIndex = index
    }

    func moveToNextSlot() {
        if activeIndex < 3 {
            activeIndex += 1
        } else {
            activeIndex = 0
        }
    }

    func moveToPreviousSlot() {
        if activeIndex > 0 {
            activeIndex -= 1
        }
    }

    func toggleFixed(at index: Int) {
        guard !isGameOver else { return }
        guard currentGuess[index] != nil else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            fixedSlots[index].toggle()
        }
    }

    // MARK: - Guess Submission

    func submitGuess() -> Bool {
        guard !isGameOver else { return false }

        // Validate guess
        guard currentGuess.allSatisfy({ $0 != nil }) else {
            onToastMessage?("FILL ALL SLOTS", .warning)
            return false
        }

        let colors = currentGuess.compactMap { $0 }
        guard Set(colors).count == 4 else {
            onToastMessage?("USE UNIQUE COLORS", .warning)
            return false
        }

        // Calculate feedback
        let feedback = calculateFeedback(guess: colors, secret: state.secretCode)

        // Update the current row
        let activeRowNumber = getCurrentRowNumber()
        if let currentAttemptIndex = state.attempts.firstIndex(where: { $0.rowNumber == activeRowNumber }) {
            state.attempts[currentAttemptIndex].colors = currentGuess
            state.attempts[currentAttemptIndex].feedback = feedback
        }

        // Check win/lose condition
        let gameEnded = checkGameStatus()
        if gameEnded {
            return true
        }

        // Prepare for next row (preserve fixed slots)
        let nextGuess: [GameColor?] = (0..<4).map { i in
            fixedSlots[i] ? currentGuess[i] : nil
        }
        currentGuess = nextGuess

        // Find next appropriate activeIndex
        if let firstEmpty = nextGuess.firstIndex(where: { $0 == nil }) {
            activeIndex = firstEmpty
        } else {
            activeIndex = 0
        }

        return true
    }

    // MARK: - Feedback Calculation

    func calculateFeedback(guess: [GameColor], secret: [GameColor]) -> [FeedbackType] {
        // Calculate position-by-position feedback first
        let positionFeedback: [FeedbackType] = guess.enumerated().map { index, color in
            if color == secret[index] {
                return .correct
            } else if secret.contains(color) {
                return .misplaced
            } else {
                return .wrong
            }
        }
        
        // For Hard mode: aggregate feedback (no position information)
        if state.difficulty == .hard {
            let correctCount = positionFeedback.filter { $0 == .correct }.count
            let misplacedCount = positionFeedback.filter { $0 == .misplaced }.count
            
            // Build aggregate feedback array: all correct first, then misplaced, then empty
            var feedback: [FeedbackType] = []
            for _ in 0..<correctCount {
                feedback.append(.correct)
            }
            for _ in 0..<misplacedCount {
                feedback.append(.misplaced)
            }
            while feedback.count < 4 {
                feedback.append(.wrong)
            }
            return feedback
        }
        
        // For Easy and Normal modes: return position-based feedback
        return positionFeedback
    }

    // MARK: - Game Status Checking

    private func checkGameStatus() -> Bool {
        guard let lastAttempt = state.attempts.last(where: { $0.isComplete }) else {
            return false
        }

        let feedback = lastAttempt.feedback

        // For Hard mode, check if we have 4 correct (regardless of position in feedback array)
        // For Easy/Normal, all feedback must be correct
        let correctCount = feedback.filter { $0 == .correct }.count
        let isWin = (correctCount == 4)

        if isWin {
            isGameOver = true
            message = "MISSION SUCCESS"

            // Solo mode: advance level
            if gameMode == .solo {
                state.level += 1
                saveProgress()
            }

            onGameWon?(state.level - 1) // Pass the level that was just won
            return true
        }

        // Check if out of attempts
        let completedAttempts = state.attempts.filter { $0.isComplete }.count
        if completedAttempts >= 7 {
            isGameOver = true
            message = "MISSION FAILED"
            onGameLost?()
            return true
        } else {
            // Continue game
            onToastMessage?("TRY AGAIN", .info)
        }

        return false
    }

    // MARK: - Computed Properties

    func getCurrentRowNumber() -> Int {
        // Find the first row that hasn't been "locked in" with feedback
        if let currentRow = state.attempts.first(where: { $0.feedback.allSatisfy { $0 == .empty } }) {
            return currentRow.rowNumber
        }
        return 7
    }

    var isCurrentGuessComplete: Bool {
        currentGuess.allSatisfy { $0 != nil }
    }

    var isCurrentRowActive: Bool {
        !isGameOver
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

    var gameMode: GameMode {
        state.mode == .advanced ? .solo : .dual
    }

    enum GameMode {
        case solo
        case dual
    }

    // MARK: - Cleanup

    func cleanup() {
        onGameWon = nil
        onGameLost = nil
        onToastMessage = nil
    }

    deinit {
        // Clean up callbacks directly to avoid async calls from deinit
        onGameWon = nil
        onGameLost = nil
        onToastMessage = nil
    }
}