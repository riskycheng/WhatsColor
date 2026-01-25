import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.launchBackground
                    .ignoresSafeArea()

                // Main game device - full screen
                VStack(spacing: 0) {
                    DeviceView(viewModel: viewModel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .frame(maxHeight: .infinity)
                }

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
            // Mode selector
            ModeSelectorView(viewModel: viewModel)
                .padding(.bottom, 10)

            // Main device body - takes available space
            VStack(spacing: 0) {
                // Antenna (visual decoration)
                Rectangle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 80, height: 30)
                    .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
                    .offset(y: 15)

                // Game board area - larger portion
                GameBoardView(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                // Bottom panel - status and knob only
                StatusControlPanelView(viewModel: viewModel)
                    .padding(.top, 15)
                    .padding(.bottom, 20)
            }
            .background(Color.deviceGreen)
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.top, -30)
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
