import Foundation
import Combine

class DailyChallengeManager: ObservableObject {
    static let shared = DailyChallengeManager()
    
    @Published private(set) var todayChallenge: DailyChallenge?
    @Published private(set) var hasCompletedToday: Bool = false
    @Published private(set) var completionTime: TimeInterval?
    @Published private(set) var completionAttempts: Int?
    
    private let challengeKey = "WhatsColor_DailyChallenge"
    private let completionKey = "WhatsColor_DailyCompletion"
    private let lastChallengeDateKey = "WhatsColor_LastChallengeDate"
    
    struct DailyChallenge: Codable {
        let date: Date
        let secretCode: [GameColor]
        let difficulty: GameDifficulty
        let theme: GameTheme
        let timeLimit: Int
        let maxAttempts: Int
        
        var isForToday: Bool {
            Calendar.current.isDateInToday(date)
        }
    }
    
    struct DailyCompletion: Codable {
        let date: Date
        let won: Bool
        let timeSpent: TimeInterval
        let attempts: Int
    }
    
    private init() {
        loadTodayChallenge()
        checkAndGenerateNewChallenge()
    }
    
    // MARK: - Challenge Generation
    
    private func checkAndGenerateNewChallenge() {
        let calendar = Calendar.current
        
        // Check if we need a new challenge for today
        if let lastChallenge = todayChallenge {
            if !lastChallenge.isForToday {
                // Generate new challenge for today
                generateNewChallenge()
            }
        } else {
            generateNewChallenge()
        }
        
        // Check if user has already completed today's challenge
        if let completion = loadTodayCompletion() {
            hasCompletedToday = calendar.isDateInToday(completion.date)
            if hasCompletedToday {
                completionTime = completion.timeSpent
                completionAttempts = completion.attempts
            }
        } else {
            hasCompletedToday = false
            completionTime = nil
            completionAttempts = nil
        }
    }
    
    private func generateNewChallenge() {
        // Generate a deterministic challenge based on today's date
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use date components as seed for deterministic generation
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        let seed = (components.year ?? 2024) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
        
        // Generate secret code using seed
        var randomCode: [GameColor] = []
        var availableColors = GameColor.allCases
        
        for i in 0..<4 {
            let index = (seed + i * 31) % availableColors.count
            randomCode.append(availableColors[index])
            availableColors.remove(at: index)
        }
        
        // Determine difficulty based on day of week (harder on weekends)
        let weekday = calendar.component(.weekday, from: today)
        let difficulty: GameDifficulty = (weekday == 1 || weekday == 7) ? .hard : .normal
        
        // Select theme based on month
        let month = components.month ?? 1
        let themes = GameTheme.allCases
        let themeIndex = (month - 1) % themes.count
        let theme = themes[themeIndex]
        
        let challenge = DailyChallenge(
            date: today,
            secretCode: randomCode,
            difficulty: difficulty,
            theme: theme,
            timeLimit: difficulty == .hard ? 180 : 300,
            maxAttempts: 7
        )
        
        todayChallenge = challenge
        saveChallenge(challenge)
        
        #if DEBUG
        print("📅 Daily Challenge: Generated new challenge for \(today)")
        print("   Difficulty: \(difficulty.rawValue), Theme: \(theme.rawValue)")
        #endif
    }
    
    // MARK: - Persistence
    
    private func loadTodayChallenge() {
        guard let data = UserDefaults.standard.data(forKey: challengeKey),
              let challenge = try? JSONDecoder().decode(DailyChallenge.self, from: data) else {
            return
        }
        todayChallenge = challenge
    }
    
    private func saveChallenge(_ challenge: DailyChallenge) {
        if let data = try? JSONEncoder().encode(challenge) {
            UserDefaults.standard.set(data, forKey: challengeKey)
        }
    }
    
    private func loadTodayCompletion() -> DailyCompletion? {
        guard let data = UserDefaults.standard.data(forKey: completionKey),
              let completion = try? JSONDecoder().decode(DailyCompletion.self, from: data) else {
            return nil
        }
        return completion
    }
    
    func recordCompletion(won: Bool, timeSpent: TimeInterval, attempts: Int) {
        let completion = DailyCompletion(
            date: Date(),
            won: won,
            timeSpent: timeSpent,
            attempts: attempts
        )
        
        if let data = try? JSONEncoder().encode(completion) {
            UserDefaults.standard.set(data, forKey: completionKey)
        }
        
        hasCompletedToday = true
        if won {
            completionTime = timeSpent
            completionAttempts = attempts
        }
        
        #if DEBUG
        print("📅 Daily Challenge: Recorded completion - Won: \(won), Time: \(timeSpent), Attempts: \(attempts)")
        #endif
    }
    
    // MARK: - Helpers
    
    func getChallengeDescription() -> String {
        guard let challenge = todayChallenge else {
            return "No challenge available"
        }
        
        let difficultyText = challenge.difficulty.rawValue
        let themeText = challenge.theme.rawValue
        let timeText = challenge.timeLimit > 0 ? "\(challenge.timeLimit)s" : "No limit"
        
        return "Today's Challenge: \(difficultyText) | \(themeText) | \(timeText)"
    }
    
    func formattedCompletionTime() -> String {
        guard let time = completionTime else { return "--:--" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Reset
    
    func resetDailyChallenge() {
        UserDefaults.standard.removeObject(forKey: challengeKey)
        UserDefaults.standard.removeObject(forKey: completionKey)
        todayChallenge = nil
        hasCompletedToday = false
        completionTime = nil
        completionAttempts = nil
        generateNewChallenge()
    }
}
