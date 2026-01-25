import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var state: GameStateModel
    @Published var showColorPicker: Bool = false

    init() {
        self.state = GameStateModel.initial
        startNewGame()
    }

    // MARK: - Game Logic

    func startNewGame() {
        state.secretCode = generateSecretCode()
        state.attempts = (1...7).map { GameRowModel(rowNumber: $0) }
        state.currentGuess = Array(repeating: nil, count: 4)
        state.activeIndex = 0
        state.isGameOver = false
        state.message = "READY"
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

        // Auto-advance to next slot
        if state.activeIndex < 3 {
            moveToNextSlot()
        }
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

        // Add attempt
        if let currentAttemptIndex = state.attempts.firstIndex(where: { !$0.isComplete && $0.colors.allSatisfy({ $0 == nil }) }) {
            state.attempts[currentAttemptIndex].colors = state.currentGuess
            state.attempts[currentAttemptIndex].feedback = feedback
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
                return
            }
        }

        // Check if out of attempts
        let completedAttempts = state.attempts.filter { $0.isComplete }.count
        if completedAttempts >= 7 {
            state.isGameOver = true
            state.message = "LOCKED! FAILED"
        } else {
            state.message = "TRY AGAIN"
        }
    }

    func changeMode(to mode: FeedbackMode) {
        state.mode = mode
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

    var hasError: Bool {
        state.message == "FILL ALL SLOTS" || state.message == "USE UNIQUE COLORS"
    }

    var errorMessage: String? {
        hasError ? state.message : nil
    }
}
