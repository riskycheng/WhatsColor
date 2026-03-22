import Foundation

class HintManager: ObservableObject {
    static let shared = HintManager()
    
    @Published var remainingHints: Int = 3
    @Published var lastHint: HintType?
    
    private let hintsKey = "WhatsColor_RemainingHints"
    private let lastResetKey = "WhatsColor_LastHintReset"
    
    enum HintType {
        case correctPosition(Int, GameColor)  // Position and color that is correct
        case colorExists(GameColor)           // A color that exists in the code (but not position)
        case colorNotExists(GameColor)        // A color that doesn't exist in the code
        
        func description(for theme: GameTheme) -> String {
            switch self {
            case .correctPosition(let pos, let color):
                return "Position \(pos + 1) is \(color.displayName(for: theme))"
            case .colorExists(let color):
                return "\(color.displayName(for: theme)) is in the code"
            case .colorNotExists(let color):
                return "\(color.displayName(for: theme)) is NOT in the code"
            }
        }
    }
    
    private init() {
        self.remainingHints = UserDefaults.standard.integer(forKey: hintsKey)
        if self.remainingHints == 0 {
            self.remainingHints = 3 // Default starting hints
        }
        checkDailyReset()
    }
    
    // MARK: - Daily Reset
    
    private func checkDailyReset() {
        let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if !calendar.isDateInToday(lastReset) {
            // It's a new day, reset hints
            remainingHints = 3
            saveHints()
            UserDefaults.standard.set(Date(), forKey: lastResetKey)
            
            #if DEBUG
            print("🎯 Hints: Daily reset - 3 hints restored")
            #endif
        }
    }
    
    private func saveHints() {
        UserDefaults.standard.set(remainingHints, forKey: hintsKey)
    }
    
    // MARK: - Hint Generation
    
    func useHint(secretCode: [GameColor], currentGuess: [GameColor?], attempts: [GameRowModel]) -> HintType? {
        guard remainingHints > 0 else { return nil }
        
        let hint = generateHint(secretCode: secretCode, currentGuess: currentGuess, attempts: attempts)
        
        if hint != nil {
            remainingHints -= 1
            lastHint = hint
            saveHints()
            
            SoundManager.shared.playSuccess()
            SoundManager.shared.hapticSuccess()
        }
        
        return hint
    }
    
    private func generateHint(secretCode: [GameColor], currentGuess: [GameColor?], attempts: [GameRowModel]) -> HintType? {
        // Strategy 1: If there's a correct position from previous attempts, reveal it
        for attempt in attempts where attempt.isComplete {
            for (index, feedback) in attempt.feedback.enumerated() {
                if feedback == .correct, let color = attempt.colors[index] {
                    // Check if this position is still unknown in current guess
                    if currentGuess[index] == nil || currentGuess[index] != color {
                        return .correctPosition(index, color)
                    }
                }
            }
        }
        
        // Strategy 2: Reveal a color that exists in the code but position is unknown
        let usedColors = Set(currentGuess.compactMap { $0 })
        let availableColors = Set(secretCode).subtracting(usedColors)
        
        if let randomColor = availableColors.randomElement() {
            return .colorExists(randomColor)
        }
        
        // Strategy 3: Reveal a color that doesn't exist (elimination hint)
        let allColors = Set(GameColor.allCases)
        let unusedColors = allColors.subtracting(Set(secretCode)).subtracting(usedColors)
        
        if let randomUnusedColor = unusedColors.randomElement() {
            return .colorNotExists(randomUnusedColor)
        }
        
        return nil
    }
    
    // MARK: - Add Hints
    
    func addHints(_ count: Int) {
        remainingHints += count
        saveHints()
    }
    
    func resetHints() {
        remainingHints = 3
        saveHints()
    }
    
    // MARK: - Hint Availability
    
    var hasHintsAvailable: Bool {
        return remainingHints > 0
    }
    
    var hintButtonText: String {
        if remainingHints > 0 {
            return "HINT (\(remainingHints))"
        } else {
            return "NO HINTS"
        }
    }
}
