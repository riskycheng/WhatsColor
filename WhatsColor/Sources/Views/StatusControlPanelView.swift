import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            // Main Panel Background (Unified)
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.08), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.12), .clear, .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 8)

            HStack(alignment: .center, spacing: 12) {
                // LEFT SIDE: Telemetry (Timer + Status)
                VStack(alignment: .leading, spacing: 2) {
                    // Timer Display (only show if difficulty has time limit)
                    if viewModel.state.difficulty.hasTimeLimit {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text("\(viewModel.timeRemaining)")
                                .font(.system(size: 62, weight: .black, design: .monospaced))
                                .foregroundColor(.gameRed)
                                .shadow(color: .gameRed.opacity(0.4), radius: 8)
                                .monospacedDigit()
                                .minimumScaleFactor(0.5)

                            Text("SEC")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.gameRed.opacity(0.5))
                                .padding(.bottom, 10)
                        }
                    } else {
                        // Easy mode: show "NO LIMIT" text instead of timer
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text("∞")
                                .font(.system(size: 48, weight: .black, design: .monospaced))
                                .foregroundColor(.gameGreen)
                                .shadow(color: .gameGreen.opacity(0.4), radius: 8)

                            Text("NO LIMIT")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.gameGreen.opacity(0.6))
                                .padding(.bottom, 8)
                        }
                    }
                    
                    // REDESIGNED: Advanced Mission Status Telemetry
                    HStack(spacing: 12) {
                        // Difficulty Block
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RANK")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                            
                            Text(viewModel.state.difficulty.rawValue)
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.gameGreen)
                                .shadow(color: .gameGreen.opacity(0.5), radius: 4)
                                .lineLimit(1)
                        }
                        
                        // Hardware-style Vertical Divider
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 1, height: 22)
                        
                        // Operation Mode Block
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.gameMode == .solo ? "SECTOR" : "MODE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                            
                            Text(viewModel.gameMode == .solo ? String(format: "L-%02d", viewModel.state.level) : "VERSUS")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // RIGHT SIDE: Control Instrument (Rotary Knob)
                ZStack {
                    // Shadow for the knob
                    Circle()
                        .fill(RadialGradient(colors: [.black, .clear], center: .center, startRadius: 0, endRadius: 65))
                        .opacity(0.4)
                        .frame(width: 120)
                        .scaleEffect(CGSize(width: 1.0, height: 0.2))
                        .offset(y: 55)

                    SubmitKnobView(viewModel: viewModel)
                }
                .padding(.trailing, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140) // Reduced from 160 to 140 for a more compact look
        .padding(.horizontal, 4)
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}

struct HintButtonView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var isPressed = false
    @State private var showHintToast = false
    @State private var hintMessage = ""
    
    var body: some View {
        Button(action: {
            guard !viewModel.state.isGameOver else { return }
            
            if let hint = HintManager.shared.useHint(
                secretCode: viewModel.state.secretCode,
                currentGuess: viewModel.state.currentGuess,
                attempts: viewModel.state.attempts
            ) {
                hintMessage = hint.description(for: viewModel.state.theme)
                viewModel.showToast("💡 \(hintMessage)", type: .info)
            } else if !HintManager.shared.hasHintsAvailable {
                viewModel.showToast("❌ NO HINTS REMAINING", type: .warning)
                SoundManager.shared.playError()
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Button background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: HintManager.shared.hasHintsAvailable ?
                                    [Color(white: 0.25), Color(white: 0.15)] :
                                    [Color(white: 0.15), Color(white: 0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    HintManager.shared.hasHintsAvailable ?
                                        Color.gameYellow.opacity(0.5) :
                                        Color.white.opacity(0.1),
                                    lineWidth: 1.5
                                )
                        )
                    
                    // Lightbulb icon
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(HintManager.shared.hasHintsAvailable ? .gameYellow : .white.opacity(0.3))
                        .shadow(
                            color: HintManager.shared.hasHintsAvailable ? .gameYellow.opacity(0.5) : .clear,
                            radius: 4
                        )
                }
                
                // Hint count label
                Text(HintManager.shared.hintButtonText)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(HintManager.shared.hasHintsAvailable ? .gameYellow.opacity(0.8) : .white.opacity(0.3))
                    .tracking(0.5)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.state.isGameOver)
        .opacity(viewModel.state.isGameOver ? 0.5 : 1.0)
    }
}

struct SubmitKnobView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var rotation: Double = 0
    @State private var isPressed = false
    @State private var lastFiredRotation: Double = 0
    @State private var hasTriggeredLongPress = false
    @State private var longPressWorkItem: DispatchWorkItem?

    var body: some View {
        IndustrialRotaryButton(
            rotation: $rotation,
            isPressed: $isPressed,
            label: "HOLD SUBMIT",
            onRotate: { newRotation in
                // Logic: Handle angular wrap-around to prevent back-and-forth jumps
                var diff = newRotation - lastFiredRotation
                if diff > 180 { diff -= 360 }
                if diff < -180 { diff += 360 }

                if abs(diff) > 28 { // Slightly improved sensitivity
                    viewModel.cycleColor(forward: diff > 0)
                    lastFiredRotation = newRotation
                    
                    // Natural sensory feedback for rotation
                    SoundManager.shared.playSelection()
                    SoundManager.shared.hapticLight()
                }
            },
            onPressStart: {
                hasTriggeredLongPress = false
                
                // Create a new work item for long press
                let workItem = DispatchWorkItem {
                    hasTriggeredLongPress = true
                    viewModel.submitGuess()
                    SoundManager.shared.hapticSuccess()
                }
                longPressWorkItem = workItem
                
                // Schedule it after 0.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
            },
            onPressEnd: {
                // Cancel pending long press if it hasn't fired yet
                longPressWorkItem?.cancel()
                longPressWorkItem = nil
                
                if !hasTriggeredLongPress {
                    // Short press logic: cycle active slot
                    viewModel.moveToNextSlot()
                    SoundManager.shared.playSelection()
                    SoundManager.shared.hapticLight()
                }
            }
        )
    }
}

struct IndustrialRotaryButton: View {
    @Binding var rotation: Double
    @Binding var isPressed: Bool
    let label: String
    var onRotate: ((Double) -> Void)? = nil
    var onPressStart: (() -> Void)? = nil
    var onPressEnd: (() -> Void)? = nil
    
    // Industrial Dimensions (Base values)
    private let housingSize: CGFloat = 110
    private let bezelBaseSize: CGFloat = 102
    private let plateBaseSize: CGFloat = 72
    
    // Extended touch target for easier rotation triggering (invisible area outside bezel)
    private let rotationTouchExtension: CGFloat = 60
    
    // Dynamic interaction state
    @State private var interactionMode: InteractionMode = .none
    
    enum InteractionMode {
        case none
        case rotation
        case centralButton
    }
    
    var body: some View {
        // Dynamic sizes based on touch location
        // When rotating: expand the bezel outward significantly, shrink the central plate much more
        let bezelExpand: CGFloat = interactionMode == .rotation ? 22 : 0
        let dynamicBezelSize: CGFloat = bezelBaseSize + bezelExpand
        let dynamicPlateSize: CGFloat = interactionMode == .rotation ? (plateBaseSize - 28) :
                                      (interactionMode == .centralButton ? (plateBaseSize + 8) : plateBaseSize)
        // Central button threshold: very small during rotation to prevent accidental clicks
        let dynamicPlateThreshold: CGFloat = interactionMode == .rotation ? (plateBaseSize / 2 - 10) : (plateBaseSize / 2)
        
        ZStack {
            // 1. OUTER HOUSING / BASEPLATE (Deep Charcoal Metal)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.22), Color(white: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: housingSize, height: housingSize)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.1), .black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.6), radius: 8, y: 5)
            
            // 2. ROTATING BEZEL WITH TICKS (Refined Gunmetal)
            // Expands when user touches the rotating region to avoid false central button presses
            ZStack {
                // Background for ticks - Consistent Matte Metal
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.35), Color(white: 0.28)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: dynamicBezelSize, height: dynamicBezelSize)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 1.2)
                    )

                // High-Density Instrument Ticks (Precise Contrast)
                ForEach(0..<120) { i in
                    let isMajor = i % 10 == 0
                    Rectangle()
                        .fill(Color.black.opacity(isMajor ? 0.6 : 0.3))
                        .frame(width: isMajor ? 0.8 : 0.4, height: isMajor ? 8 : 5)
                        .offset(y: -(dynamicBezelSize/2 - (isMajor ? 6 : 4)))
                        .rotationEffect(.degrees(Double(i) * 3))
                }
            }
            .rotationEffect(.degrees(rotation))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: interactionMode)
            
            // 3. INNER CONTROL PLATE (Recessed Black Matte)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.15), Color(white: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: dynamicPlateSize, height: dynamicPlateSize)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.08), .black.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.0
                            )
                    )
                
                // 4. CENTRAL GLOWING LED (Harmonious Glow)
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .fill(Color.gameGreen)
                        .frame(width: 5.5, height: 5.5)
                        .blur(radius: 0.3)
                        .shadow(color: .gameGreen.opacity(0.8), radius: 6)
                    
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: -0.8, y: -0.8)
                }
                .scaleEffect(interactionMode == .centralButton ? 1.2 : 1.0)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: interactionMode)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    let center = CGPoint(x: housingSize/2, y: housingSize/2)
                    let dx = value.location.x - center.x
                    let dy = value.location.y - center.y
                    let distance = sqrt(dx*dx + dy*dy)
                    
                    if interactionMode == .none {
                        // Initial determination on press
                        // Extended rotation touch area: includes bezel + extension area outside
                        let rotationTriggerRadius = (bezelBaseSize / 2) + rotationTouchExtension
                        
                        if distance < dynamicPlateThreshold {
                            interactionMode = .centralButton
                            isPressed = true
                            onPressStart?()
                        } else if distance < rotationTriggerRadius {
                            // User touched within the extended rotation area (even outside visible bezel)
                            interactionMode = .rotation
                        } else {
                            // Outside all touch targets - still allow rotation for convenience
                            interactionMode = .rotation
                        }
                    }
                    
                    if interactionMode == .rotation {
                        let angle = atan2(dy, dx)
                        let newRotation = angle * 180 / .pi
                        onRotate?(newRotation)
                        rotation = newRotation
                    }
                }
                .onEnded { _ in
                    if interactionMode == .centralButton {
                        isPressed = false
                        onPressEnd?()
                    }
                    interactionMode = .none
                }
        )
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
