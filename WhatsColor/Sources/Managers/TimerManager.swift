import Foundation
import Combine

/// Manages timer functionality with optimized state updates
@MainActor
class TimerManager: ObservableObject {
    @Published var timeRemaining: Int = 60
    @Published var isTimerActive: Bool = false

    private var timer: Timer?
    private var onTimeExpired: (() -> Void)?

    init(initialTime: Int = 60) {
        self.timeRemaining = initialTime
    }

    func setTimeExpiredCallback(_ callback: @escaping () -> Void) {
        onTimeExpired = callback
    }

    func startTimer() {
        stopTimer()
        isTimerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickTimer()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerActive = false
    }

    private func tickTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            stopTimer()
            onTimeExpired?()
        }
    }

    func setTimeLimit(seconds: Int) {
        timeRemaining = seconds
    }

    var timerDisplay: String {
        String(format: "%03d", timeRemaining)
    }

    deinit {
        // Clean up timer from deinit (cannot call async methods from deinit)
        timer?.invalidate()
        timer = nil
    }
}