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

enum FeedbackMode: String, CaseIterable, Identifiable, Codable {
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

enum GameTheme: String, CaseIterable, Identifiable, Codable {
    case classic = "CLASSIC"
    case pixelFruit = "PIXEL FRUIT"
    case cuteCat = "CUTE CAT"
    case cuteDog = "CUTE DOG"
    case fastFood = "FAST FOOD"
    case fruit = "FRUIT"
    case vegetables = "VEGETABLES"

    var id: String { rawValue }

    var logoName: String {
        switch self {
        case .classic: return "COLOR"
        case .pixelFruit: return "PIXEL"
        case .cuteCat: return "CATS"
        case .cuteDog: return "DOGS"
        case .fastFood: return "FOOD"
        case .fruit: return "FRUIT"
        case .vegetables: return "VEGGIE"
        }
    }

    var folderName: String? {
        switch self {
        case .pixelFruit: return "pixel_fruit"
        case .cuteCat: return "cute_cat"
        case .cuteDog: return "cute_dog"
        case .fastFood: return "nice_fastfood"
        case .fruit: return "nice_fruit"
        case .vegetables: return "nice_vegitables"
        default: return nil
        }
    }

    func iconNames() -> [String] {
        switch self {
        case .pixelFruit:
            return ["icon_baximei", "icon_bocai", "icon_fupenzi", "icon_lanmei", "icon_niuyouguo", "icon_qiyiguo", "icon_xilanhua"]
        case .cuteCat:
            return ["baimao", "buoumao", "heimao", "jumao", "nainiumao", "sanhuamao", "wumaomao"]
        case .cuteDog:
            return ["cangao", "chaiquan", "fadou", "hashiqi", "jinmao", "lachangquan", "tianyuanquan"]
        case .fastFood:
            return ["hanbaobao", "makalong", "pisa", "sanwenzhi", "shutiao", "tiantianquan", "zhenzhunaicha"]
        case .fruit:
            return ["boluo", "caomei", "cheng", "fanqie", "li", "liulian", "niuyouguo"]
        case .vegetables:
            return ["kugua", "lajiao", "luobu", "nangua", "xilanhua", "yangcong", "yumi"]
        case .classic:
            return []
        }
    }

    func image(for color: GameColor) -> Image? {
        let names = iconNames()
        guard color.rawValue < names.count else {
            return nil
        }
        let name = names[color.rawValue]
        
        // 1. Try simple named lookup (Asset Catalog or root)
        if let uiImage = UIImage(named: name) {
            return themeImage(uiImage)
        }
        
        // 2. Try with theme folder prefix (if added as folder reference)
        if let folder = folderName {
            if let uiImage = UIImage(named: "icon_materials/\(folder)/\(name)") {
                return themeImage(uiImage)
            }
            
            // 3. Absolute bundle path lookup with variations
            let exts = ["png", "jpg", "jpeg"]
            for ext in exts {
                // Try the standard path
                if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "icon_materials/\(folder)") {
                    if let uiImage = UIImage(contentsOfFile: path) {
                        return themeImage(uiImage)
                    }
                }
                
                // Try flattened if it ended up in the root
                if let path = Bundle.main.path(forResource: name, ofType: ext) {
                    if let uiImage = UIImage(contentsOfFile: path) {
                        return themeImage(uiImage)
                    }
                }
            }
        }
        
        // Final fallback: Recursive search in the bundle (only if it's there but we missed the path)
        return nil
    }
    
    private func themeImage(_ uiImage: UIImage) -> Image {
        let img = Image(uiImage: uiImage)
        return self == .pixelFruit ? img.interpolation(.none) : img
    }
}

enum GameDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"

    var id: String { rawValue }

    // All modes have 7 attempts
    var maxAttempts: Int {
        7
    }

    var description: String {
        switch self {
        case .easy: return "Limited colors"
        case .normal: return "Position feedback"
        case .hard: return "Aggregate only"
        }
    }

    var baseTime: Int {
        switch self {
        case .easy: return 0  // No time limit
        case .normal: return 300
        case .hard: return 300
        }
    }
    
    /// Whether this difficulty has a time limit
    var hasTimeLimit: Bool {
        baseTime > 0
    }
    
    /// Number of colors enabled in the picker (Easy mode only enables 4)
    var enabledColorCount: Int {
        switch self {
        case .easy: return 4
        case .normal, .hard: return GameColor.allCases.count
        }
    }
    
    /// Whether feedback shows position information
    var showsPositionFeedback: Bool {
        switch self {
        case .easy, .normal: return true
        case .hard: return false
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
    var fixedSlots: [Bool]
    var activeIndex: Int
    var mode: FeedbackMode
    var difficulty: GameDifficulty
    var theme: GameTheme
    var isGameOver: Bool
    var level: Int
    var message: String

    static let initial = GameStateModel(
        secretCode: [],
        attempts: [],
        currentGuess: Array(repeating: nil, count: 4),
        fixedSlots: Array(repeating: false, count: 4),
        activeIndex: 0,
        mode: .advanced,
        difficulty: .normal,
        theme: .pixelFruit,
        isGameOver: false,
        level: 1,
        message: "READY"
    )

    var maxAttempts: Int {
        difficulty.maxAttempts
    }
}
