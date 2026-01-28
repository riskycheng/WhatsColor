import SwiftUI

struct HorizontalColorPickerView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedSlotIndex: Int = 0

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showColorPicker = false
                }

            // Color picker dialog
            VStack(spacing: 0) {
                // Title
                HStack {
                    Text("SELECT COLOR")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    Button(action: {
                        viewModel.showColorPicker = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 25)

                // Color options - horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(GameColor.allCases) { color in
                            HorizontalColorButton(
                                color: color,
                                isSelected: viewModel.state.currentGuess[selectedSlotIndex] == color,
                                onTap: {
                                    viewModel.selectColor(color)
                                    viewModel.showColorPicker = false
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 30)
                }

                // Instructions
                Text("TAP A COLOR TO GUESS")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 25)
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
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showColorPicker)
        .onAppear {
            selectedSlotIndex = viewModel.state.activeIndex
        }
    }
}

struct HorizontalColorButton: View {
    let color: GameColor
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    // Button background
                    Circle()
                        .fill(color.color)
                        .frame(width: 60, height: 60)
                        .shadow(color: color.color.opacity(0.5), radius: 8, x: 0, y: 4)

                    // Selection indicator
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 68, height: 68)
                    }
                }

                // Color name
                Text(color.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeedbackModeSelectorView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 15) {
            FeedbackModeButton(
                title: "Line Hint",
                isSelected: viewModel.state.mode == .beginner
            ) {
                viewModel.changeMode(to: .beginner)
            }

            FeedbackModeButton(
                title: "Dot Hint",
                isSelected: viewModel.state.mode == .advanced
            ) {
                viewModel.changeMode(to: .advanced)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

struct FeedbackModeButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? Color.deviceGreen : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HorizontalColorPickerView(viewModel: GameViewModel())
}
