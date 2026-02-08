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
                    // Peek-out Button (External Reset) - Only in mission mode
                    if !viewModel.isShowingStartScreen {
                        HStack {
                            ResetButtonView(onTap: {
                                viewModel.pauseGame()
                            })
                            .padding(.leading, 45)
                            Spacer()
                        }
                        .offset(y: -14)
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
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14) // Standard handheld outer margin
                .frame(maxHeight: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 60) // Slightly more space for the external bar
                
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
            Spacer(minLength: 12) // Slightly tighter top
            
            // Game board area
            GameBoardView(viewModel: viewModel)
                .padding(.horizontal, 16)

            Spacer(minLength: 12)

            // Inline Color Picker
            HorizontalColorPickerView(viewModel: viewModel)
                .padding(.horizontal, 16)

            Spacer()

            // Bottom panel - status and knob
            StatusControlPanelView(viewModel: viewModel)
                .padding(.horizontal, 16)
            
            Spacer(minLength: 25) // Standardized internal gap from the shell bottom
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
                                
                                Text(toast.message)
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .tracking(1.5)
                                    .foregroundColor(statusColor)
                                
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
                                    .foregroundColor(.white.opacity(0.12))
                                
                                Spacer()
                                
                                // Internal system timer/clock simulation
                                Text("LOG_B\(Int(viewModel.timeRemaining))")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.08))
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
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            // Mechanical feedback - Standard selection click + Medium impact
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticMedium()
            onTap()
        }) {
            // Squared metallic/Hardware tab with realistic lighting
            ZStack {
                // Base structure with metallic gradient - NO RADIUS
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.15), location: 0),
                                .init(color: Color(white: 0.25), location: 0.45),
                                .init(color: Color(white: 0.20), location: 0.55),
                                .init(color: Color(white: 0.12), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Top bevel highlight (specular hit)
                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1.5
                    )
                
                // Fine industrial texture/noise layer (subtle stroke)
                Rectangle()
                    .stroke(Color.black.opacity(0.4), lineWidth: 0.5)
            }
            .frame(width: 85, height: 28)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PressedButtonStyle()) // Custom style for tactile press feel
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
    @State private var appearScale: CGFloat = 0.8
    @State private var appearOpacity: Double = 0
    @State private var rotateShield: Double = 0

    var body: some View {
        let isWin = viewModel.state.message.contains("SUCCESS") || viewModel.state.message.contains("UNLOCKED")
        
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .blur(radius: 10)

            VStack(spacing: 0) {
                // Header Status Section
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(isWin ? Color.gameGreen.opacity(0.1) : Color.gameRed.opacity(0.1))
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        Image(systemName: isWin ? "shield.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(isWin ? .gameGreen : .gameRed)
                            .rotationEffect(.degrees(rotateShield))
                            .shadow(color: (isWin ? Color.gameGreen : Color.gameRed).opacity(0.6), radius: 15)
                        
                        Text(viewModel.state.message)
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundColor(isWin ? .gameGreen : .gameRed)
                            .tracking(2)
                    }
                }
                .padding(.top, 10)

                VStack(spacing: 25) {
                    // Mission Stats Bay
                    HStack(spacing: 30) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MISSION_ID")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                            Text(viewModel.currentLevelString)
                                .font(.system(size: 22, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TIME_ELAPSED")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                            Text("\(viewModel.timeRemaining)s")
                                .font(.system(size: 22, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(15)

                    // Reveal sequence only in Dual mode or on a Solo Success (to confirm decode)
                    if viewModel.gameMode == .dual || (isWin && viewModel.gameMode == .solo) {
                        VStack(spacing: 12) {
                            Text("DECODED_SEQUENCE")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.25))
                                .tracking(1)
                            
                            HStack(spacing: 15) {
                                ForEach(0..<4, id: \.self) { index in
                                    let color = viewModel.state.secretCode[index]
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 44, height: 44)
                                        
                                        if let icon = viewModel.state.theme.image(for: color) {
                                            icon.resizable().aspectRatio(contentMode: .fit).frame(width: 32, height: 32)
                                        } else {
                                            Circle().fill(color.color).frame(width: 28, height: 28)
                                        }
                                    }
                                    .overlay(Circle().stroke(isWin ? Color.gameGreen.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1.5))
                                }
                            }
                        }
                        .padding(.bottom, 5)
                    }

                    // Command Actions
                    VStack(spacing: 15) {
                        DialogButton(title: isWin ? "NEXT MISSION" : "RETRY_SEQUENCE", action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                viewModel.showGameOverDialog = false
                                if viewModel.gameMode == .solo {
                                    // In Solo mode, we either advance or retry the fixed sequence
                                    viewModel.timeRemaining = viewModel.state.difficulty.baseTime
                                    viewModel.startNewGame()
                                } else {
                                    // In Dual mode, return to configuration setup
                                    viewModel.confirmRestart()
                                }
                            }
                        })
                        .background(isWin ? Color.gameGreen.opacity(0.1) : Color.clear)
                        .cornerRadius(12)

                        Button(action: {
                            viewModel.showGameOverDialog = false
                            viewModel.isShowingStartScreen = true
                            viewModel.gameStarted = false
                        }) {
                            Text("RETURN_TO_BASE")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 5)
                        }
                    }
                }
                .padding(30)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(LinearGradient(colors: [Color(white: 0.12), Color(white: 0.08)], startPoint: .top, endPoint: .bottom))
                    
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(isWin ? Color.gameGreen.opacity(0.3) : Color.gameRed.opacity(0.3), lineWidth: 2)
                }
            )
            .scaleEffect(appearScale)
            .opacity(appearOpacity)
            .padding(.horizontal, 30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                rotateShield = isWin ? 5 : -5
            }
        }
    }
}

struct ResultStatView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
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
