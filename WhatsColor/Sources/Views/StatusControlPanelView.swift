import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Status display
            StatusDisplayView(viewModel: viewModel)
                .frame(maxWidth: .infinity)

            // Controls row
            HStack(spacing: 15) {
                // Left: Difficulty selector
                DifficultySelectorView(viewModel: viewModel)

                Spacer()

                // Center: Submit knob
                SubmitKnobView(onTap: {
                    viewModel.submitGuess()
                })

                Spacer()

                // Right: Mode selector
                ModeSelectorView(viewModel: viewModel)
            }
            .padding(.horizontal, 5)
        }
        .padding(.horizontal, 20)
    }
}

struct StatusDisplayView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack {
            // Timer display - normal font style
            HStack(spacing: 4) {
                Text("\(viewModel.timeRemaining)")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.gameRed)
                    .shadow(color: .gameRed.opacity(0.5), radius: 4, x: 0, y: 0)
                    .frame(minWidth: 75, alignment: .leading)
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)

                Text("SEC")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gameRed.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )

            Spacer()

            // Message
            Text(viewModel.state.message)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

struct SubmitKnobView: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticMedium()
            onTap()
        }) {
            ZStack {
                // Outer shadow/depth layer - fixed, creates depth
                Circle()
                    .fill(Color(red: 0.65, green: 0.15, blue: 0.15))
                    .frame(width: 84, height: 84)

                // Inner circle - scales when pressed
                ZStack {
                    // Main button face
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.5, blue: 0.5),
                                    Color(red: 0.9, green: 0.35, blue: 0.35)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: Color(red: 0.5, green: 0.1, blue: 0.1).opacity(0.5),
                            radius: 4,
                            x: 0,
                            y: 2
                        )

                    // Highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.0)
                                ],
                                center: .top,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 76, height: 76)
                        .offset(y: -22)

                    // Marker
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 6, height: 18)
                            .cornerRadius(3)
                        Spacer()
                    }
                    .frame(width: 70, height: 70)
                    .offset(y: -10)
                }
                .scaleEffect(isPressed ? 0.92 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

struct DifficultySelectorView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 6) {
            SkeuomorphicButton(
                title: "EASY",
                isSelected: viewModel.state.difficulty == .easy,
                onTap: { viewModel.changeDifficulty(to: .easy) }
            )

            SkeuomorphicButton(
                title: "NORMAL",
                isSelected: viewModel.state.difficulty == .normal,
                onTap: { viewModel.changeDifficulty(to: .normal) }
            )

            SkeuomorphicButton(
                title: "HARD",
                isSelected: viewModel.state.difficulty == .hard,
                onTap: { viewModel.changeDifficulty(to: .hard) }
            )
        }
        .frame(minWidth: 80)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

struct ModeSelectorView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 6) {
            SkeuomorphicButton(
                title: "SOLO",
                isSelected: viewModel.state.mode == .advanced,
                onTap: { viewModel.changeMode(to: .advanced) }
            )

            SkeuomorphicButton(
                title: "DUAL",
                isSelected: viewModel.state.mode == .beginner,
                onTap: { viewModel.changeMode(to: .beginner) }
            )
        }
        .frame(minWidth: 80)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

struct SkeuomorphicButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticLight()
            onTap()
        }) {
            ZStack {
                // Bottom shadow layer (always visible, creates depth)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.6))
                    .offset(y: 2)

                // Main button face
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color(red: 0.4, green: 0.6, blue: 0.4), Color(red: 0.3, green: 0.5, blue: 0.3)] :
                                [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    )

                // Highlight on top half
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.15 : 0.1),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)

                // Text
                Text(title)
                    .font(.system(size: isSelected ? 14 : 13, weight: .bold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .frame(minWidth: 70)
            }
            .frame(height: 40)
            .offset(y: isPressed ? 2 : 0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
