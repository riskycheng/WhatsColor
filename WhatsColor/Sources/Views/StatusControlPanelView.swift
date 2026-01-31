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
                    // Timer Display
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(viewModel.timeRemaining)")
                            .font(.system(size: 68, weight: .black, design: .monospaced))
                            .foregroundColor(.gameRed)
                            .shadow(color: .gameRed.opacity(0.4), radius: 8)
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)

                        Text("SEC")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundColor(.gameRed.opacity(0.5))
                    }
                    
                    // Mission Data - High-Contrast Technical Telemetry
                    HStack(spacing: 0) {
                        Text(viewModel.state.difficulty.rawValue.uppercased())
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                            .foregroundColor(.gameGreen)
                            .shadow(color: .gameGreen.opacity(0.5), radius: 6)
                        
                        Text(viewModel.gameMode == .solo ? " // L\(viewModel.state.level)" : " // DUAL")
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundColor(.gameGreen.opacity(0.6))
                    }
                    .padding(.top, 4)
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
    
    // Industrial Dimensions (ULTRA-REFINED)
    private let housingSize: CGFloat = 110
    private let bezelSize: CGFloat = 102
    private let plateSize: CGFloat = 72 // Enlarged from 56
    
    var body: some View {
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
                    .frame(width: bezelSize, height: bezelSize)
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
                        .offset(y: -(bezelSize/2 - (isMajor ? 6 : 4)))
                        .rotationEffect(.degrees(Double(i) * 3))
                }
            }
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = bezelSize / 2
                        let vector = CGVector(dx: value.location.x - center, dy: value.location.y - center)
                        let angle = atan2(vector.dy, vector.dx)
                        let newRotation = angle * 180 / .pi
                        
                        // Pass rotation to callback
                        onRotate?(newRotation)
                        rotation = newRotation
                    }
            )
            
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
                    .frame(width: plateSize, height: plateSize)
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
                        .frame(width: 14, height: 14) // Slightly larger for better balance
                    
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
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPressStart?()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onPressEnd?()
                    }
            )
        }
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
