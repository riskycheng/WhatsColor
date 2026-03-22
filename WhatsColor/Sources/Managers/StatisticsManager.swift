import Foundation
import Combine

class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()
    
    @Published private(set) var statistics: GameStatistics
    
    private let statisticsKey = "WhatsColor_Statistics"
    private var gameStartTime: Date?
    private var currentGameAttempts: Int = 0
    
    private init() {
        self.statistics = StatisticsManager.loadStatistics()
    }
    
    // MARK: - Persistence
    
    private static func loadStatistics() -> GameStatistics {
        guard let data = UserDefaults.standard.data(forKey: "WhatsColor_Statistics"),
              let stats = try? JSONDecoder().decode(GameStatistics.self, from: data) else {
            return GameStatistics()
        }
        return stats
    }
    
    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(data, forKey: statisticsKey)
        }
    }
    
    // MARK: - Game Session Management
    
    func startGame() {
        gameStartTime = Date()
        currentGameAttempts = 0
    }
    
    func recordAttempt() {
        currentGameAttempts += 1
    }
    
    func endGame(won: Bool, difficulty: GameDifficulty, mode: GameViewModel.GameMode) {
        guard let startTime = gameStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        
        statistics.recordGame(
            difficulty: difficulty,
            mode: mode,
            won: won,
            attempts: currentGameAttempts,
            timeSpent: timeSpent
        )
        
        saveStatistics()
        
        // Reset session
        gameStartTime = nil
        currentGameAttempts = 0
        
        #if DEBUG
        print("📊 Statistics: Game recorded - Won: \(won), Attempts: \(currentGameAttempts), Time: \(timeSpent)")
        #endif
    }
    
    // MARK: - Statistics Access
    
    func getWinRate(for difficulty: GameDifficulty? = nil) -> Double {
        if let difficulty = difficulty {
            return statistics.statsForDifficulty(difficulty).winRate
        }
        return statistics.winRate
    }
    
    func getAverageAttempts(for difficulty: GameDifficulty? = nil) -> Double {
        if let difficulty = difficulty {
            return statistics.statsForDifficulty(difficulty).averageAttempts
        }
        return statistics.averageAttempts
    }
    
    func getBestAttempts(for difficulty: GameDifficulty? = nil) -> Int? {
        let best: Int
        if let difficulty = difficulty {
            best = statistics.statsForDifficulty(difficulty).bestAttempts
        } else {
            best = statistics.bestAttemptCount
        }
        return best == Int.max ? nil : best
    }
    
    func getBestTime(for difficulty: GameDifficulty? = nil) -> TimeInterval? {
        let best: TimeInterval
        if let difficulty = difficulty {
            best = statistics.statsForDifficulty(difficulty).bestTime
        } else {
            best = statistics.bestTime
        }
        return best == TimeInterval.infinity ? nil : best
    }
    
    func getRecentGames(limit: Int = 10) -> [GameRecord] {
        return Array(statistics.recentGames.suffix(limit).reversed())
    }
    
    // MARK: - Reset
    
    func resetAllStatistics() {
        statistics = GameStatistics()
        saveStatistics()
        
        #if DEBUG
        print("📊 Statistics: All statistics reset")
        #endif
    }
    
    // MARK: - Formatted Display Helpers
    
    func formattedWinRate(for difficulty: GameDifficulty? = nil) -> String {
        let rate = getWinRate(for: difficulty)
        return String(format: "%.1f%%", rate * 100)
    }
    
    func formattedAverageAttempts(for difficulty: GameDifficulty? = nil) -> String {
        let avg = getAverageAttempts(for: difficulty)
        return String(format: "%.1f", avg)
    }
    
    func formattedBestTime(for difficulty: GameDifficulty? = nil) -> String {
        guard let time = getBestTime(for: difficulty) else { return "--:--" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formattedTotalTimePlayed() -> String {
        let total = statistics.totalTimePlayed
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
