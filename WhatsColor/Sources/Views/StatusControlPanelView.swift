import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Range indicator
            RangeIndicatorView()
                .frame(maxWidth: .infinity)

            // Status display
            StatusDisplayView(viewModel: viewModel)
                .frame(maxWidth: .infinity)

            // Controls row
            HStack(spacing: 20) {
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
            .padding(.horizontal, 10)
        }
        .padding(.horizontal, 20)
    }
}

struct RangeIndicatorView: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Range")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 45, alignment: .leading)

            Spacer()

            // Color blocks
            HStack(spacing: 4) {
                ForEach(GameColor.allCases) { color in
                    Rectangle()
                        .fill(color.color)
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

struct StatusDisplayView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack {
            // Level number
            Text(viewModel.currentLevelString)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.gameRed)
                .shadow(color: .gameRed.opacity(0.5), radius: 3, x: 0, y: 0)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // Message
            Text(viewModel.state.message)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

struct SubmitKnobView: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            ZStack {
                // Outer shadow/depth - fixed size, doesn't change
                Circle()
                    .fill(Color(red: 0.65, green: 0.15, blue: 0.15))
                    .frame(width: 84, height: 84)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 4)

                // Inner content - this scales when pressed
                ZStack {
                    // Main button
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
                            radius: 5,
                            x: 0,
                            y: 3
                        )

                    // Highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.0)
                                ],
                                center: .top,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 75, height: 75)
                        .offset(y: -25)

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
                .scaleEffect(isPressed ? 0.9 : 1.0)
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
        VStack(spacing: 4) {
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
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }
}

struct ModeSelectorView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 4) {
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
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }
}

struct SkeuomorphicButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            ZStack {
                // Button shadow/depth
                RoundedRectangle(cornerRadius: 6)
                    .fill(isPressed ? Color.gray.opacity(0.3) : Color.gray.opacity(0.6))
                    .frame(height: 28)
                    .offset(y: isPressed ? 0 : 2)

                // Button face
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color(red: 0.4, green: 0.6, blue: 0.4), Color(red: 0.3, green: 0.5, blue: 0.3)] :
                                [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    )

                // Highlight
                RoundedRectangle(cornerRadius: 5)
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
                    .frame(height: 13)
                    .mask(RoundedRectangle(cornerRadius: 5))

                // Text
                Text(title)
                    .font(.system(size: isSelected ? 11 : 10, weight: .bold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .frame(height: 28)
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

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
