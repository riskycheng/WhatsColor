import SwiftUI

struct HorizontalColorPickerView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Technical Label
            HStack(spacing: 4) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 8))
                Text("COLOR_INJECTOR_BUS")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(1)
            }
            .foregroundColor(.white.opacity(0.15))
            .padding(.leading, 10)

            HStack(spacing: 0) {
                // Color options - sized to match board width
                HStack(spacing: 8) { 
                    ForEach(GameColor.allCases) { color in
                        HorizontalColorButton(
                            color: color,
                            isSelected: viewModel.state.currentGuess[viewModel.state.activeIndex] == color,
                            viewModel: viewModel,
                            onTap: {
                                viewModel.selectColor(color)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.4))
                    
                    // Internal shadow/recessed look
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            )
        }
        .padding(.horizontal, 16)
    }
}

struct HorizontalColorButton: View {
    let color: GameColor
    let isSelected: Bool
    @ObservedObject var viewModel: GameViewModel
    let onTap: () -> Void

    @State private var isPressing = false

    var body: some View {
        ZStack {
            // Shadow background
            Circle()
                .fill(color.color.opacity(0.3))
                .frame(width: 36, height: 36)
                .blur(radius: isPressing ? 8 : 4)
                .offset(y: isPressing ? 4 : 2)
            
            // Main color circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.color.opacity(0.85), color.color],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 32
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // Selection / Press highlight
            let isDragActive = viewModel.activeDragColor != nil
            let showingSelection = isDragActive ? (viewModel.activeDragColor == color) : isSelected
            
            if showingSelection || isPressing {
                Circle()
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: 40, height: 40)
                    .shadow(color: .white.opacity(0.5), radius: 3)
            }
        }
        .scaleEffect(isPressing ? 1.1 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressing)
        .frame(width: 38, height: 38)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    isPressing = true
                    if viewModel.activeDragColor == nil {
                        // Start drag once we move a bit to distinguish from tap
                        if abs(value.translation.width) > 5 || abs(value.translation.height) > 5 {
                            viewModel.activeDragColor = color
                            // We don't call selectColor here anymore to avoid premature board update
                            SoundManager.shared.playDragStart()
                            SoundManager.shared.hapticMedium()
                        }
                    }
                    viewModel.updateDragPosition(value.location)
                }
                .onEnded { value in
                    isPressing = false
                    
                    if viewModel.activeDragColor == nil {
                        SoundManager.shared.playSelection()
                        SoundManager.shared.hapticLight()
                        onTap()
                    } else {
                        viewModel.endDragging()
                    }
                }
        )
    }
}

#Preview {
    ZStack {
        Color.gray
        HorizontalColorPickerView(viewModel: GameViewModel())
    }
}
