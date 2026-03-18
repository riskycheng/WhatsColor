import XCTest
@testable import WhatsColor

@MainActor
class GameFlowManagerTests: XCTestCase {
    var gameFlowManager: GameFlowManager!

    override func setUp() {
        super.setUp()
        gameFlowManager = GameFlowManager()
    }

    override func tearDown() {
        gameFlowManager.cleanup()
        gameFlowManager = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(gameFlowManager.isShowingStartScreen)
        XCTAssertFalse(gameFlowManager.gameStarted)
        XCTAssertFalse(gameFlowManager.showPauseDialog)
        XCTAssertFalse(gameFlowManager.showSettingsDialog)
        XCTAssertFalse(gameFlowManager.showSecretCodeDialog)
        XCTAssertFalse(gameFlowManager.showGameOverDialog)
    }

    func testToastMessage() {
        let expectation = XCTestExpectation(description: "Toast should auto-dismiss")

        gameFlowManager.showToast("Test Message", type: .info)

        XCTAssertNotNil(gameFlowManager.toast)
        XCTAssertEqual(gameFlowManager.toast?.message, "Test Message")
        XCTAssertEqual(gameFlowManager.toast?.type, .info)

        // Toast should auto-dismiss after 2.2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertNil(self.gameFlowManager.toast)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testSecretCodeSelection() {
        gameFlowManager.startSecretCodeSelection()

        XCTAssertTrue(gameFlowManager.showSecretCodeDialog)
        XCTAssertEqual(gameFlowManager.selectedSecretCode.count, 0)
        XCTAssertEqual(gameFlowManager.currentSecretSlot, 0)

        // Add colors to secret code
        gameFlowManager.selectSecretColor(.red)
        gameFlowManager.selectSecretColor(.green)
        gameFlowManager.selectSecretColor(.blue)

        XCTAssertEqual(gameFlowManager.selectedSecretCode.count, 3)
        XCTAssertEqual(gameFlowManager.currentSecretSlot, 3)
        XCTAssertFalse(gameFlowManager.isSecretCodeComplete)

        // Complete the secret code
        gameFlowManager.selectSecretColor(.yellow)

        XCTAssertTrue(gameFlowManager.isSecretCodeComplete)
        XCTAssertEqual(gameFlowManager.selectedSecretCode.count, 4)
    }

    func testSecretCodeReset() {
        gameFlowManager.selectSecretColor(.red)
        gameFlowManager.selectSecretColor(.green)
        gameFlowManager.selectSecretColor(.blue)

        XCTAssertEqual(gameFlowManager.selectedSecretCode.count, 3)

        // Reset from index 1
        gameFlowManager.resetSecretCode(from: 1)

        XCTAssertEqual(gameFlowManager.selectedSecretCode.count, 1)
        XCTAssertEqual(gameFlowManager.selectedSecretCode[0], .red)
        XCTAssertEqual(gameFlowManager.currentSecretSlot, 1)
    }

    func testGameStartSolo() {
        var soloGameStarted = false

        gameFlowManager.onStartGameSolo = {
            soloGameStarted = true
        }

        gameFlowManager.startGame(mode: .solo)

        XCTAssertFalse(gameFlowManager.isShowingStartScreen)
        XCTAssertTrue(gameFlowManager.gameStarted)
        XCTAssertTrue(soloGameStarted)
    }

    func testGameStartDual() {
        gameFlowManager.startGame(mode: .dual)

        XCTAssertFalse(gameFlowManager.isShowingStartScreen)
        XCTAssertTrue(gameFlowManager.gameStarted)
        XCTAssertTrue(gameFlowManager.showSettingsDialog)
    }

    func testPauseResumeFlow() {
        var pauseCalled = false
        var resumeCalled = false

        gameFlowManager.onPauseGame = {
            pauseCalled = true
        }

        gameFlowManager.onResumeGame = {
            resumeCalled = true
        }

        gameFlowManager.pauseGame()
        XCTAssertTrue(gameFlowManager.showPauseDialog)
        XCTAssertTrue(pauseCalled)

        gameFlowManager.resumeGame()
        XCTAssertFalse(gameFlowManager.showPauseDialog)
        XCTAssertTrue(resumeCalled)
    }

    func testDialogDismissals() {
        gameFlowManager.showSettingsDialog = true
        gameFlowManager.dismissSettingsDialog()
        XCTAssertFalse(gameFlowManager.showSettingsDialog)
        XCTAssertTrue(gameFlowManager.showPauseDialog)

        gameFlowManager.showSecretCodeDialog = true
        gameFlowManager.cancelSecretCodeSelection()
        XCTAssertFalse(gameFlowManager.showSecretCodeDialog)
        XCTAssertTrue(gameFlowManager.showSettingsDialog)
    }

    func testRestartFlow() {
        var restartCalled = false

        gameFlowManager.onRestartGame = {
            restartCalled = true
        }

        gameFlowManager.gameStarted = true
        gameFlowManager.isShowingStartScreen = false

        gameFlowManager.confirmRestart()

        XCTAssertTrue(gameFlowManager.isShowingStartScreen)
        XCTAssertFalse(gameFlowManager.gameStarted)
        XCTAssertEqual(gameFlowManager.selectedSecretCode.count, 0)
        XCTAssertEqual(gameFlowManager.currentSecretSlot, 0)
        XCTAssertTrue(restartCalled)
    }

    func testCallbackCleanup() {
        // Set up callbacks
        gameFlowManager.onStartGameSolo = { }
        gameFlowManager.onStartGameDual = { }
        gameFlowManager.onApplySettings = { _ in }

        // Cleanup should nil all callbacks
        gameFlowManager.cleanup()

        XCTAssertNil(gameFlowManager.onStartGameSolo)
        XCTAssertNil(gameFlowManager.onStartGameDual)
        XCTAssertNil(gameFlowManager.onApplySettings)
    }
}