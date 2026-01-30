import SwiftUI

import SwiftUI
import AudioToolbox

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.launchBackground
                    .ignoresSafeArea()

                // Main game device - centered
                DeviceView(viewModel: viewModel)
                    .frame(maxWidth: geometry.size.width > 400 ? 380 : geometry.size.width - 40)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 10)

                // Pause/Restart confirmation dialog
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
        VStack(spacing: 0) {
            // Top toolbar with reset button - aligned with game board
            HStack(alignment: .center) {
                ResetButtonView(onTap: {
                    viewModel.pauseGame()
                })
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Main device body
            VStack(spacing: 0) {
                // Antenna (visual decoration)
                Rectangle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 80, height: 30)
                    .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
                    .offset(y: 15)

                // Game board area
                GameBoardView(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 0)

                // Inline Color Picker
                HorizontalColorPickerView(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                // Bottom panel - status and knob only
                StatusControlPanelView(viewModel: viewModel)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
            }
            .background(Color.deviceGreen)
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.top, -30)
        }
    }
}

struct ResetButtonView: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticMedium()
            onTap()
        }) {
            HStack(spacing: 8) {
                // Reset icon
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))

                // Reset text label
                Text("RESET")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // Layered background
            .overlay(
                ZStack {
                    // Shadow layer at bottom
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.6))
                        .offset(y: 2)

                    // Button face
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.55),
                                    Color.gray.opacity(0.35)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Border
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)

                    // Highlight
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .padding(1)
                }
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

// MARK: - Settings Dialog

struct SettingsDialogView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedTime: Int = 60

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
                DialogButton(title: "NEXT: SET CODE", action: {
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
