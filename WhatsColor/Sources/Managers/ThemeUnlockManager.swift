import Foundation
import Combine

class ThemeUnlockManager: ObservableObject {
    static let shared = ThemeUnlockManager()
    
    @Published private(set) var unlockedThemes: Set<GameTheme>
    @Published private(set) var themeUnlockProgress: [GameTheme: Int]
    
    private let unlockedThemesKey = "WhatsColor_UnlockedThemes"
    private let themeProgressKey = "WhatsColor_ThemeProgress"
    
    // Theme unlock requirements (level needed)
    let themeUnlockRequirements: [GameTheme: Int] = [
        .classic: 1,      // Always unlocked
        .pixelFruit: 1,   // Always unlocked
        .cuteCat: 5,      // Unlock at level 5
        .cuteDog: 10,     // Unlock at level 10
        .fastFood: 20,    // Unlock at level 20
        .fruit: 35,       // Unlock at level 35
        .vegetables: 50   // Unlock at level 50
    ]
    
    private init() {
        self.unlockedThemes = ThemeUnlockManager.loadUnlockedThemes()
        self.themeUnlockProgress = ThemeUnlockManager.loadThemeProgress()
        
        // Ensure classic and pixelFruit are always unlocked
        unlockedThemes.insert(.classic)
        unlockedThemes.insert(.pixelFruit)
    }
    
    // MARK: - Persistence
    
    private static func loadUnlockedThemes() -> Set<GameTheme> {
        guard let data = UserDefaults.standard.data(forKey: "WhatsColor_UnlockedThemes"),
              let themes = try? JSONDecoder().decode([GameTheme].self, from: data) else {
            // Default: classic and pixelFruit are unlocked
            return [.classic, .pixelFruit]
        }
        return Set(themes)
    }
    
    private static func loadThemeProgress() -> [GameTheme: Int] {
        guard let data = UserDefaults.standard.data(forKey: "WhatsColor_ThemeProgress"),
              let progress = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        
        var result: [GameTheme: Int] = [:]
        for (key, value) in progress {
            if let theme = GameTheme(rawValue: key) {
                result[theme] = value
            }
        }
        return result
    }
    
    private func saveUnlockedThemes() {
        if let data = try? JSONEncoder().encode(Array(unlockedThemes)) {
            UserDefaults.standard.set(data, forKey: unlockedThemesKey)
        }
    }
    
    private func saveThemeProgress() {
        var stringDict: [String: Int] = [:]
        for (theme, progress) in themeUnlockProgress {
            stringDict[theme.rawValue] = progress
        }
        if let data = try? JSONEncoder().encode(stringDict) {
            UserDefaults.standard.set(data, forKey: themeProgressKey)
        }
    }
    
    // MARK: - Theme Unlock Logic
    
    func isThemeUnlocked(_ theme: GameTheme) -> Bool {
        return unlockedThemes.contains(theme)
    }
    
    func getUnlockRequirement(for theme: GameTheme) -> Int {
        return themeUnlockRequirements[theme] ?? 1
    }
    
    func getProgressForTheme(_ theme: GameTheme, currentLevel: Int) -> (current: Int, required: Int, isUnlocked: Bool) {
        let required = getUnlockRequirement(for: theme)
        let isUnlocked = isThemeUnlocked(theme)
        return (current: currentLevel, required: required, isUnlocked: isUnlocked)
    }
    
    func checkAndUnlockThemes(currentLevel: Int) -> [GameTheme] {
        var newlyUnlocked: [GameTheme] = []
        
        for (theme, requirement) in themeUnlockRequirements {
            if !unlockedThemes.contains(theme) && currentLevel >= requirement {
                unlockedThemes.insert(theme)
                newlyUnlocked.append(theme)
                
                #if DEBUG
                print("🎨 Theme Unlocked: \(theme.rawValue) at level \(currentLevel)")
                #endif
            }
        }
        
        if !newlyUnlocked.isEmpty {
            saveUnlockedThemes()
        }
        
        return newlyUnlocked
    }
    
    func unlockTheme(_ theme: GameTheme) {
        unlockedThemes.insert(theme)
        saveUnlockedThemes()
    }
    
    func getNextUnlockableTheme(currentLevel: Int) -> (theme: GameTheme, requirement: Int)? {
        let lockedThemes = GameTheme.allCases.filter { !isThemeUnlocked($0) }
        
        guard let nextTheme = lockedThemes.min(by: { 
            getUnlockRequirement(for: $0) < getUnlockRequirement(for: $1) 
        }) else {
            return nil
        }
        
        let requirement = getUnlockRequirement(for: nextTheme)
        return (nextTheme, requirement)
    }
    
    // MARK: - Reset
    
    func resetThemeUnlocks() {
        unlockedThemes = [.classic, .pixelFruit]
        themeUnlockProgress = [:]
        saveUnlockedThemes()
        saveThemeProgress()
    }
    
    // MARK: - Theme Descriptions
    
    func getUnlockDescription(for theme: GameTheme) -> String {
        switch theme {
        case .classic:
            return "Default theme - Always available"
        case .pixelFruit:
            return "Starter theme - Always available"
        case .cuteCat:
            return "Unlock at Level 5"
        case .cuteDog:
            return "Unlock at Level 10"
        case .fastFood:
            return "Unlock at Level 20"
        case .fruit:
            return "Unlock at Level 35"
        case .vegetables:
            return "Unlock at Level 50"
        }
    }
}
