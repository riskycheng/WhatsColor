import SwiftUI

// MARK: - Secret Code Selection Dialog
// Sophisticated color picker with consistent dialog height

struct SecretCodeSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    
    // Fixed dialog dimensions
    private let dialogWidth: CGFloat = 360
    private let dialogPadding: CGFloat = 24
    private let pickerHeight: CGFloat = 110
    
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
                    .padding(.vertical, 16)
                
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
            
            // Global drag overlay for secret code selection
            if let dragColor = viewModel.secretDragColor, let _ = viewModel.secretDragSourceIndex {
                GeometryReader { _ in
                    ZStack {
                        // Dragged color representation
                        if let icon = viewModel.state.theme.image(for: dragColor) {
                            icon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(dragColor.color)
                                .frame(width: 50, height: 50)
                                .shadow(color: dragColor.color.opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                    }
                    .position(viewModel.secretDragPosition)
                    .scaleEffect(1.1)
                    .opacity(0.9)
                    .animation(.spring(response: 0.1, dampingFraction: 0.8), value: viewModel.secretDragPosition)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.gameMode == .dual ? "PLAYER 1: MISSION LOG" : "MISSION BRIEFING")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(viewModel.gameMode == .dual ? "SET THE SECRET CODE" : "Select 4 colors in order")
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
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Selected Colors Section
    
    private var selectedColorsSection: some View {
        HStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { index in
                SecretColorSlotView(
                    color: viewModel.selectedSecretCode.indices.contains(index) ?
                           viewModel.selectedSecretCode[index] : nil,
                    slotIndex: index,
                    isActive: index == viewModel.currentSecretSlot,
                    viewModel: viewModel
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, dialogPadding)
    }

    // MARK: - Color Picker Section
    
    private var colorPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GameColor.allCases, id: \.self) { color in
                    SecretColorCard(
                        color: color,
                        isSelected: viewModel.currentSecretSlot < 4 && viewModel.selectedSecretCode.indices.contains(viewModel.currentSecretSlot) && viewModel.selectedSecretCode[viewModel.currentSecretSlot] == color,
                        viewModel: viewModel,
                        action: {
                            viewModel.selectSecretColor(color)
                        }
                    )
                }
            }
            .padding(.horizontal, dialogPadding)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 8) {
            // Unified Hint Area - Pre-reserved space to prevent layout jumps
            HStack {
                if viewModel.showDuplicateWarning {
                    Text("NO DUPLICATES ALLOWED")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.gameRed.opacity(0.9))
                        .tracking(1.5)
                } else if viewModel.gameMode == .dual && viewModel.isSecretCodeComplete {
                    Text("READY? HAND TO THE CHALLENGER")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.gameGreen.opacity(0.8))
                        .tracking(1.5)
                } else {
                    Text(" ")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                }
            }
            .frame(height: 20)
            .padding(.top, 8)
            
            HStack(spacing: 12) {
                // Random button
                Button(action: {
                    viewModel.generateRandomSecretCode()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 14))
                        Text("RANDOM")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.6))
                    )
                }
                
                // Start button
                Button(action: {
                    viewModel.finishSecretCodeSelection()
                }) {
                    Text("START")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
        }
        .padding(.horizontal, dialogPadding)
        .padding(.vertical, 12)
        .animation(.spring(), value: viewModel.isSecretCodeComplete)
        .animation(.spring(), value: viewModel.showDuplicateWarning)
    }
}

// MARK: - Secret Color Slot View with Drag Support

struct SecretColorSlotView: View {
    let color: GameColor?
    let slotIndex: Int
    let isActive: Bool
    @ObservedObject var viewModel: GameViewModel
    @State private var isPressing = false
    
    var body: some View {
        let isPreciseTarget = viewModel.secretDropTargetIndex == slotIndex
        let showTargetEffect = isPreciseTarget
        
        ZStack {
            // Slot background
            RoundedRectangle(cornerRadius: 4)
                .fill(showTargetEffect ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isActive ? Color.gameGreen.opacity(0.6) : (showTargetEffect ? Color.white : Color.white.opacity(0.1)),
                            lineWidth: isActive ? 2 : (showTargetEffect ? 3 : 1)
                        )
                )
                .scaleEffect(showTargetEffect ? 1.1 : (isPressing ? 0.95 : 1.0))
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: showTargetEffect)
            
            if let color = color {
                // Selected color/icon
                if let icon = viewModel.state.theme.image(for: color) {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        .scaleEffect(showTargetEffect ? 0.9 : 1.0)
                        .opacity(viewModel.secretDragSourceIndex == slotIndex ? 0.0 : 1.0)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.color)
                        .padding(4)
                        .shadow(color: color.color.opacity(0.5), radius: 4, x: 0, y: 2)
                        .scaleEffect(showTargetEffect ? 0.9 : 1.0)
                        .opacity(viewModel.secretDragSourceIndex == slotIndex ? 0.0 : 1.0)
                }
            } else {
                // Empty slot indicator
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            
            // Selection indicator
            if isActive && !showTargetEffect {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white, lineWidth: 2)
                            .scaleEffect(1.05)
                    )
            }
        }
        .frame(width: 60, height: 60)
        .scaleEffect(isActive && !showTargetEffect ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        viewModel.registerSecretSlotFrame(geo.frame(in: .global), slot: slotIndex)
                    }
                    .onChange(of: geo.frame(in: .global)) { newFrame in
                        viewModel.registerSecretSlotFrame(newFrame, slot: slotIndex)
                    }
            }
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if viewModel.secretDragSourceIndex == nil {
                        // Start dragging if we have a color and moved enough
                        if abs(value.translation.width) > 5 || abs(value.translation.height) > 5 {
                            if color != nil {
                                isPressing = false
                                viewModel.secretDragSourceIndex = slotIndex
                                viewModel.secretDragColor = color
                                SoundManager.shared.playDragStart()
                                SoundManager.shared.hapticMedium()
                            }
                        } else {
                            // Show press feedback while deciding if it's a drag
                            isPressing = true
                        }
                    }
                    
                    // Update position for the global overlay - always update to follow finger
                    if viewModel.secretDragSourceIndex != nil {
                        viewModel.updateSecretDragPosition(value.location)
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    
                    if viewModel.secretDragSourceIndex == nil {
                        // If we never triggered the drag threshold, treat as tap
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.currentSecretSlot = slotIndex
                            SoundManager.shared.playSelection()
                            SoundManager.shared.hapticLight()
                        }
                    } else {
                        // Check if we are releasing over a valid target
                        viewModel.endSecretDragging()
                    }
                }
        )
    }
}

// MARK: - Secret Color Card

struct SecretColorCard: View {
    let color: GameColor
    let isSelected: Bool
    @ObservedObject var viewModel: GameViewModel
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            SoundManager.shared.hapticLight()
            action()
        }) {
            ZStack {
                // Glow effect for selection
                if isSelected {
                    if let icon = viewModel.state.theme.image(for: color) {
                         Circle()
                            .fill(Color.white.opacity(0.3))
                            .blur(radius: 12)
                            .frame(width: 58, height: 58)
                    } else {
                        Rectangle()
                            .fill(color.color.opacity(0.4))
                            .blur(radius: 12)
                            .frame(width: 58, height: 58)
                    }
                }
                
                // The Visual Representation (Icon or Color block)
                if let icon = viewModel.state.theme.image(for: color) {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.2))
                                .frame(width: 42, height: 42)
                                .blur(radius: 2)
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                                .frame(width: 54, height: 54)
                        )
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color.color, color.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Rectangle()
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.15), lineWidth: isSelected ? 3 : 1)
                        )
                        .shadow(color: color.color.opacity(0.35), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 4 : 1)
                }
                
                // Selection checkmark overlay
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2)
                }
            }
            .frame(width: 65, height: 75)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    SecretCodeSelectionView(viewModel: GameViewModel())
}
