import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Board panel
            HStack(spacing: 0) {
                // Game grid - top to bottom
                VStack(spacing: 8) {
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
                        isSelected: isActive && viewModel.state.activeIndex == index,
                        slotIndex: index,
                        rowNumber: row.rowNumber,
                        viewModel: viewModel,
                        onTap: {
                            if isActive {
                                viewModel.selectSlot(at: index)
                            }
                        },
                        onDrop: { color in
                            if isActive {
                                viewModel.state.currentGuess[index] = color
                                viewModel.selectSlot(at: index)
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
    let isSelected: Bool
    let slotIndex: Int
    let rowNumber: Int
    @ObservedObject var viewModel: GameViewModel
    let onTap: () -> Void
    let onDrop: (GameColor) -> Void
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var startLocation: CGPoint = .zero

    var body: some View {
        let showTargetEffect = viewModel.dropTargetIndex == slotIndex && isActive
        
        ZStack {
            // Empty slot
            RoundedRectangle(cornerRadius: 8)
                .fill(showTargetEffect ? Color.white.opacity(0.15) : Color.black.opacity(0.8))
                .frame(width: 45, height: 45)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(showTargetEffect ? Color.white : (isSelected ? Color.white : (isActive ? Color.white.opacity(0.5) : Color.gray.opacity(0.3))), 
                                lineWidth: showTargetEffect ? 4 : (isSelected ? 3 : (isActive ? 2 : 1)))
                )
                .scaleEffect(showTargetEffect ? 1.15 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: showTargetEffect)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                if isActive {
                                    viewModel.registerSlotFrame(geo.frame(in: .global), for: slotIndex)
                                }
                            }
                            .onChange(of: geo.frame(in: .global)) { newFrame in
                                if isActive {
                                    viewModel.registerSlotFrame(newFrame, for: slotIndex)
                                }
                            }
                    }
                )

            // Filled slot
            if let color = color {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.color)
                    .frame(width: 45, height: 45)
                    .shadow(color: isSelected ? color.color.opacity(0.8) : .white.opacity(0.3), radius: isSelected ? 6 : 2, x: 0, y: 0)
                    .scaleEffect(showTargetEffect ? 0.9 : 1.0)
            }

            // Selection indicator for active slot
            if isSelected && !showTargetEffect {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(width: 45, height: 45)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 3)
                            .scaleEffect(1.1)
                    )
            }
        }
        .offset(x: dragOffset)
        .contentShape(Rectangle())
        .onTapGesture {
            if isActive {
                onTap()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
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
                        
                        if dragDistance < 0 {
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
            .frame(width: 14, height: 14)
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
