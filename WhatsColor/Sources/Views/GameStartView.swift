import SwiftUI

struct GameStartView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            // Background hardware details
            VStack {
                HStack {
                    Spacer()
                    Text("SER. NO. WC-2026-XMT")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.15))
                        .padding(20)
                }
                Spacer()
                // Ventilation grilles pattern
                VStack(spacing: 4) {
                    ForEach(0..<6) { _ in
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 40, height: 3)
                    }
                }
                .padding(.bottom, 30)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // App Title - Stylized hardware logo
                VStack(spacing: 8) {
                    ZStack {
                        // Metallic backing plate
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.95), Color(white: 0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 280, height: 120)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                        
                        VStack(spacing: -8) {
                            Text("WHATS")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .tracking(4)
                                .foregroundColor(Color(white: 0.2))
                            
                            Text("COLOR")
                                .font(.system(size: 58, weight: .black, design: .monospaced))
                                .foregroundColor(Color(white: 0.1))
                                .shadow(color: .white.opacity(0.8), radius: 0.5, x: 1, y: 1)
                            
                            // Glowing red status line
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.gameRed)
                                .frame(width: 140, height: 3)
                                .shadow(color: .gameRed.opacity(0.8), radius: 5)
                                .padding(.top, 12)
                        }
                    }
                }
                
                Spacer(minLength: 60)
                
                // Main Console Panel
                VStack(spacing: 40) {
                    // Difficulty Section
                    VStack(spacing: 18) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.gameGreen)
                                .frame(width: 4, height: 14)
                                .shadow(color: .gameGreen.opacity(0.5), radius: 3)
                            Text("DIFFICULTY SELECTOR")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(GameDifficulty.allCases) { diff in
                                IndustrialSwitch(
                                    title: diff.rawValue,
                                    isSelected: viewModel.state.difficulty == diff,
                                    onTap: { viewModel.changeDifficulty(to: diff) }
                                )
                            }
                        }
                    }
                    
                    // Mission Section
VStack(spacing: 18) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.gameGreen)
                                .frame(width: 4, height: 14)
                                .shadow(color: .gameGreen.opacity(0.5), radius: 3)
                            Text("MISSION TYPE BUS")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 15) {
                            IndustrialSwitch(
                                title: "SOLO",
                                isSelected: viewModel.state.mode == .advanced,
                                onTap: { viewModel.changeMode(to: .advanced) }
                            )
                            
                            IndustrialSwitch(
                                title: "DUAL",
                                isSelected: viewModel.state.mode == .beginner,
                                onTap: { viewModel.changeMode(to: .beginner) }
                            )
                        }
                    }
                }
                .padding(28)
                .background(
                    ZStack {
                        // Main Panel Body
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.15), Color(white: 0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Screw Details
                        VStack {
                            HStack {
                                ScrewHead().padding(10)
                                Spacer()
                                ScrewHead().padding(10)
                            }
                            Spacer()
                            HStack {
                                ScrewHead().padding(10)
                                Spacer()
                                ScrewHead().padding(10)
                            }
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.1), .clear, .black.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                .padding(.horizontal, 24)

                // Dedicated Statistics Area - High-Tech Telemetry Bay
                ZStack {
                    if viewModel.state.mode == .advanced {
                        HStack(spacing: 25) {
                            DataModuleSmall(label: "LOG", value: "\(viewModel.state.level)/500", color: .gameGreen)
                            
                            DataModuleSmall(label: "MISSION", value: viewModel.state.difficulty.rawValue, color: .gameGreen)
                            
                            Spacer()
                            
                            // Technical progress graph indicator
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("COMPLETION")
                                    .font(.system(size: 7, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.15))
                                
                                HStack(spacing: 2) {
                                    ForEach(0..<10) { i in
                                        Rectangle()
                                            .fill(Double(i + 1) <= (Double(viewModel.state.level) / 50.0) ? Color.gameGreen : Color.black.opacity(0.4))
                                            .frame(width: 3, height: 8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.45))
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            }
                        )
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64) 
                .padding(.horizontal, 24)
                .padding(.top, 15)
                
                Spacer()
                
                // Redesigned Industrial Initialization Trigger - Now matching the "Ready" aesthetic
                Button(action: {
                    SoundManager.shared.playSuccess()
                    SoundManager.shared.hapticSuccess()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.startGame()
                    }
                }) {
                    ZStack {
                        // Safety Housing - Deep Metallic
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.12), Color(white: 0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 90)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                            )
                        
                        // Internal Component Path
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.6))
                            .frame(height: 70)
                            .padding(.horizontal, 10)
                        
                        // The Primary Actuator - High-Fidelity Gunmetal with Green Glow
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(white: 0.25), Color(white: 0.15)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .gameGreen.opacity(0.15), radius: 10, y: 5)
                            
                            // Mechanical highlights (Screw heads or tabs)
                            HStack {
                                Circle().fill(Color.white.opacity(0.05)).frame(width: 4, height: 4).padding(.leading, 12)
                                Spacer()
                                Circle().fill(Color.white.opacity(0.05)).frame(width: 4, height: 4).padding(.trailing, 12)
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "power")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.gameGreen.opacity(0.6))
                                
                                Text("ENGAGE MISSION")
                                    .font(.system(size: 20, weight: .black, design: .monospaced))
                                    .tracking(2)
                                    .foregroundColor(.white)
                                    .shadow(color: .gameGreen.opacity(0.5), radius: 8)
                                
                                Image(systemName: "chevron.right.2")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.gameGreen.opacity(0.6))
                            }
                        }
                        .frame(height: 64)
                        .padding(.horizontal, 13)
                    }
                }
                .padding(.horizontal, 24)
                .buttonStyle(PressedButtonStyle())
                
                Spacer(minLength: 25)
            }
        }
    }
}

struct DigitalDisplayItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(Color.gameGreen.opacity(0.4))
            Text(value)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(Color.gameGreen)
                .shadow(color: Color.gameGreen.opacity(0.5), radius: 2)
        }
    }
}

struct DataModuleSmall: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            // Industrial vertical indicator
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2, height: 22)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
                    .tracking(1)
                
                Text(value.uppercased())
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct ScrewHead: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(white: 0.4), Color(white: 0.2)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 5
                )
            )
            .frame(width: 8, height: 8)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 6, height: 1)
                    .rotationEffect(.degrees(45))
            )
    }
}

struct IndustrialSwitch: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticLight()
            onTap()
        }) {
            ZStack {
                // Button Base (Recessed look)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 54)
                
                // Button Face
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color(white: 0.25), Color(white: 0.15)] :
                                [Color(white: 0.2), Color(white: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 50)
                    .padding(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.gameGreen.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1.5)
                            .padding(2)
                    )
                
                VStack(spacing: 4) {
                    // Indicator LED
                    Circle()
                        .fill(isSelected ? Color.gameGreen : Color(white: 0.2))
                        .frame(width: 4, height: 4)
                        .shadow(color: isSelected ? Color.gameGreen.opacity(0.8) : .clear, radius: 2)
                    
                    Text(title)
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                }
            }
            .offset(y: isPressed ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct SkeuomorphicButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticLight()
            onTap()
        }) {
            ZStack {
                // Bottom shadow layer (always visible, creates depth)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.6))
                    .offset(y: 2)

                // Main button face
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color(red: 0.4, green: 0.6, blue: 0.4), Color(red: 0.3, green: 0.5, blue: 0.3)] :
                                [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    )

                // Highlight on top half
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.15 : 0.1),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)

                // Text
                Text(title)
                    .font(.system(size: isSelected ? 16 : 14, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 10)
            }
            .frame(height: 50)
            .offset(y: isPressed ? 2 : 0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    ZStack {
        Color.launchBackground.ignoresSafeArea()
        GameStartView(viewModel: GameViewModel())
            .padding(20)
    }
}
