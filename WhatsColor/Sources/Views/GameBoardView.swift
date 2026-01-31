import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Screen Header Label
            HStack {
                Text("NEURAL_CORE_DISPLAY")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.15))
                Spacer()
                HStack(spacing: 3) {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(Color.gameGreen.opacity(0.2))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(.horizontal, 8)

            // Board panel
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
            .padding(18)
            .background(
                ZStack {
                    // Deep recessed screen background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.03))
                    
                    // Screen "Glow" shadow
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.03), lineWidth: 1)
                }
            )
            .overlay(
                // Carbon fiber / grid texture overlay (subtle)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 10)
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
            HStack(spacing: 14) {
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

    var body: some View {
        let showTargetEffect = viewModel.dropTargetIndex == slotIndex && viewModel.dropTargetRow == rowNumber && isActive
        
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
                                viewModel.registerSlotFrame(geo.frame(in: .global), row: rowNumber, slot: slotIndex)
                            }
                            .onChange(of: geo.frame(in: .global)) { newFrame in
                                viewModel.registerSlotFrame(newFrame, row: rowNumber, slot: slotIndex)
                            }
                    }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.dropTargetIndex)

            // Filled slot
            if let color = color {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.color)
                    .frame(width: 45, height: 45)
                    .shadow(color: isSelected ? color.color.opacity(0.8) : .white.opacity(0.3), radius: isSelected ? 6 : 2, x: 0, y: 0)
                    .scaleEffect(showTargetEffect ? 0.9 : 1.0)
                    .opacity(viewModel.sourceSlotIndex == slotIndex && viewModel.sourceSlotRow == rowNumber ? 0.0 : 1.0) // Hide source while dragging
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.dropTargetIndex)
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
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if isActive {
                        if viewModel.activeDragColor == nil {
                            // Start dragging if we have a color and moved enough
                            if abs(value.translation.width) > 10 || abs(value.translation.height) > 10 {
                                if let color = color {
                                    viewModel.activeDragColor = color
                                    viewModel.sourceSlotRow = rowNumber
                                    viewModel.sourceSlotIndex = slotIndex
                                    SoundManager.shared.playDragStart()
                                    SoundManager.shared.hapticMedium()
                                }
                            }
                        }
                        
                        // Update position for the global overlay
                        if viewModel.activeDragColor != nil {
                            viewModel.updateDragPosition(value.location)
                        }
                    }
                }
                .onEnded { value in
                    if isActive {
                        if viewModel.activeDragColor == nil {
                            // If we never triggered the drag threshold, treat as tap
                            onTap()
                        } else {
                            // Check if we are releasing over a valid target
                            viewModel.endDragging()
                        }
                    } else if viewModel.activeDragColor != nil {
                        // If dragging started from active row but ended over inactive row, still trigger logic
                        viewModel.endDragging()
                    }
                }
        )
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
        .padding(.leading, 18)
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
