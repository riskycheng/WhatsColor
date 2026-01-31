import SwiftUI

struct GameStartView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            
            // App Title - Stylized hardware logo
            VStack(spacing: -5) {
                Text("WHATS")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                
                Text("COLOR")
                    .font(.system(size: 64, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                
                // Red glowing accent line
                Rectangle()
                    .fill(Color.gameRed)
                    .frame(width: 120, height: 4)
                    .cornerRadius(2)
                    .shadow(color: .gameRed.opacity(0.6), radius: 4, x: 0, y: 0)
                    .padding(.top, 10)
            }
            
            Spacer(minLength: 60)
            
            // Menu Container
            VStack(spacing: 35) {
                // Difficulty Section
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        Text("DIFFICULTY")
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        ForEach(GameDifficulty.allCases) { diff in
                            SkeuomorphicButton(
                                title: diff.rawValue,
                                isSelected: viewModel.state.difficulty == diff,
                                onTap: { viewModel.changeDifficulty(to: diff) }
                            )
                        }
                    }
                }
                
                // Mode Section
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("MISSION TYPE")
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    
                    HStack(spacing: 15) {
                        SkeuomorphicButton(
                            title: "SOLO",
                            isSelected: viewModel.state.mode == .advanced,
                            onTap: { viewModel.changeMode(to: .advanced) }
                        )
                        
                        SkeuomorphicButton(
                            title: "DUAL",
                            isSelected: viewModel.state.mode == .beginner,
                            onTap: { viewModel.changeMode(to: .beginner) }
                        )
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Industrial Start Button
            Button(action: {
                SoundManager.shared.playSuccess()
                SoundManager.shared.hapticSuccess()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.startGame()
                }
            }) {
                ZStack {
                    // Button Depth
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.6, green: 0.1, blue: 0.1))
                        .offset(y: 4)
                    
                    // Button Face
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color.gameRed, Color(red: 0.8, green: 0.15, blue: 0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Text("INITIALIZE")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        )
                }
                .frame(height: 76)
                .shadow(color: .gameRed.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 40)
            .buttonStyle(PressedButtonStyle())
            
            Spacer(minLength: 15) // Standardized bottom internal spacer
        }
        .background(Color.deviceGreen)
        .cornerRadius(40)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
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
