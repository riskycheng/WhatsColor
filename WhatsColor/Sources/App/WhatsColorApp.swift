import SwiftUI

@main
struct WhatsColorApp: App {
    @StateObject private var gameStateManager = GameStateManager()
    @StateObject private var gameFlowManager = GameFlowManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var dragDropCoordinator = DragDropCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameStateManager)
                .environmentObject(gameFlowManager)
                .environmentObject(themeManager)
                .environmentObject(timerManager)
                .environmentObject(dragDropCoordinator)
        }
    }
}
