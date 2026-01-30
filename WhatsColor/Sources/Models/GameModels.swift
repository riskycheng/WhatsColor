import Foundation
import SwiftUI

enum GameColor: Int, CaseIterable, Identifiable, Codable {
    case red = 0
    case green = 1
    case orange = 2
    case blue = 3
    case yellow = 4
    case purple = 5
    case cyan = 6

    var id: Int { rawValue }

    var hex: String {
        switch self {
        case .red: return "#ff3b30"
        case .green: return "#4cd964"
        case .orange: return "#ff9500"
        case .blue: return "#007aff"
        case .yellow: return "#ffcc00"
        case .purple: return "#af52de"
        case .cyan: return "#5ac8fa"
        }
    }

    var color: Color {
        Color(hex: hex)
    }

    var name: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .orange: return "Orange"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .purple: return "Purple"
        case .cyan: return "Cyan"
        }
    }
}

enum FeedbackType: Equatable {
    case correct
    case misplaced
    case wrong
    case empty
}

enum FeedbackMode: String, CaseIterable, Identifiable {
    case beginner = "Line Hint"
    case advanced = "Dot Hint"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .beginner:
            return "Shows correct/wrong/misplaced for each position"
        case .advanced:
            return "Shows only total correct and misplaced colors"
        }
    }
}

enum GameDifficulty: String, CaseIterable, Identifiable {
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"

    var id: String { rawValue }

    // Always return 7 for UI consistency - layout doesn't change with difficulty
    var maxAttempts: Int {
        7
    }

    var description: String {
        switch self {
        case .easy: return "10 attempts"
        case .normal: return "7 attempts"
        case .hard: return "5 attempts"
        }
    }
}

struct GameRowModel: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var colors: [GameColor?]
    var feedback: [FeedbackType]

    init(rowNumber: Int, colors: [GameColor?] = Array(repeating: nil, count: 4), feedback: [FeedbackType] = Array(repeating: .empty, count: 4)) {
        self.rowNumber = rowNumber
        self.colors = colors
        self.feedback = feedback
    }

    var isComplete: Bool {
        colors.allSatisfy { $0 != nil }
    }
}

struct GameStateModel {
    var secretCode: [GameColor]
    var attempts: [GameRowModel]
    var currentGuess: [GameColor?]
    var activeIndex: Int
    var mode: FeedbackMode
    var difficulty: GameDifficulty
    var isGameOver: Bool
    var level: Int
    var message: String

    static let initial = GameStateModel(
        secretCode: [],
        attempts: [],
        currentGuess: Array(repeating: nil, count: 4),
        activeIndex: 0,
        mode: .advanced,
        difficulty: .normal,
        isGameOver: false,
        level: 1,
        message: "READY"
    )

    var maxAttempts: Int {
        difficulty.maxAttempts
    }
}
