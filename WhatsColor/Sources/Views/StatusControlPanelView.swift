import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 25) { // Adjusted spacing for balanced layout
            // 1. Telemetry Dashboard (Black Panel)
            StatusDisplayView(viewModel: viewModel)
            
            // 2. Control Instrument (Rotary Knob)
            VStack(spacing: 4) {
                SubmitKnobView(viewModel: viewModel)
                
                // Subtle shadow/glow under the knob housing
                Ellipse()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 90, height: 10)
                    .blur(radius: 6)
            }
            .padding(.bottom, 20) // Reduced to fit within its parent comfortably
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
    @State private var pressStartTime: Date?

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
                pressStartTime = Date()
            },
            onPressEnd: {
                if let startTime = pressStartTime {
                    let duration = Date().timeIntervalSince(startTime)
                    if duration < 0.4 {
                        // Short press: cycle active slot
                        viewModel.moveToNextSlot()
                        SoundManager.shared.playSelection()
                        SoundManager.shared.hapticLight()
                    } else {
                        // Long press: submit
                        viewModel.submitGuess()
                        SoundManager.shared.hapticSuccess()
                    }
                }
                pressStartTime = nil
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
            // 1. OUTER HOUSING (Heavy Duty Gunmetal)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.35), Color(white: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 168, height: 168)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.3), .clear, .black.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.8), radius: 25, y: 15)
            
            // 2. ROTATING DIAL (Brushed Graphite)
            ZStack {
                // Dial Base Side Wall (Visual depth)
                Circle()
                    .fill(Color(white: 0.08))
                    .frame(width: 156, height: 156)
                    .offset(y: 5)

                // Dial Face (Lathed texture)
                Circle()
                    .fill(
                        AngularGradient(
                            stops: [
                                .init(color: Color(white: 0.28), location: 0),
                                .init(color: Color(white: 0.18), location: 0.25),
                                .init(color: Color(white: 0.28), location: 0.5),
                                .init(color: Color(white: 0.18), location: 0.75),
                                .init(color: Color(white: 0.28), location: 1)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 152, height: 152)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                
                // Fine-Grained Ticks
                ForEach(0..<120) { i in
                    Rectangle()
                        .fill(Color.white.opacity(i % 10 == 0 ? 0.45 : 0.15))
                        .frame(width: i % 10 == 0 ? 3 : 1, height: i % 10 == 0 ? 20 : 8)
                        .offset(y: -66)
                        .rotationEffect(.degrees(Double(i) * 3))
                }
            }
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let vector = CGVector(dx: value.location.x - 84, dy: value.location.y - 84)
                        let angle = atan2(vector.dy, vector.dx)
                        let newRotation = angle * 180 / .pi
                        
                        if Int(newRotation / 3) != Int(rotation / 3) {
                            SoundManager.shared.hapticLight()
                            onRotate?(newRotation)
                        }
                        rotation = newRotation
                    }
            )
            
            // 3. CENTRAL RECESSION
            Circle()
                .fill(Color.black)
                .frame(width: 106, height: 106)
                .shadow(color: .white.opacity(0.12), radius: 2, y: -2)
            
            // 4. ACTION BUTTON (Vivid Industrial Red)
            ZStack {
                // Pressed State logic integrated into one gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isPressed ? Color(red: 0.6, green: 0, blue: 0.05) : Color(red: 1.0, green: 0.15, blue: 0.15),
                                Color(red: 0.45, green: 0, blue: 0)
                            ],
                            center: isPressed ? .center : .topLeading,
                            startRadius: 0,
                            endRadius: 48
                        )
                    )
                    .frame(width: 94, height: 94)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear, .black.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3.5
                            )
                    )
                
                // Hardware Printed Label (More readable)
                VStack(spacing: 3) {
                    Text(label)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.black.opacity(0.4))
                        .overlay(
                            Text(label)
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.15))
                                .offset(y: -0.5)
                        )
                    
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.3))
                }
                .offset(y: 16)
                
                // High-End Status Gem
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 18, height: 18)
                    
                    Circle()
                        .fill(Color.gameGreen)
                        .frame(width: 8, height: 8)
                        .blur(radius: 0.5)
                        .shadow(color: .gameGreen.opacity(0.8), radius: 6)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 2, height: 2)
                        .offset(x: -1.5, y: -1.5)
                }
                .offset(y: -22)
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
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
