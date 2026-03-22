import XCTest
@testable import WhatsColor

@MainActor
class StatisticsManagerTests: XCTestCase {
    var statisticsManager: StatisticsManager!
    
    override func setUp() {
        super.setUp()
        statisticsManager = StatisticsManager.shared
        statisticsManager.resetAllStatistics()
    }
    
    override func tearDown() {
        statisticsManager.resetAllStatistics()
        statisticsManager = nil
        super.tearDown()
    }
    
    func testInitialStatistics() {
        XCTAssertEqual(statisticsManager.statistics.totalGamesPlayed, 0)
        XCTAssertEqual(statisticsManager.statistics.totalGamesWon, 0)
        XCTAssertEqual(statisticsManager.statistics.totalGamesLost, 0)
        XCTAssertEqual(statisticsManager.statistics.currentWinStreak, 0)
        XCTAssertEqual(statisticsManager.statistics.bestWinStreak, 0)
    }
    
    func testRecordWin() {
        statisticsManager.startGame()
        statisticsManager.recordAttempt()
        statisticsManager.recordAttempt()
        
        statisticsManager.endGame(won: true, difficulty: .normal, mode: .solo)
        
        XCTAssertEqual(statisticsManager.statistics.totalGamesPlayed, 1)
        XCTAssertEqual(statisticsManager.statistics.totalGamesWon, 1)
        XCTAssertEqual(statisticsManager.statistics.totalGamesLost, 0)
        XCTAssertEqual(statisticsManager.statistics.currentWinStreak, 1)
        XCTAssertEqual(statisticsManager.statistics.bestWinStreak, 1)
        XCTAssertEqual(statisticsManager.statistics.totalAttempts, 2)
    }
    
    func testRecordLoss() {
        statisticsManager.startGame()
        statisticsManager.recordAttempt()
        statisticsManager.recordAttempt()
        statisticsManager.recordAttempt()
        
        statisticsManager.endGame(won: false, difficulty: .hard, mode: .dual)
        
        XCTAssertEqual(statisticsManager.statistics.totalGamesPlayed, 1)
        XCTAssertEqual(statisticsManager.statistics.totalGamesWon, 0)
        XCTAssertEqual(statisticsManager.statistics.totalGamesLost, 1)
        XCTAssertEqual(statisticsManager.statistics.currentWinStreak, 0)
        XCTAssertEqual(statisticsManager.statistics.currentLossStreak, 1)
    }
    
    func testWinStreak() {
        // Record 3 wins in a row
        for _ in 0..<3 {
            statisticsManager.startGame()
            statisticsManager.recordAttempt()
            statisticsManager.endGame(won: true, difficulty: .easy, mode: .solo)
        }
        
        XCTAssertEqual(statisticsManager.statistics.currentWinStreak, 3)
        XCTAssertEqual(statisticsManager.statistics.bestWinStreak, 3)
        
        // Record a loss
        statisticsManager.startGame()
        statisticsManager.endGame(won: false, difficulty: .easy, mode: .solo)
        
        XCTAssertEqual(statisticsManager.statistics.currentWinStreak, 0)
        XCTAssertEqual(statisticsManager.statistics.currentLossStreak, 1)
        XCTAssertEqual(statisticsManager.statistics.bestWinStreak, 3) // Best streak preserved
    }
    
    func testDifficultySpecificStats() {
        // Record games for different difficulties
        statisticsManager.startGame()
        statisticsManager.endGame(won: true, difficulty: .easy, mode: .solo)
        
        statisticsManager.startGame()
        statisticsManager.endGame(won: true, difficulty: .normal, mode: .solo)
        
        statisticsManager.startGame()
        statisticsManager.endGame(won: false, difficulty: .hard, mode: .solo)
        
        let easyStats = statisticsManager.statistics.easyStats
        let normalStats = statisticsManager.statistics.normalStats
        let hardStats = statisticsManager.statistics.hardStats
        
        XCTAssertEqual(easyStats.gamesPlayed, 1)
        XCTAssertEqual(easyStats.gamesWon, 1)
        
        XCTAssertEqual(normalStats.gamesPlayed, 1)
        XCTAssertEqual(normalStats.gamesWon, 1)
        
        XCTAssertEqual(hardStats.gamesPlayed, 1)
        XCTAssertEqual(hardStats.gamesWon, 0)
        XCTAssertEqual(hardStats.gamesLost, 1)
    }
    
    func testModeSpecificStats() {
        statisticsManager.startGame()
        statisticsManager.endGame(won: true, difficulty: .normal, mode: .solo)
        
        statisticsManager.startGame()
        statisticsManager.endGame(won: false, difficulty: .normal, mode: .dual)
        
        XCTAssertEqual(statisticsManager.statistics.soloStats.gamesPlayed, 1)
        XCTAssertEqual(statisticsManager.statistics.soloStats.gamesWon, 1)
        
        XCTAssertEqual(statisticsManager.statistics.dualStats.gamesPlayed, 1)
        XCTAssertEqual(statisticsManager.statistics.dualStats.gamesWon, 0)
    }
    
    func testWinRateCalculation() {
        // 3 wins, 2 losses
        for i in 0..<5 {
            statisticsManager.startGame()
            statisticsManager.endGame(won: i < 3, difficulty: .normal, mode: .solo)
        }
        
        XCTAssertEqual(statisticsManager.statistics.winRate, 0.6)
        XCTAssertEqual(statisticsManager.formattedWinRate(), "60.0%")
    }
    
    func testBestAttemptsTracking() {
        // First win with 5 attempts
        statisticsManager.startGame()
        for _ in 0..<5 {
            statisticsManager.recordAttempt()
        }
        statisticsManager.endGame(won: true, difficulty: .normal, mode: .solo)
        
        // Second win with 3 attempts (better)
        statisticsManager.startGame()
        for _ in 0..<3 {
            statisticsManager.recordAttempt()
        }
        statisticsManager.endGame(won: true, difficulty: .normal, mode: .solo)
        
        // Third win with 4 attempts
        statisticsManager.startGame()
        for _ in 0..<4 {
            statisticsManager.recordAttempt()
        }
        statisticsManager.endGame(won: true, difficulty: .normal, mode: .solo)
        
        XCTAssertEqual(statisticsManager.getBestAttempts(), 3)
        XCTAssertEqual(statisticsManager.formattedAverageAttempts(), "4.0")
    }
    
    func testRecentGamesLimit() {
        // Record more than 100 games
        for i in 0..<105 {
            statisticsManager.startGame()
            statisticsManager.endGame(won: i % 2 == 0, difficulty: .normal, mode: .solo)
        }
        
        XCTAssertEqual(statisticsManager.statistics.totalGamesPlayed, 105)
        XCTAssertEqual(statisticsManager.statistics.recentGames.count, 100) // Should be limited to 100
    }
    
    func testFormattedTimePlayed() {
        // Test that formattedTotalTimePlayed returns a valid string
        // We can't directly set totalTimePlayed since it's private,
        // so we just verify the method doesn't crash and returns something
        let formatted = statisticsManager.formattedTotalTimePlayed()
        // Should return "0m" when no time has been recorded
        XCTAssertEqual(formatted, "0m")
    }
}
