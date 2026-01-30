import SwiftUI

struct HorizontalColorPickerView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Label section
            VStack(alignment: .leading, spacing: 0) {
                Text("COLOR")
                Text("RANGE")
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(.white.opacity(0.3))
            
            Spacer(minLength: 10)

            // Color options - more compact to fit board width
            HStack(spacing: 6) {
                ForEach(GameColor.allCases) { color in
                    HorizontalColorButton(
                        color: color,
                        isSelected: viewModel.state.currentGuess[viewModel.state.activeIndex] == color,
                        onTap: {
                            viewModel.selectColor(color)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(Color.panelDark)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
    }
}

struct HorizontalColorButton: View {
    let color: GameColor
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 24, height: 24)
                    .shadow(color: color.color.opacity(0.5), radius: 3, x: 0, y: 1)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .frame(width: 32, height: 32)
        .buttonStyle(PlainButtonStyle())
        .onDrag {
            NSItemProvider(object: String(color.rawValue) as NSString)
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        HorizontalColorPickerView(viewModel: GameViewModel())
    }
}
