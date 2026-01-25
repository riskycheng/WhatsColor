import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 15) {
            // Range indicator
            RangeIndicatorView()

            // Status display
            StatusDisplayView(viewModel: viewModel)

            // Submit knob only
            SubmitKnobView(onTap: {
                viewModel.submitGuess()
            })
        }
        .padding(.horizontal, 20)
    }
}

struct RangeIndicatorView: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Range:")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)

            HStack(spacing: 5) {
                ForEach(GameColor.allCases) { color in
                    Rectangle()
                        .fill(color.color)
                        .frame(width: 12, height: 6)
                        .cornerRadius(1)
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(Color.black)
        .cornerRadius(5)
    }
}

struct StatusDisplayView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack {
            // Level number
            Text(viewModel.currentLevelString)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.gameRed)
                .shadow(color: .gameRed.opacity(0.5), radius: 2, x: 0, y: 0)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // Message
            Text(viewModel.state.message)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.9))
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal, 15)
    }
}

struct SubmitKnobView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Knob base
                Circle()
                    .fill(Color(red: 1.0, green: 0.42, blue: 0.42))
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.5), radius: 5, x: 0, y: 3)

                // Knob marker
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 4, height: 15)
                        .cornerRadius(2)
                    Spacer()
                }
                .frame(width: 80, height: 80)
                .offset(y: -10)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
