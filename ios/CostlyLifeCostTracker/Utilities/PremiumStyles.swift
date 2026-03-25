import SwiftUI

struct PremiumButtonStyle: ButtonStyle {
    let scale: CGFloat
    let opacity: CGFloat

    init(scale: CGFloat = 0.97, opacity: CGFloat = 0.85) {
        self.scale = scale
        self.opacity = opacity
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct PremiumPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PremiumCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .allowsHitTesting(false)
            )
            .clipShape(.rect(cornerRadius: 0))
            .onAppear {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func premiumShimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
                    .shadow(color: Color.black.opacity(0.02), radius: 1, y: 0)
            )
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
            )
    }

    func frostCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                .ultraThinMaterial,
                in: .rect(cornerRadius: cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.7), Color.white.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
    }

    func premiumCardStyle(cornerRadius: CGFloat = 20) -> some View {
        self.glassCard(cornerRadius: cornerRadius)
    }

    func premiumStagger(appeared: Bool, index: Int, baseDelay: Double = 0.04) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.78).delay(Double(index) * baseDelay),
                value: appeared
            )
    }
}
