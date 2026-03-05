import SwiftUI

struct CostlyAgeOrbView: View {
    let costlyAge: Double
    let delta: Double
    let isHealthConnected: Bool
    @State private var phase: CGFloat = 0
    @State private var appeared: Bool = false
    @State private var particlePhase: CGFloat = 0

    private var orbColor: Color {
        delta >= 0 ? GlassTheme.positive : GlassTheme.negative
    }

    private var deltaText: String {
        if abs(delta) < 0.1 { return "on track" }
        return String(format: "%.1f years %@", abs(delta), delta >= 0 ? "younger" : "older")
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                orbBackground
                particleField
                orbBlob
                ageDisplay
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)

            if !isHealthConnected {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.clipboard")
                        .font(.system(size: 11))
                    Text("Connect Health to refine your Costly Age")
                        .font(.satoshi(.regular, size: 11))
                }
                .foregroundStyle(GlassTheme.textTertiary)
                .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                particlePhase = .pi * 2
            }
        }
    }

    private var orbBackground: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius: CGFloat = 130

            for i in stride(from: maxRadius, through: 20, by: -4) {
                let fraction = i / maxRadius
                let opacity = 0.02 * fraction
                let rect = CGRect(
                    x: center.x - i,
                    y: center.y - i,
                    width: i * 2,
                    height: i * 2
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(orbColor.opacity(opacity))
                )
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var particleField: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let time = particlePhase

            for i in 0..<60 {
                let seed = Double(i) * 1.618033988749
                let baseAngle = seed * .pi * 2
                let orbitRadius: CGFloat = CGFloat(40 + (seed.truncatingRemainder(dividingBy: 1.0)) * 90)

                let wobble = sin(time * 0.5 + seed * 3) * 8
                let angle = baseAngle + time * (0.3 + seed.truncatingRemainder(dividingBy: 0.4))

                let x = center.x + cos(angle) * (orbitRadius + wobble)
                let y = center.y + sin(angle) * (orbitRadius + wobble) * 0.95

                let distFromCenter = hypot(x - center.x, y - center.y)
                let maxDist: CGFloat = 130
                guard distFromCenter < maxDist else { continue }

                let fadeFactor = 1.0 - (distFromCenter / maxDist)
                let flickerAlpha = 0.15 + 0.6 * fadeFactor + sin(time * 2 + seed * 5) * 0.15
                let particleSize: CGFloat = CGFloat(1.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 2.5)

                let rect = CGRect(x: x - particleSize / 2, y: y - particleSize / 2, width: particleSize, height: particleSize)
                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(flickerAlpha))
                )
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var orbBlob: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius: CGFloat = 100
            let time = phase

            var path = Path()
            let segments = 120

            for i in 0...segments {
                let angle = (CGFloat(i) / CGFloat(segments)) * .pi * 2

                let r = baseRadius
                    + sin(angle * 3 + time) * 8
                    + cos(angle * 5 - time * 0.7) * 5
                    + sin(angle * 7 + time * 1.3) * 3

                let x = center.x + cos(angle) * r
                let y = center.y + sin(angle) * r

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()

            context.fill(path, with: .color(orbColor.opacity(0.06)))

            context.stroke(
                path,
                with: .color(orbColor.opacity(0.5)),
                lineWidth: 1.5
            )

            let glowPath = path
            context.stroke(
                glowPath,
                with: .color(orbColor.opacity(0.15)),
                lineWidth: 6
            )
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1.0 : 0.85)
    }

    private var ageDisplay: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", costlyAge))
                .font(.satoshi(.light, size: 64))
                .foregroundStyle(GlassTheme.textPrimary)
                .contentTransition(.numericText())
                .monospacedDigit()
                .scaleEffect(appeared ? 1.0 : 0.8)
                .opacity(appeared ? 1 : 0)

            Text("COSTLY AGE")
                .font(.satoshi(.bold, size: 10))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(2.5)
                .opacity(appeared ? 1 : 0)

            HStack(spacing: 4) {
                if abs(delta) >= 0.1 {
                    Image(systemName: delta >= 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(deltaText)
                    .font(.satoshi(.medium, size: 13))
            }
            .foregroundStyle(orbColor)
            .opacity(appeared ? 1 : 0)
            .padding(.top, 2)
        }
    }
}
