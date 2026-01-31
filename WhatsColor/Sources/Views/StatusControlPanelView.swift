import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 25) { // Adjusted spacing for balanced layout
            // 1. Telemetry Dashboard (Black Panel)
            StatusDisplayView(viewModel: viewModel)
            
            // 2. Control Instrument (Rotary Knob)
            VStack(spacing: 8) {
                SubmitKnobView(viewModel: viewModel)
                
                // Realistic contact shadow for the hardware unit
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.black, .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 12)
                    .opacity(0.6)
                    .blur(radius: 4)
            }
            .padding(.bottom, 12) // Tightened internal padding to match start screen feel
        }
    }
}

struct StatusDisplayView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left: Large Timer display
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(viewModel.timeRemaining)")
                    .font(.system(size: 72, weight: .black, design: .monospaced))
                    .foregroundColor(.gameRed)
                    .shadow(color: .gameRed.opacity(0.5), radius: 12)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)

                Text("SEC")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(.gameRed.opacity(0.6))
            }
            .padding(.leading, 24)
            
            Spacer()
            
            // Right: Elegant Status Cluster
            VStack(alignment: .leading, spacing: 6) {
                Text("MISSION DATA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1)

                HStack(spacing: 12) {
                    // Difficulty Column
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DIFF")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Text(viewModel.state.difficulty.rawValue.uppercased())
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.gameGreen)
                            .shadow(color: .gameGreen.opacity(0.4), radius: 4)
                    }
                    .frame(width: 60, alignment: .leading)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 20)
                    
                    // Mode/Level Column
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.gameMode == .solo ? "LVL" : "MODE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Text(viewModel.gameMode == .solo ? "\(viewModel.state.level)" : "DUAL")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.gameGreen)
                            .shadow(color: .gameGreen.opacity(0.4), radius: 4)
                    }
                    .frame(width: 35, alignment: .leading)
                }
            }
            .padding(.trailing, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(
            ZStack {
                // Main Panel
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.05), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle Glass/Metal Reflections
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 5)
        )
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
                // Logic: Every 30 degrees increment, cycle color (increased sensitivity)
                let diff = newRotation - lastFiredRotation
                if abs(diff) > 30 {
                    viewModel.cycleColor(forward: diff > 0)
                    lastFiredRotation = newRotation
                    SoundManager.shared.playSelection()
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
    
    var body: some View {
        ZStack {
            // 1. OUTER HOUSING / BASEPLATE (Subtle Matte Metal)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.22), Color(white: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 108, height: 108)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.15), .black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
            
            // 2. ROTATING BEZEL WITH TICKS (High Contrast Metallic)
            ZStack {
                // Background for ticks - Metallic Silver for high contrast
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.5), Color(white: 0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 102, height: 102)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.3), lineWidth: 0.8)
                    )

                // Fine radial ticks - Darker for visibility on light background
                ForEach(0..<120) { i in
                    Rectangle()
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 1.2, height: 12)
                        .offset(y: -40)
                        .rotationEffect(.degrees(Double(i) * 3))
                }
            }
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let vector = CGVector(dx: value.location.x - 54, dy: value.location.y - 54)
                        let angle = atan2(vector.dy, vector.dx)
                        let newRotation = angle * 180 / .pi
                        
                        if Int(newRotation / 3) != Int(rotation / 3) {
                            SoundManager.shared.hapticLight()
                            onRotate?(newRotation)
                        }
                        rotation = newRotation
                    }
            )
            
            // 3. INNER CONTROL PLATE (Ultra-Compact Center)
            ZStack {
                // The physical knob surface
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.12), Color(white: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.1), .black.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1.5)
                
                // 4. CENTRAL GLOWING LED
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 12, height: 12)
                    
                    Circle()
                        .fill(Color.gameGreen)
                        .frame(width: 5, height: 5)
                        .blur(radius: 0.5)
                        .shadow(color: .gameGreen.opacity(0.9), radius: 5)
                    
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: -0.8, y: -0.8)
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
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
