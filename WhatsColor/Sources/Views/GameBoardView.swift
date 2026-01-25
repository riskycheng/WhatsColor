import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Board panel
            HStack(spacing: 15) {
                // Row numbers
                VStack(spacing: 12) {
                    ForEach((1...7).reversed(), id: \.self) { rowNum in
                        Text("\(rowNum)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                            .frame(width: 15)
                    }
                }

                // Game grid
                VStack(spacing: 12) {
                    ForEach(viewModel.state.attempts.reversed()) { row in
                        GameRowView(row: row, mode: viewModel.state.mode)
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

    var body: some View {
        HStack(spacing: 0) {
            // Color slots
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    SlotView(color: row.colors[index])
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

    var body: some View {
        ZStack {
            // Empty slot
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.8))
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            // Filled slot
            if let color = color {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.color)
                    .frame(width: 40, height: 40)
                    .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
            }
        }
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
