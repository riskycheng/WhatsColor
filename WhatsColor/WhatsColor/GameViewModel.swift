import SwiftUI
import Combine
import Foundation

enum GameMode {
    case beginner
    case advanced
}

enum FeedbackType {
    case correct      // Correct color, correct position
    case misplaced    // Correct color, wrong position
    case none         // Wrong color
}

struct GameColor: Identifiable, Equatable {
    let id: Int
    let name: String
    let color: Color
    let hex: String
}

struct Attempt: Identifiable {
    let id = UUID()
    let guess: [GameColor?]
    let feedback: [FeedbackType]
}

class GameViewModel: ObservableObject {
    @Published var secretCode: [GameColor] = []
    @Published var attempts: [Attempt] = []
    @Published var currentGuess: [GameColor?] = [nil, nil, nil, nil]
    @Published var selectedSlotIndex: Int = 0
    @Published var gameMode: GameMode = .advanced
    @Published var isGameOver: Bool = false
    @Published var statusMessage: String = "READY"
    @Published var level: Int = 1
    
    let allColors: [GameColor] = [
        GameColor(id: 0, name: "Red", color: Color(hex: "ff3b30"), hex: "#ff3b30"),
        GameColor(id: 1, name: "Green", color: Color(hex: "4cd964"), hex: "#4cd964"),
        GameColor(id: 2, name: "Orange", color: Color(hex: "ff9500"), hex: "#ff9500"),
        GameColor(id: 3, name: "Blue", color: Color(hex: "007aff"), hex: "#007aff"),
        GameColor(id: 4, name: "Yellow", color: Color(hex: "ffcc00"), hex: "#ffcc00"),
        GameColor(id: 5, name: "Purple", color: Color(hex: "af52de"), hex: "#af52de"),
        GameColor(id: 6, name: "Cyan", color: Color(hex: "5ac8fa"), hex: "#5ac8fa")
    ]
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        secretCode = generateSecret()
        attempts = []
        currentGuess = [nil, nil, nil, nil]
        selectedSlotIndex = 0
        isGameOver = false
        statusMessage = "READY"
    }
    
    private func generateSecret() -> [GameColor] {
        var shuffled = allColors.shuffled()
        return Array(shuffled.prefix(4))
    }
    
    func selectColor(_ color: GameColor) {
        guard !isGameOver else { return }
        currentGuess[selectedSlotIndex] = color
        selectedSlotIndex = (selectedSlotIndex + 1) % 4
    }
    
    func submitGuess() {
        guard !isGameOver else { return }
        
        if currentGuess.contains(where: { $0 == nil }) {
            statusMessage = "FILL ALL SLOTS"
            return
        }
        
        let guess = currentGuess.compactMap { $0 }
        
        // Check for unique colors if the game rules require it (prototype script says so)
        if Set(guess.map { $0.id }).count < 4 {
            statusMessage = "USE UNIQUE COLORS"
            return
        }
        
        let feedback = calculateFeedback(guess: guess)
        attempts.append(Attempt(guess: currentGuess, feedback: feedback))
        
        if feedback.filter({ $0 == .correct }).count == 4 {
            isGameOver = true
            statusMessage = "UNLOCKED!"
        } else if attempts.count >= 7 {
            isGameOver = true
            statusMessage = "LOCKED! FAILED"
        } else {
            statusMessage = "TRY AGAIN"
            currentGuess = [nil, nil, nil, nil]
            selectedSlotIndex = 0
        }
    }
    
    private func calculateFeedback(guess: [GameColor]) -> [FeedbackType] {
        if gameMode == .beginner {
            return zip(guess, secretCode).map { g, s in
                if g.id == s.id { return .correct }
                if secretCode.contains(where: { $0.id == g.id }) { return .misplaced }
                return .none
            }
        } else {
            // Mastermind style feedback
            var correctCount = 0
            var misplacedCount = 0
            
            var secretCopy = secretCode
            var guessCopy = guess
            
            // First pass: count correct
            for i in 0..<4 {
                if guess[i].id == secretCode[i].id {
                    correctCount += 1
                    // Mark as used
                    // We can use a different approach for clarity
                }
            }
            
            // Second pass: count misplaced
            // For a simpler implementation when colors are unique:
            let secretIds = secretCode.map { $0.id }
            let guessIds = guess.map { $0.id }
            
            let commonColors = Set(secretIds).intersection(Set(guessIds)).count
            misplacedCount = commonColors - correctCount
            
            var result: [FeedbackType] = []
            for _ in 0..<correctCount { result.append(.correct) }
            for _ in 0..<misplacedCount { result.append(.misplaced) }
            while result.count < 4 { result.append(.none) }
            
            return result
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
