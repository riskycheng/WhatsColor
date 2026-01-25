import SwiftUI

struct ColorPickerView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

            // Color options
            HStack(spacing: 15) {
                ForEach(GameColor.allCases) { color in
                    ColorOptionButton(color: color) {
                        viewModel.selectColor(color)
                        viewModel.showColorPicker = false
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Instructions
            Text("Tap a color to select it")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
        }
        .background(Color.black.opacity(0.95))
        .cornerRadius(20)
        .padding()
    }
}

struct ColorOptionButton: View {
    let color: GameColor
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Button background
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.color)
                    .frame(width: 55, height: 55)
                    .shadow(color: color.color.opacity(0.5), radius: 5, x: 0, y: 2)

                // Selection indicator
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 55, height: 55)
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
    ColorPickerView(viewModel: GameViewModel())
}
