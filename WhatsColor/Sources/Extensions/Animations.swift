import SwiftUI

extension Animation {
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let mediumSpring = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let slowSpring = Animation.spring(response: 0.5, dampingFraction: 0.5)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    static let easeOut = Animation.easeOut(duration: 0.2)
}

struct BounceEffect: ViewModifier {
    @State private var isBouncing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isBouncing)
            .onTapGesture {
                isBouncing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isBouncing = false
                }
            }
    }
}

struct ShakeEffect: ViewModifier {
    @State private var isShaking = false

    func body(content: Content) -> some View {
        content
            .offset(x: isShaking ? -5 : 0)
            .animation(.easeInOut(duration: 0.05).repeatCount(3, autoreverses: true), value: isShaking)
            .onAppear {
                isShaking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isShaking = false
                }
            }
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

struct GlowEffect: ViewModifier {
    @State private var isGlowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: isGlowing ? .white : .clear, radius: isGlowing ? 10 : 0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isGlowing)
            .onAppear {
                isGlowing = true
            }
    }
}

struct SlideInEffect: ViewModifier {
    @State private var hasAppeared = false
    let from: Edge
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(x: hasAppeared ? 0 : (from == .leading ? -20 : 20))
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(delay), value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
    }
}

struct FadeInEffect: ViewModifier {
    @State private var hasAppeared = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3).delay(delay), value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
    }
}

struct ScaleInEffect: ViewModifier {
    @State private var hasAppeared = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(hasAppeared ? 1 : 0.5)
            .opacity(hasAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
    }
}

extension View {
    func bounce() -> some View {
        modifier(BounceEffect())
    }

    func shake() -> some View {
        modifier(ShakeEffect())
    }

    func pulse() -> some View {
        modifier(PulseEffect())
    }

    func glow() -> some View {
        modifier(GlowEffect())
    }

    func slideIn(from: Edge = .trailing, delay: Double = 0) -> some View {
        modifier(SlideInEffect(from: from, delay: delay))
    }

    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInEffect(delay: delay))
    }

    func scaleIn(delay: Double = 0) -> some View {
        modifier(ScaleInEffect(delay: delay))
    }
}

// MARK: - Specific Animation Views

struct BouncingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RevealAnimation: View {
    let isVisible: Bool
    let duration: Double = 0.5

    var body: some View {
        VStack {
            if isVisible {
                Text("")
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: duration, dampingFraction: 0.7), value: isVisible)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Bounce").bounce()
        Text("Shake").shake()
        Text("Pulse").pulse()
        Text("Glow").glow()
    }
    .padding()
}
