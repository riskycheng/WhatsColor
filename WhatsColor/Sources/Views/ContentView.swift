import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.launchBackground
                    .ignoresSafeArea()

                // Main game device
                VStack(spacing: 0) {
                    DeviceView(viewModel: viewModel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
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
            // Mode selector
            ModeSelectorView(viewModel: viewModel)
                .padding(.bottom, 10)

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
                    .padding(.top, 10)

                // Bottom panel
                ControlPanelView(viewModel: viewModel)
                    .padding(.top, 15)
            }
            .background(Color.deviceGreen)
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.top, -30)

            // New Game button
            Button(action: {
                viewModel.startNextLevel()
            }) {
                Text("New Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
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
