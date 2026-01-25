import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Board panel
            HStack(spacing: 15) {
                // Row numbers - top to bottom
                VStack(spacing: 12) {
                    ForEach(1...7, id: \.self) { rowNum in
                        RowNumberView(
                            number: rowNum,
                            isActive: viewModel.isCurrentRowActive && viewModel.getCurrentRowNumber() == rowNum
                        )
                    }
                }

                // Game grid - top to bottom to match row numbers
                VStack(spacing: 12) {
                    ForEach(viewModel.state.attempts) { row in
                        GameRowView(
                            row: row,
                            mode: viewModel.state.mode,
                            isActive: viewModel.isCurrentRowActive && viewModel.getCurrentRowNumber() == row.rowNumber,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding(15)
            .background(Color.panelDark)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        }
    }
}

struct RowNumberView: View {
    let number: Int
    let isActive: Bool

    var body: some View {
        Text("\(number)")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isActive ? .white : .gray.opacity(0.6))
            .frame(width: 15, height: 40)
    }
}

struct GameRowView: View {
    let row: GameRowModel
    let mode: FeedbackMode
    let isActive: Bool
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Color slots
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    SlotView(
                        // For active row, show currentGuess; for others, show row.colors
                        color: isActive ? viewModel.state.currentGuess[index] : row.colors[index],
                        isActive: isActive,
                        slotIndex: index,
                        rowNumber: row.rowNumber,
                        onTap: {
                            if isActive {
                                viewModel.selectSlot(at: index)
                                viewModel.showColorPicker = true
                            }
                        },
                        onSwipeLeft: {
                            if isActive {
                                viewModel.cycleColor(at: index, direction: -1)
                            }
                        },
                        onSwipeRight: {
                            if isActive {
                                viewModel.cycleColor(at: index, direction: 1)
                            }
                        }
                    )
                }
            }

            Spacer()

            // Feedback dots
            FeedbackView(feedback: row.feedback, mode: mode)
        }
    }
}

struct SlotView: View {
    let color: GameColor?
    let isActive: Bool
    let slotIndex: Int
    let rowNumber: Int
    let onTap: () -> Void
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var startLocation: CGPoint = .zero

    var body: some View {
        ZStack {
            // Empty slot
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.8))
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color.white.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
                )

            // Filled slot
            if let color = color {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.color)
                    .frame(width: 40, height: 40)
                    .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
            }

            // Tap indicator for active slots
            if isActive {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    )
            }
        }
        .offset(x: dragOffset)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if isActive {
                        if startLocation == .zero {
                            startLocation = value.location
                        }
                        dragOffset = value.location.x - startLocation.x
                    }
                }
                .onEnded { value in
                    if isActive {
                        let dragDistance = value.location.x - startLocation.x
                        let swipeThreshold: CGFloat = 30

                        if abs(dragDistance) < swipeThreshold {
                            // This is a tap
                            onTap()
                        } else if dragDistance < 0 {
                            // Swipe left
                            onSwipeLeft()
                        } else {
// Swipe right
                            onSwipeRight()
                        }
                        dragOffset = 0
                        startLocation = .zero
                    }
                }
        )
        .animation(.easeOut(duration: 0.2), value: dragOffset)
    }
}

struct FeedbackView: View {
    let feedback: [FeedbackType]
    let mode: FeedbackMode

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { col in
                        let index = row * 2 + col
                        FeedbackDot(type: feedback[index], mode: mode)
                    }
                }
            }
        }
        .padding(.leading, 20)
    }
}

struct FeedbackDot: View {
    let type: FeedbackType
    let mode: FeedbackMode

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(dotBorderColor, lineWidth: 1)
            )
            .shadow(color: dotColor.opacity(0.5), radius: 2, x: 0, y: 0)
    }

    var dotColor: Color {
        switch type {
        case .correct:
            return .gameGreen
        case .misplaced:
            return .white
        case .wrong:
            return .black
        case .empty:
            return .black.opacity(0.3)
        }
    }

    var dotBorderColor: Color {
        switch type {
        case .correct:
            return .gameGreen
        case .misplaced:
            return .white
        case .wrong:
            return .gray.opacity(0.5)
        case .empty:
            return .gray.opacity(0.3)
        }
    }
}

#Preview {
    GameBoardView(viewModel: GameViewModel())
        .padding()
}
