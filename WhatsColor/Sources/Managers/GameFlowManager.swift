import Foundation
import SwiftUI
import Combine

/// Manages game flow, dialog states, and navigation
@MainActor
class GameFlowManager: ObservableObject {
    // Dialog states
    @Published var showPauseDialog: Bool = false
    @Published var showSettingsDialog: Bool = false
    @Published var showSecretCodeDialog: Bool = false
    @Published var showGameOverDialog: Bool = false

    // Game flow state
    @Published var isShowingStartScreen: Bool = true
    @Published var gameStarted: Bool = false

    // Secret code selection state
    @Published var selectedSecretCode: [GameColor] = []
    @Published var currentSecretSlot: Int = 0

    // Toast/Message state
    struct ToastInfo: Equatable {
        let message: String
        let type: ToastType
    }

    enum ToastType {
        case info, success, warning, error
    }

    @Published var toast: ToastInfo? = nil
    private var toastTimer: Timer?

    // Callbacks for external coordination
    var onStartGameSolo: (() -> Void)?
    var onStartGameDual: (() -> Void)?
    var onApplySettings: ((Int) -> Void)? // time limit
    var onSecretCodeReady: (([GameColor]) -> Void)?
    var onResumeGame: (() -> Void)?
    var onPauseGame: (() -> Void)?
    var onRestartGame: (() -> Void)?

    init() {
        gameStarted = false
        isShowingStartScreen = true
    }

    // MARK: - Toast Management

    func showToast(_ message: String, type: ToastType = .info) {
        toast = ToastInfo(message: message, type: type)
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
            Task { @MainActor in
                withAnimation {
                    self?.toast = nil
                }
            }
        }
    }

    // MARK: - Game Start Flow

    func startGame(mode: GameMode) {
        if mode == .dual {
            // DUAL mode: full pipeline (Time -> Color -> Play)
            showSettingsDialog = true
            isShowingStartScreen = false
            gameStarted = true
        } else {
            // SOLO mode: Skip dialogs, use predefined mission parameters
            isShowingStartScreen = false
            gameStarted = true
            onStartGameSolo?()
        }
    }

    func applySettingsAndRestart(timeLimit: Int) {
        showSettingsDialog = false
        // This is only called in DUAL mode now, so proceed to secret code setup
        onApplySettings?(timeLimit)
        startSecretCodeSelection()
    }

    func dismissSettingsDialog() {
        // Dismiss settings and go back to paused state
        showSettingsDialog = false
        showPauseDialog = true
    }

    // MARK: - Secret Code Selection Flow

    func startSecretCodeSelection() {
        showSettingsDialog = false
        showSecretCodeDialog = true
        selectedSecretCode = []
        currentSecretSlot = 0
    }

    func selectSecretColor(_ color: GameColor) {
        guard currentSecretSlot < 4 else { return }
        selectedSecretCode.append(color)
        currentSecretSlot += 1
    }

    func resetSecretCode(from index: Int) {
        guard index < selectedSecretCode.count else { return }
        selectedSecretCode.removeSubrange(index..<selectedSecretCode.count)
        currentSecretSlot = selectedSecretCode.count
    }

    func finishSecretCodeSelection() {
        guard selectedSecretCode.count == 4 else { return }
        showSecretCodeDialog = false
        gameStarted = true  // Mark game as started
        onSecretCodeReady?(selectedSecretCode)
    }

    func cancelSecretCodeSelection() {
        showSecretCodeDialog = false
        showSettingsDialog = true
        selectedSecretCode = []
        currentSecretSlot = 0
    }

    func dismissSecretCodeSelection() {
        // Dismiss without going back to settings - just cancel and restart
        showSecretCodeDialog = false
        selectedSecretCode = []
        currentSecretSlot = 0
        gameStarted = true  // Mark game as started
        onStartGameDual?()
    }

    var isSecretCodeComplete: Bool {
        selectedSecretCode.count == 4
    }

    // MARK: - Game Pause/Resume Flow

    func pauseGame() {
        onPauseGame?()
        showPauseDialog = true
    }

    func resumeGame() {
        showPauseDialog = false
        onResumeGame?()
    }

    func confirmRestart() {
        showPauseDialog = false
        isShowingStartScreen = true
        gameStarted = false
        selectedSecretCode = []
        currentSecretSlot = 0
        onRestartGame?()
    }

    // MARK: - Game Over Flow

    func showGameOver() {
        showGameOverDialog = true
    }

    func dismissGameOver() {
        showGameOverDialog = false
    }

    func startNextLevel() {
        showGameOverDialog = false
        // Delegate to external handler
    }

    func returnToStart() {
        showGameOverDialog = false
        isShowingStartScreen = true
        gameStarted = false
        selectedSecretCode = []
        currentSecretSlot = 0
    }

    enum GameMode {
        case solo
        case dual
    }

    // MARK: - Cleanup

    func cleanup() {
        onStartGameSolo = nil
        onStartGameDual = nil
        onApplySettings = nil
        onSecretCodeReady = nil
        onResumeGame = nil
        onPauseGame = nil
        onRestartGame = nil
        toastTimer?.invalidate()
        toastTimer = nil
    }

    deinit {
        // Clean up directly to avoid async calls from deinit
        onStartGameSolo = nil
        onStartGameDual = nil
        onApplySettings = nil
        onSecretCodeReady = nil
        onResumeGame = nil
        onPauseGame = nil
        onRestartGame = nil
        toastTimer?.invalidate()
    }
}