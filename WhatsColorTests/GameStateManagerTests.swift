import XCTest
@testable import WhatsColor

@MainActor
class GameStateManagerTests: XCTestCase {
    var gameStateManager: GameStateManager!

    override func setUp() {
        super.setUp()
        gameStateManager = GameStateManager()
    }

    override func tearDown() {
        gameStateManager.cleanup()
        gameStateManager = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(gameStateManager.state.level, 1)
        XCTAssertFalse(gameStateManager.isGameOver)
        XCTAssertEqual(gameStateManager.message, "READY")
        XCTAssertEqual(gameStateManager.activeIndex, 0)
    }

    func testSecretCodeGeneration() {
        let secretCode = gameStateManager.generateSecretCode()
        XCTAssertEqual(secretCode.count, 4)

        // Check that all colors are unique
        let uniqueColors = Set(secretCode)
        XCTAssertEqual(uniqueColors.count, 4)
    }

    func testDeterministicSecretCodeForSoloMode() {
        gameStateManager.state.mode = .advanced
        gameStateManager.state.level = 1

        let code1 = gameStateManager.generateSecretCode()
        let code2 = gameStateManager.generateSecretCode()

        // Should generate the same code for the same level
        XCTAssertEqual(code1, code2)
        XCTAssertEqual(code1, [.red, .green, .orange, .blue])
    }

    func testColorPlacement() {
        gameStateManager.setColor(.red, at: 0)
        XCTAssertEqual(gameStateManager.currentGuess[0], .red)
        XCTAssertEqual(gameStateManager.activeIndex, 1) // Should auto-advance
    }

    func testAutoAdvanceLogic() {
        // Fill first 3 slots
        gameStateManager.setColor(.red, at: 0)
        gameStateManager.setColor(.green, at: 1)
        gameStateManager.setColor(.blue, at: 2)

        XCTAssertEqual(gameStateManager.activeIndex, 3)

        // Fill last slot
        gameStateManager.setColor(.yellow, at: 3)

        // Should stay at last position when all filled
        XCTAssertTrue(gameStateManager.isCurrentGuessComplete)
    }

    func testFixedSlotBehavior() {
        gameStateManager.setColor(.red, at: 0)
        gameStateManager.toggleFixed(at: 0)

        XCTAssertTrue(gameStateManager.fixedSlots[0])

        // Should not allow changing fixed slots
        gameStateManager.setColor(.blue, at: 0)
        XCTAssertEqual(gameStateManager.currentGuess[0], .red) // Should remain red
    }

    func testFeedbackCalculationBeginner() {
        gameStateManager.state.mode = .beginner
        gameStateManager.state.secretCode = [.red, .green, .blue, .yellow]

        let feedback = gameStateManager.calculateFeedback(
            guess: [.red, .yellow, .green, .purple],
            secret: [.red, .green, .blue, .yellow]
        )

        XCTAssertEqual(feedback[0], .correct)      // Red in correct position
        XCTAssertEqual(feedback[1], .misplaced)   // Yellow in wrong position
        XCTAssertEqual(feedback[2], .misplaced)   // Green in wrong position
        XCTAssertEqual(feedback[3], .wrong)       // Purple not in secret
    }

    func testFeedbackCalculationAdvanced() {
        gameStateManager.state.mode = .advanced
        gameStateManager.state.secretCode = [.red, .green, .blue, .yellow]

        let feedback = gameStateManager.calculateFeedback(
            guess: [.red, .yellow, .green, .purple],
            secret: [.red, .green, .blue, .yellow]
        )

        // Advanced mode should have 1 correct, 2 misplaced, 1 wrong
        let correctCount = feedback.filter { $0 == .correct }.count
        let misplacedCount = feedback.filter { $0 == .misplaced }.count
        let wrongCount = feedback.filter { $0 == .wrong }.count

        XCTAssertEqual(correctCount, 1)
        XCTAssertEqual(misplacedCount, 2)
        XCTAssertEqual(wrongCount, 1)
    }

    func testGameModeProperty() {
        gameStateManager.state.mode = .advanced
        XCTAssertEqual(gameStateManager.gameMode, .solo)

        gameStateManager.state.mode = .beginner
        XCTAssertEqual(gameStateManager.gameMode, .dual)
    }

    func testStartNewGame() {
        // Set up some state
        gameStateManager.setColor(.red, at: 0)
        gameStateManager.isGameOver = true
        gameStateManager.message = "GAME OVER"

        // Start new game should reset everything
        gameStateManager.startNewGame()

        XCTAssertFalse(gameStateManager.isGameOver)
        XCTAssertEqual(gameStateManager.message, "READY")
        XCTAssertEqual(gameStateManager.activeIndex, 0)
        XCTAssertNil(gameStateManager.currentGuess[0])
        XCTAssertEqual(gameStateManager.state.attempts.count, 7)
    }

    func testLevelProgression() {
        let initialLevel = gameStateManager.state.level
        gameStateManager.startNextLevel()
        XCTAssertEqual(gameStateManager.state.level, initialLevel + 1)
    }

    func testRankCalculation() {
        gameStateManager.state.level = 3
        XCTAssertEqual(gameStateManager.currentRank, "RECRUIT")

        gameStateManager.state.level = 15
        XCTAssertEqual(gameStateManager.currentRank, "SPECIALIST")

        gameStateManager.state.level = 35
        XCTAssertEqual(gameStateManager.currentRank, "OPERATIVE")

        gameStateManager.state.level = 75
        XCTAssertEqual(gameStateManager.currentRank, "COMMANDER")

        gameStateManager.state.level = 250
        XCTAssertEqual(gameStateManager.currentRank, "ELITE")

        gameStateManager.state.level = 500
        XCTAssertEqual(gameStateManager.currentRank, "LEGENDARY")
    }
}