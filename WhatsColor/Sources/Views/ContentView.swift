import SwiftUI
import AudioToolbox

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color.launchBackground
                    .ignoresSafeArea()

                // Main game content
                ZStack(alignment: .top) {
                    // Peek-out Buttons - Only in mission mode
                    if !viewModel.isShowingStartScreen {
                        HStack {
                            // Left: Reset/Menu Button
                            ResetButtonView(viewModel: viewModel, onTap: {
                                viewModel.pauseGame()
                            })
                            .padding(.leading, 50)
                            #if DEBUG
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        viewModel.setDebugButtonState(position: .topLeft, pressed: true)
                                    }
                                    .onEnded { _ in
                                        viewModel.setDebugButtonState(position: .topLeft, pressed: false)
                                    }
                            )
                            #endif
                            
                            Spacer()
                            
                            // Right: Hint Button
                            ExternalHintButtonView(viewModel: viewModel)
                                .padding(.trailing, 50)
                                #if DEBUG
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            viewModel.setDebugButtonState(position: .topRight, pressed: true)
                                        }
                                        .onEnded { _ in
                                            viewModel.setDebugButtonState(position: .topRight, pressed: false)
                                        }
                                )
                                #endif
                        }
                        .offset(y: -12)
                    }

                    // Main Device Body Shell
                    Group {
                        if viewModel.isShowingStartScreen {
                            GameStartView(viewModel: viewModel)
                        } else {
                            DeviceView(viewModel: viewModel)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        ZStack {
                            Color.deviceGreen
                            
                            // Hardware Finish - Brushed look
                            LinearGradient(
                                colors: [.white.opacity(0.1), .clear, .black.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .cornerRadius(40)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .blur(radius: viewModel.showPauseDialog || viewModel.showGameOverDialog ? 15 : 0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showPauseDialog || viewModel.showGameOverDialog)
                    #if DEBUG
                    .overlay(
                        // Invisible debug button at top center
                        GeometryReader { geo in
                            Color.clear
                                .contentShape(Rectangle())
                                .frame(width: 100, height: 40)
                                .position(x: geo.size.width / 2, y: 20)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            viewModel.setDebugButtonState(position: .top, pressed: true)
                                        }
                                        .onEnded { _ in
                                            viewModel.setDebugButtonState(position: .top, pressed: false)
                                        }
                                )
                        }
                    )
                    #endif
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14) // Standard handheld outer margin
                .frame(maxHeight: .infinity)
                .padding(.top, 12)
                .padding(.bottom, viewModel.isShowingStartScreen ? 20 : 60) // Less padding on start screen
                
                // EXTERNAL SYSTEM STATUS BAR - Only shown during mission, hidden on start screen
                if !viewModel.isShowingStartScreen {
                    VStack {
                        Spacer()
                        SystemStatusBar(viewModel: viewModel)
                            .padding(.horizontal, 45) // Match standard recessed width
                            .frame(height: 50)
                    }
                    .ignoresSafeArea(.keyboard)
                }
                
                // Dialog overlays...
                if viewModel.showPauseDialog {
                    PauseDialogView(viewModel: viewModel)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showPauseDialog)
                }

                // Settings dialog for time limit selection
                if viewModel.showSettingsDialog {
                    SettingsDialogView(viewModel: viewModel)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showSettingsDialog)
                }

                // How to Play dialog
                if viewModel.showHowToPlay {
                    HowToPlayView(viewModel: viewModel)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showHowToPlay)
                }

                // Secret code selection dialog
                if viewModel.showSecretCodeDialog {
                    SecretCodeSelectionView(viewModel: viewModel)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showSecretCodeDialog)
                }

                // Game Over Dialog
                if viewModel.showGameOverDialog {
                    GameOverDialogView(viewModel: viewModel)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showGameOverDialog)
                }

                // Manual Drag Overlay - instant response, no plus badge, finger-offset
                if let dragColor = viewModel.activeDragColor {
                    ZStack {
                        if let icon = viewModel.state.theme.image(for: dragColor) {
                            icon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 55, height: 55)
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                        } else {
                            Circle()
                                .fill(dragColor.color)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 2.5)
                                .frame(width: 68, height: 68)
                        }
                    }
                    .position(x: viewModel.dragPosition.x, y: viewModel.dragPosition.y)
                    .transition(.scale.combined(with: .opacity))
                    .ignoresSafeArea()
                    .allowsHitTesting(false) // CRITICAL: Stop overlay from stealing drag events
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct DeviceView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)
            
            // Game board area - height adjusted to match GameStartView
            GameBoardView(viewModel: viewModel)
                .padding(.horizontal, 16)
                .frame(height: 500)

            // Larger spacer above to push color picker slightly upward
            Spacer()

            // Inline Color Picker - centered in available space
            HorizontalColorPickerView(viewModel: viewModel)
                .padding(.horizontal, 16)

            // Smaller spacer below to fine-tune centering
            Spacer()
            Spacer()

            // Bottom panel - status and knob
            StatusControlPanelView(viewModel: viewModel)
                .padding(.horizontal, 16)
                .frame(height: 140)
            
            Spacer(minLength: 10)
        }
    }
}

struct SystemStatusBar: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var pulseOpacity = 0.4
    
    var body: some View {
        ZStack {
            // External Chassis Cutout (Darker/Sleeker)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
                .shadow(color: .white.opacity(0.03), radius: 0.5, x: 0, y: 1)
            
            HStack(spacing: 12) {
                // System Status Indicator (Pulsing LED)
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: statusColor.opacity(0.8), radius: 4)
                    .opacity(pulseOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulseOpacity = 1.0
                        }
                    }
                
                // Console Line Text
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        if let toast = viewModel.toast {
                            HStack(spacing: 8) {
                                Image(systemName: toastIcon(for: toast.type))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(statusColor)
                                
                                // Show hint icon if this is a hint toast with a color
                                if let hintColor = toast.hintColor {
                                    if let icon = viewModel.state.theme.image(for: hintColor) {
                                        icon
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 18, height: 18)
                                    } else {
                                        Circle()
                                            .fill(hintColor.color)
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                }
                                
                                Text(toast.message)
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .tracking(1.5)
                                    .foregroundColor(statusColor)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                // Animated binary-style progress/activity
                                HStack(spacing: 3) {
                                    ForEach(0..<6) { _ in
                                        Rectangle()
                                            .fill(statusColor)
                                            .frame(width: 1.5, height: 8)
                                            .opacity(Double.random(in: 0.3...1.0))
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        } else {
                            HStack {
                                Text("SYSTEM: NOMINAL")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .tracking(2.5)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Spacer()
                                
                                // Internal system timer/clock simulation
                                Text("LOG_B\(Int(viewModel.timeRemaining))")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .transition(.opacity)
                        }
                    }
                    .id(viewModel.toast?.message ?? "standing_by")
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 34)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.toast)
    }
    
    private func toastIcon(for type: GameViewModel.ToastType) -> String {
        switch type {
        case .info: return "chevron.right"
        case .success: return "checkmark.diamond.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .error: return "bolt.horizontal.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if let toast = viewModel.toast {
            switch toast.type {
            case .info: return .white
            case .success: return .gameGreen
            case .warning: return .orange
            case .error: return .gameRed
            }
        }
        return .white.opacity(0.15)
    }
}

struct ResetButtonView: View {
    @ObservedObject var viewModel: GameViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            // Don't trigger action if debug mode is active (both buttons pressed)
            guard !viewModel.isDebugModeActive else { return }
            
            // Enhanced mechanical feedback - click sound + medium haptic
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticMedium()
            onTap()
        }) {
            // Large metallic/Hardware tab with icon - MUCH LARGER for visibility
            ZStack {
                // Base structure with metallic gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.2), location: 0),
                                .init(color: Color(white: 0.32), location: 0.45),
                                .init(color: Color(white: 0.25), location: 0.55),
                                .init(color: Color(white: 0.15), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Top bevel highlight
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 2
                    )
                
                // Menu icon - MUCH LARGER
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 90, height: 80)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PressedButtonStyle())
    }
}

// MARK: - External Hint Button (Top Right)

struct ExternalHintButtonView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        Button(action: {
            // Don't trigger action if debug mode is active (both buttons pressed)
            guard !viewModel.isDebugModeActive else { return }
            guard !viewModel.state.isGameOver else { return }
            
            // Enhanced mechanical feedback - click sound + medium haptic
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticMedium()
            
            if let hint = HintManager.shared.useHint(
                secretCode: viewModel.state.secretCode,
                currentGuess: viewModel.state.currentGuess,
                attempts: viewModel.state.attempts
            ) {
                viewModel.showToast(hint.description(for: viewModel.state.theme), type: .info, hintColor: hint.color)
            } else if !HintManager.shared.hasHintsAvailable {
                viewModel.showToast("NO HINTS REMAINING", type: .warning)
                SoundManager.shared.playError()
            }
        }) {
            // Large metallic/Hardware tab with hint icon and square indicators
            ZStack {
                // Base structure with metallic gradient - hint themed
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.22), location: 0),
                                .init(color: Color(white: 0.35), location: 0.45),
                                .init(color: Color(white: 0.28), location: 0.55),
                                .init(color: Color(white: 0.18), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Inner glow effect when hints available
                if HintManager.shared.hasHintsAvailable {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gameYellow.opacity(0.5), lineWidth: 2.5)
                }
                
                // Top bevel highlight - yellow tint when hints available
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: HintManager.shared.hasHintsAvailable ? 
                                [.gameYellow.opacity(0.8), .clear] :
                                [.white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 2
                    )
                
                // Content: Lightbulb icon with glow effect
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(HintManager.shared.hasHintsAvailable ? .gameYellow : .white.opacity(0.4))
                    .shadow(color: HintManager.shared.hasHintsAvailable ? .gameYellow.opacity(0.8) : .clear, radius: 6)
            }
            .frame(width: 90, height: 80)
            .shadow(
                color: HintManager.shared.hasHintsAvailable ? .gameYellow.opacity(0.4) : .black.opacity(0.5),
                radius: 5,
                x: 0,
                y: 3
            )
        }
        .buttonStyle(PressedButtonStyle())
        .disabled(viewModel.state.isGameOver)
        .opacity(viewModel.state.isGameOver ? 0.5 : 1.0)
        #if DEBUG
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    viewModel.setDebugButtonState(position: .topRight, pressed: true)
                }
                .onEnded { _ in
                    viewModel.setDebugButtonState(position: .topRight, pressed: false)
                }
        )
        #endif
    }
}

// Custom button style for a realistic "click" depress effect
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 1 : 0) // Visual depress
            .brightness(configuration.isPressed ? -0.05 : 0) // Slight darkening on press
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Pause Dialog

struct PauseDialogView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            // Semi-transparent overlay - dismiss on tap outside dialog
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.resumeGame()
                }

            // Dialog content
            VStack(spacing: 20) {
                Text("PAUSED")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, 20)

                Text("Restart game?")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray.opacity(0.9))

                // Buttons
                VStack(spacing: 12) {
                    DialogButton(title: "RESUME", action: {
                        viewModel.resumeGame()
                    })

                    DialogButton(title: "RESTART", action: {
                        viewModel.confirmRestart()
                        viewModel.startGame() // Immediately start a new game with current settings
                    })

                    DialogButton(title: "MAIN MENU", action: {
                        viewModel.confirmRestart() // This sets isShowingStartScreen = true
                    })
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                    )
            )
            .frame(width: 300)
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            .offset(y: -40) // Move dialog a little bit upper
        }
    }
}

struct DialogButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 0.4),
                                    Color(red: 0.3, green: 0.5, blue: 0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .offset(y: isPressed ? 2 : 0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Game Over Dialog

struct GameOverDialogView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var appearScale: CGFloat = 0.85
    @State private var appearOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.5

    var body: some View {
        let isWin = viewModel.state.message.contains("SUCCESS") || viewModel.state.message.contains("UNLOCKED")
        
        ZStack {
            // Deep backdrop with animated glow for success
            Color.black.opacity(0.88)
                .ignoresSafeArea()
            
            if isWin {
                // Animated success glow
                RadialGradient(
                    colors: [
                        Color.gameGreen.opacity(0.15 * glowOpacity),
                        Color.gameGreen.opacity(0.05 * glowOpacity),
                        .clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
                .ignoresSafeArea()
                .blur(radius: 20)
            }

            // Centered compact content
            VStack(spacing: 18) {
                // Header with icon
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(isWin ? Color.gameGreen.opacity(0.3) : Color.gameRed.opacity(0.2), lineWidth: 1)
                            .frame(width: 68, height: 68)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isWin ? 
                                        [Color.gameGreen.opacity(0.18), Color.gameGreen.opacity(0.06)] :
                                        [Color.gameRed.opacity(0.15), Color.gameRed.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: isWin ? "checkmark.seal.fill" : "xmark.octagon.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(isWin ? .gameGreen : .gameRed)
                    }
                    
                    VStack(spacing: 4) {
                        Text(viewModel.state.message)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(isWin ? .gameGreen : .gameRed)
                            .tracking(2)
                        
                        Text(isWin ? "SEQUENCE DECRYPTED" : "ACCESS DENIED")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                    }
                }

                // Stats row
                HStack(spacing: 0) {
                    StatItem(label: "MISSION", value: viewModel.currentLevelString)
                    Divider().background(Color.white.opacity(0.1)).frame(height: 28)
                    StatItem(label: "TIME", value: "\(viewModel.timeRemaining)s")
                    Divider().background(Color.white.opacity(0.1)).frame(height: 28)
                    StatItem(label: "ATTEMPTS", value: "\(viewModel.state.attempts.filter { $0.isComplete }.count)/7")
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
                .padding(.horizontal, 20)

                // Secret code
                if viewModel.gameMode == .dual || (isWin && viewModel.gameMode == .solo) {
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { index in
                            let color = viewModel.state.secretCode[index]
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 48, height: 48)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isWin ? Color.gameGreen.opacity(0.25) : Color.white.opacity(0.1), lineWidth: 1))
                                
                                if let icon = viewModel.state.theme.image(for: color) {
                                    icon.resizable().aspectRatio(contentMode: .fit).frame(width: 34, height: 34)
                                } else {
                                    Circle().fill(color.color).frame(width: 28, height: 28)
                                }
                            }
                        }
                    }
                }

                // Buttons
                VStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.showGameOverDialog = false
                            if viewModel.gameMode == .solo {
                                viewModel.timeRemaining = viewModel.state.difficulty.baseTime
                                viewModel.startNewGame()
                            } else {
                                viewModel.confirmRestart()
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isWin ? "arrow.right" : "arrow.counterclockwise")
                                .font(.system(size: 14))
                            Text(isWin ? "NEXT MISSION" : "RETRY")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isWin ? Color.gameGreen.opacity(0.8) : Color(white: 0.3))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        viewModel.showGameOverDialog = false
                        viewModel.isShowingStartScreen = true
                        viewModel.gameStarted = false
                        // Reset time to difficulty's base time when returning to base
                        viewModel.timeRemaining = viewModel.state.difficulty.baseTime
                    }) {
                        Text("RETURN TO BASE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 28)
            .background(
                ZStack {
                    // Main background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.14), Color(white: 0.09)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Subtle border glow for success
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            isWin ?
                            LinearGradient(
                                colors: [
                                    Color.gameGreen.opacity(0.4),
                                    Color.gameGreen.opacity(0.1),
                                    Color.gameGreen.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gameRed.opacity(0.2), Color.gameRed.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: isWin ? 1.5 : 1
                        )
                }
            )
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
            .padding(.horizontal, 35)
        }
        .onAppear {
            // Staggered animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                iconScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 1.0
            }
        }
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings Dialog

struct SettingsDialogView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedTime: Int

    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        self._selectedTime = State(initialValue: viewModel.timeRemaining)
    }

    var body: some View {
        ZStack {
            // Semi-transparent overlay - dismiss on tap
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissSettingsDialog()
                }

            // Dialog content
            VStack(spacing: 0) {
                Text("SET TIME LIMIT")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 25)
                    .padding(.bottom, 10)

                // Professional iOS-style vertical time picker ruler
                TimeWheelPicker(selectedTime: $selectedTime)
                    .padding(.horizontal, 10)

                // Start button
                DialogButton(title: viewModel.gameMode == .dual ? "NEXT: SET CODE" : "START MISSION", action: {
                    viewModel.timeRemaining = selectedTime
                    viewModel.applySettingsAndRestart(timeLimit: selectedTime)
                })
                .padding(.horizontal, 40)
                .padding(.vertical, 25)
            }
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.15), Color(white: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                    )
            )
            .frame(width: 350)
            .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 15)
        }
    }
}

// Helper extension for specific corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ScrewHeadSmall: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(white: 0.4), Color(white: 0.15)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 4
                )
            )
            .frame(width: 8, height: 8)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 6, height: 1.5)
                    .rotationEffect(.degrees(45))
            )
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
}

// MARK: - How To Play View

struct HowToPlayView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    SoundManager.shared.playSelection()
                    viewModel.showHowToPlay = false
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("MISSION BRIEFING")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Spacer()
                    
                    Button(action: {
                        SoundManager.shared.playSelection()
                        viewModel.showHowToPlay = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Objective
                        HStack(spacing: 10) {
                            Image(systemName: "target")
                                .font(.system(size: 18))
                                .foregroundColor(.gameGreen)
                            
                            Text("Decode the secret 4-color sequence. You have 7 attempts to crack the code.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        // Game Modes
                        HStack(spacing: 12) {
                            ModeCard(
                                title: "SOLO",
                                icon: "person.fill",
                                description: "Play against AI.\nProgress through levels.",
                                color: .gameGreen
                            )
                            
                            ModeCard(
                                title: "DUAL",
                                icon: "person.2.fill",
                                description: "Two players.\nOne sets, one guesses.",
                                color: .blue
                            )
                        }
                        
                        // Feedback System - using generic terms for multi-theme support
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gameGreen)
                                Text("FEEDBACK")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(1)
                            }
                            
                            // Using generic terms (item/symbol) to support all themes
                            HStack(spacing: 0) {
                                FeedbackItem(
                                    color: .gameGreen,
                                    label: "GREEN",
                                    line1: "Correct item",
                                    line2: "& position"
                                )
                                
                                FeedbackItem(
                                    color: .white,
                                    label: "WHITE",
                                    line1: "Correct item,",
                                    line2: "wrong position"
                                )
                                
                                FeedbackItem(
                                    color: .clear,
                                    label: "NONE",
                                    line1: "Item not",
                                    line2: "in code"
                                )
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.03))
                        )
                        
                        // Difficulty Modes - 无时间显示，更详细描述
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "gauge.with.dots.needle.67percent")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gameGreen)
                                Text("DIFFICULTY")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(1)
                            }
                            
                            VStack(spacing: 6) {
                                DifficultyDescRow(
                                    title: "EASY",
                                    desc: "Limited palette with position hints",
                                    color: .gameGreen
                                )
                                
                                DifficultyDescRow(
                                    title: "NORMAL",
                                    desc: "Full palette with position hints",
                                    color: .yellow
                                )
                                
                                DifficultyDescRow(
                                    title: "HARD",
                                    desc: "Full palette with count-only hints",
                                    color: .gameRed
                                )
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.03))
                        )
                        
                        // Controls - 双栏布局，无图标，单行
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gameGreen)
                                Text("CONTROLS")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(1)
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                // Rotary Controller Block
                                VStack(alignment: .leading, spacing: 0) {
                                    // Header with fixed height for alignment
                                    HStack(spacing: 6) {
                                        MiniRotaryIcon()
                                        
                                        Text("DIAL")
                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(height: 24)
                                    .padding(.bottom, 8)
                                    
                                    // Content lines with fixed height for alignment
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("• Tap: Advance slot")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.75))
                                            .frame(height: 18, alignment: .leading)
                                        Text("• Hold: Submit guess")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.75))
                                            .frame(height: 18, alignment: .leading)
                                        Text("• Drag edge: Rotate")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.75))
                                            .frame(height: 18, alignment: .leading)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.2))
                                )
                                
                                // Color Cell Block
                                VStack(alignment: .leading, spacing: 0) {
                                    // Header with fixed height for alignment
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.grid.2x2")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gameGreen.opacity(0.8))
                                            .frame(width: 24, height: 24)
                                        
                                        Text("CELLS")
                                            .font(.system(size: 10, weight: .black, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(height: 24)
                                    .padding(.bottom, 8)
                                    
                                    // Content lines with fixed height for alignment
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("• Tap: Select item")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.75))
                                            .frame(height: 18, alignment: .leading)
                                        Text("• Drag: Swap slots")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.75))
                                            .frame(height: 18, alignment: .leading)
                                        Text("• Hold: Lock/unlock")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.75))
                                            .frame(height: 18, alignment: .leading)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.2))
                                )
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.03))
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.12), Color(white: 0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(16)
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        if value.translation.height > 100 || value.velocity.height > 500 {
                            // Close if dragged down more than 100pt or with high velocity
                            withAnimation(.easeOut(duration: 0.2)) {
                                SoundManager.shared.playSelection()
                                viewModel.showHowToPlay = false
                            }
                        } else {
                            // Spring back to original position
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
    }
}

struct ModeCard: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(color)
            
            Text(description)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct FeedbackItem: View {
    let color: Color
    let label: String
    let line1: String
    let line2: String
    
    var body: some View {
        VStack(spacing: 8) {
            // 固定高度的circle容器
            ZStack {
                Circle()
                    .fill(color == .clear ? Color.white.opacity(0.12) : color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
            .frame(height: 24)
            
            Text(label)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            // 固定高度的文本区域
            VStack(spacing: 1) {
                Text(line1)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Text(line2)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DifficultyDescRow: View {
    let title: String
    let desc: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 55, alignment: .leading)
            
            Text(desc)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct MiniRotaryIcon: View {
    var body: some View {
        ZStack {
            // Outer housing
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.22), Color(white: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.1), .black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 0.5
                        )
                )
            
            // Bezel with ticks
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.35), Color(white: 0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 20)
                
                // Ticks
                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(Color.black.opacity(i % 3 == 0 ? 0.6 : 0.3))
                        .frame(width: i % 3 == 0 ? 0.6 : 0.3, height: i % 3 == 0 ? 2.5 : 1.5)
                        .offset(y: -8)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
            
            // Inner plate
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.08), .black.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 0.5
                        )
                )
            
            // Central LED
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 4, height: 4)
                
                Circle()
                    .fill(Color.gameGreen)
                    .frame(width: 2, height: 2)
                    .shadow(color: .gameGreen.opacity(0.8), radius: 2)
            }
        }
    }
}
