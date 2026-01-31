import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 25) {
            // 1. Telemetry Dashboard (Black Panel)
            StatusDisplayView(viewModel: viewModel)
            
            // 2. Control Instrument (Rotary Knob)
            SubmitKnobView(viewModel: viewModel)
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

    var body: some View {
        IndustrialRotaryButton(
            rotation: $rotation,
            isPressed: $isPressed,
            label: "CONFIRM",
            onRotate: { newRotation in
                // Logic: Every 40 degrees increment, cycle color
                let diff = newRotation - lastFiredRotation
                if abs(diff) > 40 {
                    viewModel.cycleColor(forward: diff > 0)
                    lastFiredRotation = newRotation
                    SoundManager.shared.playSelection()
                }
            },
            onTap: {
                viewModel.submitGuess()
            }
        )
    }
}

struct IndustrialRotaryButton: View {
    @Binding var rotation: Double
    @Binding var isPressed: Bool
    let label: String
    var onRotate: ((Double) -> Void)? = nil
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // 1. OUTERMOST FIXED RING (Depth / Housing)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.15), Color(white: 0.05)],
                        center: .center,
                        startRadius: 45,
                        endRadius: 55
                    )
                )
                .frame(width: 112, height: 112)
                .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
            
            // 2. ROTATING DIAL (With Ticks)
            ZStack {
                // Dial Base - Professional Metal Finish
                Circle()
                    .fill(
                        AngularGradient(
                            stops: [
                                .init(color: Color(white: 0.12), location: 0),
                                .init(color: Color(white: 0.22), location: 0.25),
                                .init(color: Color(white: 0.15), location: 0.5),
                                .init(color: Color(white: 0.25), location: 0.75),
                                .init(color: Color(white: 0.12), location: 1)
                            ],
                            center: .center
                        )
                    )
                
                // Graduation Ticks (Extending closer to center)
                ForEach(0..<60) { i in
                    Rectangle()
                        .fill(Color.white.opacity(i % 5 == 0 ? 0.25 : 0.1))
                        .frame(width: i % 5 == 0 ? 2 : 1, height: i % 5 == 0 ? 12 : 6)
                        .offset(y: -46)
                        .rotationEffect(.degrees(Double(i) * 6))
                }
            }
            .frame(width: 104, height: 104)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let vector = CGVector(dx: value.location.x - 52, dy: value.location.y - 52)
                        let angle = atan2(vector.dy, vector.dx)
                        let newRotation = angle * 180 / .pi
                        
                        // Haptic feedback on ticks
                        if Int(newRotation / 6) != Int(rotation / 6) {
                            SoundManager.shared.hapticLight()
                            onRotate?(newRotation)
                        }
                        rotation = newRotation
                    }
            )
            
            // 3. INNER RECESSED GROOVE (Dark pit)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(white: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            // 4. CENTRAL ACTION BUTTON
            Button(action: {
                SoundManager.shared.playSelection()
                SoundManager.shared.hapticMedium()
                onTap?()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    isPressed ? Color(red: 0.7, green: 0.1, blue: 0.1) : Color.gameRed,
                                    isPressed ? Color(red: 0.5, green: 0, blue: 0) : Color(red: 0.7, green: 0.1, blue: 0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
                    
                    // Light Indicator (LED)
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 5, height: 5)
                        .shadow(color: .white, radius: 4)
                        .offset(y: -18)
                    
                    Text(label)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: 8)
                }
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
