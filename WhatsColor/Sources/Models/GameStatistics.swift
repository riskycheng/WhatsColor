import Foundation

struct GameStatistics: Codable, Equatable {
    // Total games played
    var totalGamesPlayed: Int = 0
    var totalGamesWon: Int = 0
    var totalGamesLost: Int = 0
    
    // Win rate
    var winRate: Double {
        guard totalGamesPlayed > 0 else { return 0.0 }
        return Double(totalGamesWon) / Double(totalGamesPlayed)
    }
    
    // Current streaks
    var currentWinStreak: Int = 0
    var currentLossStreak: Int = 0
    var bestWinStreak: Int = 0
    
    // Attempts statistics
    var totalAttempts: Int = 0
    var bestAttemptCount: Int = Int.max
    var averageAttempts: Double {
        guard totalGamesWon > 0 else { return 0.0 }
        return Double(totalAttempts) / Double(totalGamesWon)
    }
    
    // Time statistics (in seconds)
    var totalTimePlayed: TimeInterval = 0
    var bestTime: TimeInterval = TimeInterval.infinity
    var averageTime: TimeInterval {
        guard totalGamesPlayed > 0 else { return 0.0 }
        return totalTimePlayed / Double(totalGamesPlayed)
    }
    
    // Difficulty-specific statistics
    var easyStats = DifficultyStatistics()
    var normalStats = DifficultyStatistics()
    var hardStats = DifficultyStatistics()
    
    // Mode-specific statistics
    var soloStats = ModeStatistics()
    var dualStats = ModeStatistics()
    
    // History (last 100 games)
    var recentGames: [GameRecord] = []
    private let maxRecentGames = 100
    
    mutating func recordGame(difficulty: GameDifficulty, mode: GameViewModel.GameMode, won: Bool, attempts: Int, timeSpent: TimeInterval) {
        totalGamesPlayed += 1
        
        if won {
            totalGamesWon += 1
            currentWinStreak += 1
            currentLossStreak = 0
            bestWinStreak = max(bestWinStreak, currentWinStreak)
            
            totalAttempts += attempts
            bestAttemptCount = min(bestAttemptCount, attempts)
        } else {
            totalGamesLost += 1
            currentLossStreak += 1
            currentWinStreak = 0
        }
        
        totalTimePlayed += timeSpent
        if won {
            bestTime = min(bestTime, timeSpent)
        }
        
        // Update difficulty-specific stats
        switch difficulty {
        case .easy:
            easyStats.recordGame(won: won, attempts: attempts, time: timeSpent)
        case .normal:
            normalStats.recordGame(won: won, attempts: attempts, time: timeSpent)
        case .hard:
            hardStats.recordGame(won: won, attempts: attempts, time: timeSpent)
        }
        
        // Update mode-specific stats
        switch mode {
        case .solo:
            soloStats.recordGame(won: won)
        case .dual:
            dualStats.recordGame(won: won)
        }
        
        // Add to recent games
        let record = GameRecord(
            date: Date(),
            difficulty: difficulty,
            mode: mode,
            won: won,
            attempts: attempts,
            timeSpent: timeSpent
        )
        recentGames.append(record)
        if recentGames.count > maxRecentGames {
            recentGames.removeFirst()
        }
    }
    
    func statsForDifficulty(_ difficulty: GameDifficulty) -> DifficultyStatistics {
        switch difficulty {
        case .easy: return easyStats
        case .normal: return normalStats
        case .hard: return hardStats
        }
    }
}

struct DifficultyStatistics: Codable, Equatable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var gamesLost: Int = 0
    var totalAttempts: Int = 0
    var bestAttempts: Int = Int.max
    var totalTime: TimeInterval = 0
    var bestTime: TimeInterval = TimeInterval.infinity
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
    
    var averageAttempts: Double {
        guard gamesWon > 0 else { return 0.0 }
        return Double(totalAttempts) / Double(gamesWon)
    }
    
    var averageTime: TimeInterval {
        guard gamesPlayed > 0 else { return 0.0 }
        return totalTime / Double(gamesPlayed)
    }
    
    mutating func recordGame(won: Bool, attempts: Int, time: TimeInterval) {
        gamesPlayed += 1
        totalTime += time
        
        if won {
            gamesWon += 1
            totalAttempts += attempts
            bestAttempts = min(bestAttempts, attempts)
            bestTime = min(bestTime, time)
        } else {
            gamesLost += 1
        }
    }
}

struct ModeStatistics: Codable, Equatable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var gamesLost: Int = 0
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
    
    mutating func recordGame(won: Bool) {
        gamesPlayed += 1
        if won {
            gamesWon += 1
        } else {
            gamesLost += 1
        }
    }
}

struct GameRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let date: Date
    let difficulty: GameDifficulty
    let modeRawValue: String
    let won: Bool
    let attempts: Int
    let timeSpent: TimeInterval
    
    init(id: UUID = UUID(), date: Date, difficulty: GameDifficulty, mode: GameViewModel.GameMode, won: Bool, attempts: Int, timeSpent: TimeInterval) {
        self.id = id
        self.date = date
        self.difficulty = difficulty
        self.modeRawValue = mode == .solo ? "solo" : "dual"
        self.won = won
        self.attempts = attempts
        self.timeSpent = timeSpent
    }
    
    var mode: GameViewModel.GameMode {
        return modeRawValue == "solo" ? .solo : .dual
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let minutes = Int(timeSpent) / 60
        let seconds = Int(timeSpent) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
