import SwiftUI

struct HorizontalColorPickerView: View {
    @ObservedObject var viewModel: GameViewModel
    
    /// Returns the colors that should be shown based on difficulty
    private var enabledColors: [GameColor] {
        let allColors = GameColor.allCases
        let enabledCount = viewModel.state.difficulty.enabledColorCount
        return Array(allColors.prefix(enabledCount))
    }
    
    /// Returns colors that are disabled (grayed out)
    private var disabledColors: [GameColor] {
        let allColors = GameColor.allCases
        let enabledCount = viewModel.state.difficulty.enabledColorCount
        guard enabledCount < allColors.count else { return [] }
        return Array(allColors.suffix(from: enabledCount))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Color options - evenly distributed across full width
            HStack(spacing: 0) {
                let allColors = enabledColors + disabledColors
                
                ForEach(Array(allColors.enumerated()), id: \.element) { index, color in
                    HorizontalColorButton(
                        color: color,
                        isSelected: viewModel.state.currentGuess[viewModel.state.activeIndex] == color,
                        isEnabled: enabledColors.contains(color),
                        viewModel: viewModel,
                        onTap: {
                            if enabledColors.contains(color) {
                                viewModel.selectColor(color)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.4))
                    
                    // Internal shadow/recessed look
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            )
        }
    }
}

struct HorizontalColorButton: View {
    let color: GameColor
    let isSelected: Bool
    let isEnabled: Bool
    @ObservedObject var viewModel: GameViewModel
    let onTap: () -> Void

    @State private var isPressing = false

    var body: some View {
        ZStack {
            // Main visual element (Icon or Color Dot)
            if let icon = viewModel.state.theme.image(for: color) {
                // Background shadow for the icon
                Circle()
                    .fill(Color.black.opacity(isEnabled ? 0.3 : 0.15))
                    .frame(width: 32, height: 32)
                    .blur(radius: isPressing && isEnabled ? 4 : 2)
                    .offset(y: isPressing && isEnabled ? 2 : 1)

                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .grayscale(isEnabled ? 0 : 1)
                    .opacity(isEnabled ? 1 : 0.3)
            } else {
                // Secondary visual fallback (Original Color Dot)
                ZStack {
                    // Shadow background (Fallback only)
                    Circle()
                        .fill(color.color.opacity(isEnabled ? 0.3 : 0.1))
                        .frame(width: 36, height: 36)
                        .blur(radius: isPressing && isEnabled ? 8 : 4)
                        .offset(y: isPressing && isEnabled ? 4 : 2)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.color.opacity(isEnabled ? 0.85 : 0.3),
                                    color.color.opacity(isEnabled ? 1 : 0.4)
                                ],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 32
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isEnabled ? 0.2 : 0.05), lineWidth: 1)
                        )
                        .grayscale(isEnabled ? 0 : 0.7)
                }
            }
            
            // Selection / Press highlight (only for enabled colors)
            if isEnabled {
                let isDragActive = viewModel.activeDragColor != nil
                let showingSelection = isDragActive ? (viewModel.activeDragColor == color) : isSelected
                
                if showingSelection || isPressing {
                    Circle()
                        .stroke(Color.white, lineWidth: 2.5)
                        .frame(width: 40, height: 40)
                        .shadow(color: .white.opacity(0.5), radius: 3)
                }
            }
            
            // Disabled overlay
            if !isEnabled {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "slash.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .scaleEffect(isPressing && isEnabled ? 1.1 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressing)
        .frame(width: 38, height: 38)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    guard isEnabled else { return }
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
                    
                    guard isEnabled else { return }
                    
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
