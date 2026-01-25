import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Range indicator
            RangeIndicatorView()

            // Status display
            StatusDisplayView(viewModel: viewModel)

            // Controls
            HStack(spacing: 20) {
                // Color input slots
                VStack(spacing: 8) {
                    Text("Input")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { index in
                            InputSlotView(
                                color: viewModel.state.currentGuess[index],
                                isActive: index == viewModel.state.activeIndex,
                                onTap: {
                                    viewModel.state.activeIndex = index
                                    viewModel.showColorPicker = true
                                }
                            )
                        }
                    }
                }

                // Submit knob
                SubmitKnobView(onTap: {
                    viewModel.submitGuess()
                })
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $viewModel.showColorPicker) {
            ColorPickerView(viewModel: viewModel)
        }
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

struct InputSlotView: View {
    let color: GameColor?
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Slot background
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.8))
                .frame(width: 50, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isActive ? Color.white : Color.clear,
                            lineWidth: isActive ? 3 : 0
                        )
                )
                .shadow(color: isActive ? Color.white.opacity(0.5) : .clear, radius: 5, x: 0, y: 0)

            // Color
            if let color = color {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.color)
                    .frame(width: 42, height: 42)
            }
        }
        .onTapGesture(perform: onTap)
        .animation(.easeInOut(duration: 0.2), value: isActive)
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
    ControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
