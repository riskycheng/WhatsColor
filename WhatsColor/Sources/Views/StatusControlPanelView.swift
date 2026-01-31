import SwiftUI

struct StatusControlPanelView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 10)

            // Dynamic Informational Panel or Progress display
            StatusDisplayView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
            
            Spacer(minLength: 35) // Increased margin between timer and knob

            // Centered Submit knob - Docked at the bottom
            HStack {
                Spacer()
                SubmitKnobView(onTap: {
                    viewModel.submitGuess()
                })
                Spacer()
            }
            .padding(.bottom, 10) // Small padding at bottom
        }
        .padding(.horizontal, 12)
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
            .padding(.leading, 20) // Reduced from 28
            
            Spacer()
            
            // Vertical Divider with glow
            RoundedRectangle(cornerRadius: 1)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.15), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .padding(.vertical, 15)
                .padding(.horizontal, 12) // Reduced from 20
            
            // Right: Elegant Status Cluster
            VStack(alignment: .leading, spacing: 6) {
                Text("MISSION DATA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1)

                HStack(spacing: 15) {
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
                    .frame(width: 65, alignment: .leading)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 22)
                    
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
                    .frame(width: 65, alignment: .leading)
                }
            }
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            ZStack {
                // Main Panel
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.05), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle Glass/Metal Reflections
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}

struct SubmitKnobView: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticMedium()
            onTap()
        }) {
            ZStack {
                // Outer shadow/depth layer - fixed, creates depth
                Circle()
                    .fill(Color(red: 0.65, green: 0.15, blue: 0.15))
                    .frame(width: 84, height: 84)

                // Inner circle - scales when pressed
                ZStack {
                    // Main button face
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.5, blue: 0.5),
                                    Color(red: 0.9, green: 0.35, blue: 0.35)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: Color(red: 0.5, green: 0.1, blue: 0.1).opacity(0.5),
                            radius: 4,
                            x: 0,
                            y: 2
                        )

                    // Highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.0)
                                ],
                                center: .top,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 76, height: 76)
                        .offset(y: -22)

                    // Marker
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 6, height: 18)
                            .cornerRadius(3)
                        Spacer()
                    }
                    .frame(width: 70, height: 70)
                    .offset(y: -10)
                }
                .scaleEffect(isPressed ? 0.92 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

#Preview {
    StatusControlPanelView(viewModel: GameViewModel())
        .background(Color.deviceGreen)
}
