import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.launchBackground
                    .ignoresSafeArea()

                // Main game device - centered
                DeviceView(viewModel: viewModel)
                    .frame(maxWidth: geometry.size.width > 400 ? 380 : geometry.size.width - 40)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 10)

                // Color picker dialog (centered overlay)
                if viewModel.showColorPicker {
                    HorizontalColorPickerView(viewModel: viewModel)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.showColorPicker)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct DeviceView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar with reset button - aligned with game board
            HStack(alignment: .center) {
                ResetButtonView(onTap: {
                    viewModel.startNewGame()
                })
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(height: 50)

            // Main device body
            VStack(spacing: 0) {
                // Antenna (visual decoration)
                Rectangle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 80, height: 30)
                    .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
                    .offset(y: 15)

                // Game board area
                GameBoardView(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                // Bottom panel - status and knob only
                StatusControlPanelView(viewModel: viewModel)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            .background(Color.deviceGreen)
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.top, -30)
        }
    }
}

struct ResetButtonView: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 8) {
                // Reset icon
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))

                // Reset text label
                Text("RESET")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Skeuomorphic layered background
            .overlay(
                ZStack {
                    // Button depth/shadow layer
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isPressed ? Color.gray.opacity(0.3) : Color.gray.opacity(0.6))
                        .offset(y: isPressed ? 0 : 3)

                    // Button face with gradient
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.55),
                                    Color.gray.opacity(0.35)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Border
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)

                    // Highlight
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .padding(2)
                }
            )
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .offset(y: isPressed ? 3 : 0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// Helper extension for specific corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
}
