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
                Group {
                    if viewModel.isShowingStartScreen {
                        GameStartView(viewModel: viewModel)
                    } else {
                        DeviceView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: geometry.size.width > 400 ? 380 : geometry.size.width - 40)
                .padding(.top, 12)
                .padding(.bottom, 15) // Reduced from 30 to move device down
                
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

                // Toast Message
                if let toast = viewModel.toastMessage {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.8))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: viewModel.toastMessage)
                }

                // Manual Drag Overlay - instant response, no plus badge, finger-offset
                if let dragColor = viewModel.activeDragColor {
                    ZStack {
                        Circle()
                            .fill(dragColor.color)
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 2.5)
                            .frame(width: 68, height: 68)
                    }
                    .position(x: viewModel.dragPosition.x, y: viewModel.dragPosition.y)
                    .transition(.scale.combined(with: .opacity))
                    .ignoresSafeArea()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct DeviceView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack(alignment: .top) {
            // External "Stitched" Reset Button - Peeking from the back
            HStack {
                ResetButtonView(onTap: {
                    viewModel.pauseGame()
                })
                .padding(.leading, 45) // Better alignment with the corner curve
                Spacer()
            }
            .offset(y: -14) // Adjusted for the larger button height

            // Main device body
            VStack(spacing: 0) {
                Spacer(minLength: 20) // Tightened top
                
                // Game board area
                GameBoardView(viewModel: viewModel)
                    .padding(.horizontal, 16)

                Spacer(minLength: 12)

                // Inline Color Picker
                HorizontalColorPickerView(viewModel: viewModel)
                    .padding(.horizontal, 16)

                Spacer(minLength: 12)

                // Bottom panel - status and knob only
                StatusControlPanelView(viewModel: viewModel)
                
                Spacer(minLength: 15) // Standardized bottom internal spacer
            }
            .background(Color.deviceGreen)
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
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

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 25) {
                Text(viewModel.state.message)
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(viewModel.state.message.contains("UNLOCKED") ? .gameGreen : .gameRed)
                    .shadow(color: (viewModel.state.message.contains("UNLOCKED") ? Color.gameGreen : Color.gameRed).opacity(0.5), radius: 10)

                VStack(spacing: 8) {
                    Text("MISSION RESULTS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    
                    HStack(spacing: 20) {
                        ResultStatView(label: "LEVEL", value: viewModel.currentLevelString)
                        ResultStatView(label: "TIME", value: "\(viewModel.timeRemaining)s")
                    }
                }
                .padding(.vertical, 10)

                VStack(spacing: 12) {
                    DialogButton(title: "PLAY AGAIN", action: {
                        viewModel.showGameOverDialog = false
                        viewModel.confirmRestart()
                    })

                    DialogButton(title: "MAIN MENU", action: {
                        viewModel.showGameOverDialog = false
                        viewModel.isShowingStartScreen = true
                        viewModel.gameStarted = false
                    })
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)
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

#Preview {
    ContentView()
}
