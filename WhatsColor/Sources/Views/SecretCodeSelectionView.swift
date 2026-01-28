import SwiftUI

// MARK: - Secret Code Selection Dialog
// Sophisticated color picker with consistent dialog height

struct SecretCodeSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    
    // Fixed dialog dimensions
    private let dialogWidth: CGFloat = 360
    private let dialogPadding: CGFloat = 24
    private let pickerHeight: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissSecretCodeSelection()
                }
            
            // Dialog content - fixed height container
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                // Selected colors preview section
                selectedColorsSection
                    .frame(height: 80)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                // Color picker section - fixed height
                colorPickerSection
                    .frame(height: pickerHeight)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                // Action buttons section
                actionButtonsSection
                    .frame(height: 72)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 10)
            )
            .frame(width: min(dialogWidth, UIScreen.main.bounds.width - 40))
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(spacing: 4) {
                Text("SET SECRET CODE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Select 4 colors in order")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Close button
            Button(action: {
                viewModel.dismissSecretCodeSelection()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray.opacity(0.6))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal, dialogPadding)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Selected Colors Section
    
    private var selectedColorsSection: some View {
        HStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { index in
                ColorSlotView(
                    color: viewModel.selectedSecretCode.indices.contains(index) ?
                           viewModel.selectedSecretCode[index] : nil,
                    slotIndex: index,
                    isActive: index == viewModel.selectedSecretCode.count,
                    onTap: {
                        // Reset from this slot onwards
                        if index < viewModel.selectedSecretCode.count {
                            viewModel.resetSecretCode(from: index)
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, dialogPadding)
    }
    
    // MARK: - Color Picker Section
    
    private var colorPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(GameColor.allCases, id: \.self) { color in
                    SecretColorCard(
                        color: color,
                        isSelected: viewModel.selectedSecretCode.last == color,
                        action: {
                            viewModel.selectSecretColor(color)
                        }
                    )
                }
            }
            .padding(.horizontal, dialogPadding - 4)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // Cancel button
            Button(action: {
                viewModel.dismissSecretCodeSelection()
            }) {
                Text("CANCEL")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            // Start button
            Button(action: {
                viewModel.finishSecretCodeSelection()
            }) {
                Text("START GAME")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.isSecretCodeComplete ?
                                  Color.gameGreen :
                                  Color.gray.opacity(0.3))
                    )
                    .shadow(
                        color: viewModel.isSecretCodeComplete ?
                            Color.gameGreen.opacity(0.4) :
                            .clear,
                        radius: 8, x: 0, y: 4
                    )
            }
            .disabled(!viewModel.isSecretCodeComplete)
        }
        .padding(.horizontal, dialogPadding)
        .padding(.vertical, 12)
    }
}

// MARK: - Color Slot View

struct ColorSlotView: View {
    let color: GameColor?
    let slotIndex: Int
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Slot background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isActive ? Color.gameGreen.opacity(0.6) : Color.clear,
                                lineWidth: isActive ? 2 : 0
                            )
                    )
                
                if let color = color {
                    // Selected color
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.color)
                        .shadow(color: color.color.opacity(0.5), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Position indicator
                    VStack {
                        HStack {
                            Text("\(slotIndex + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                                .offset(x: -4, y: -4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(4)
                } else {
                    // Empty slot indicator
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        if isActive {
                            Text("TAP")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.gameGreen)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

// MARK: - Secret Color Card

struct SecretColorCard: View {
    let color: GameColor
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                // Color swatch
                ZStack {
                    // Glow effect
                    if isSelected {
                        Circle()
                            .fill(color.color.opacity(0.4))
                            .blur(radius: 10)
                            .frame(width: 60, height: 60)
                    }
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.color, color.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(
                            color: color.color.opacity(0.5),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? 4 : 2
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.white : Color.white.opacity(0.2),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                    
                    // Highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.0)
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 44, height: 44)
                        .offset(x: -6, y: -6)
                    
                    // Selection checkmark
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                
                // Color name
                Text(color.name)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ?
                          LinearGradient(
                              colors: [Color.gameGreen.opacity(0.15), Color.gameGreen.opacity(0.08)],
                              startPoint: .top,
                              endPoint: .bottom
                          ) :
                          LinearGradient(
                              colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                              startPoint: .top,
                              endPoint: .bottom
                          )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.gameGreen.opacity(0.5) : Color.clear, lineWidth: 2)
)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.92 : (isSelected ? 1.08 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    SecretCodeSelectionView(viewModel: GameViewModel())
}
