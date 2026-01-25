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
                    Text("Select Color")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        viewModel.showColorPicker = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Color options - horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 25)
                }

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Instructions
                Text("Tap a color to select it")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 10)
            }
            .background(Color.black.opacity(0.95))
            .cornerRadius(20)
            .frame(width: 350)
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
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

struct ModeSelectorView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 15) {
            ModeButton(
                title: "Line Hint",
                isSelected: viewModel.state.mode == .beginner
            ) {
                viewModel.changeMode(to: .beginner)
            }

            ModeButton(
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

struct ModeButton: View {
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
