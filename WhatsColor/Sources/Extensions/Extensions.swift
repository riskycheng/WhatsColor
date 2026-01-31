import SwiftUI

extension Color {
    static let deviceGreen = Color("DeviceGreen")
    static let panelDark = Color("PanelDark")
    static let launchBackground = Color("LaunchBackground")

    static let gameRed = Color(hex: "#ff3b30")
    static let gameGreen = Color(hex: "#4cd964")
    static let gameOrange = Color(hex: "#ff9500")
    static let gameBlue = Color(hex: "#007aff")
    static let gameYellow = Color(hex: "#ffcc00")
    static let gamePurple = Color(hex: "#af52de")
    static let gameCyan = Color(hex: "#5ac8fa")
    static let gameBlack = Color.black
    static let gameWhite = Color.white
    static let gameGray = Color.gray

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.deviceGreen)
            .cornerRadius(40)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    func panelStyle() -> some View {
        self
            .background(Color.panelDark)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
    }

    func slotStyle() -> some View {
        self
            .background(Color.panelDark)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Blur View

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
