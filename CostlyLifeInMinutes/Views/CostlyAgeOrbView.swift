import SwiftUI

struct CostlyAgeOrbView: View {
    let costlyAge: Double
    let delta: Double
    let isHealthConnected: Bool

    @State private var appeared: Bool = false
    @State private var time: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var ringRotations: [CGFloat] = [0, 0, 0, 0]
    @State private var breathe: CGFloat = 0

    private var orbColor: Color {
        delta >= 0 ? GlassTheme.positive : GlassTheme.negative
    }

    private var deltaText: String {
        if abs(delta) < 0.1 { return "on track" }
        return String(format: "%.1f years %@", abs(delta), delta >= 0 ? "younger" : "older")
    }

    private let ringCount = 4
    private let ringConfigs: [(radius: CGFloat, width: CGFloat, speed: CGFloat, dashPattern: [CGFloat], opacity: Double)] = [
        (radius: 130, width: 0.5, speed: 1.0, dashPattern: [2, 6], opacity: 0.12),
        (radius: 112, width: 0.8, speed: -0.6, dashPattern: [1, 0], opacity: 0.08),
        (radius: 95, width: 0.4, speed: 1.4, dashPattern: [4, 12], opacity: 0.15),
        (radius: 78, width: 1.2, speed: -0.3, dashPattern: [1, 0], opacity: 0.05),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ambientGlow
                concentricRings
                orbitingMotes
                arcGauge
                ageDisplay
            }
            .frame(height: 320)
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
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                breathe = 1.0
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.04
            }
            startRingRotations()
        }
    }

    private func startRingRotations() {
        for i in 0..<ringCount {
            let speed = ringConfigs[i].speed
            let duration = 30.0 / abs(Double(speed))
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                ringRotations[i] = speed > 0 ? 360 : -360
            }
        }
    }

    private var ambientGlow: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            let innerGlow = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [
                    orbColor.opacity(0.08),
                    orbColor.opacity(0.03),
                    orbColor.opacity(0.01),
                    .clear,
                ]),
                center: center,
                startRadius: 0,
                endRadius: 150
            )
            context.fill(Circle().path(in: CGRect(x: center.x - 150, y: center.y - 150, width: 300, height: 300)), with: innerGlow)

            let coreGlow = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [
                    .white.opacity(0.06),
                    .white.opacity(0.02),
                    .clear,
                ]),
                center: center,
                startRadius: 0,
                endRadius: 60
            )
            context.fill(Circle().path(in: CGRect(x: center.x - 60, y: center.y - 60, width: 120, height: 120)), with: coreGlow)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(pulseScale)
    }

    private var concentricRings: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { index in
                let config = ringConfigs[index]
                let breathOffset = sin(breathe * .pi + CGFloat(index) * 0.8) * 3

                Circle()
                    .stroke(
                        orbColor.opacity(config.opacity),
                        style: StrokeStyle(
                            lineWidth: config.width,
                            lineCap: .round,
                            dash: config.dashPattern
                        )
                    )
                    .frame(
                        width: (config.radius + breathOffset) * 2,
                        height: (config.radius + breathOffset) * 2
                    )
                    .rotationEffect(.degrees(Double(ringRotations[index])))
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var orbitingMotes: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                let motes: [(orbit: CGFloat, speed: Double, size: CGFloat, phase: Double, brightness: Double)] = [
                    (orbit: 130, speed: 0.15, size: 2.5, phase: 0.0, brightness: 0.7),
                    (orbit: 130, speed: 0.15, size: 1.5, phase: 3.14, brightness: 0.4),
                    (orbit: 112, speed: -0.22, size: 2.0, phase: 1.2, brightness: 0.5),
                    (orbit: 95, speed: 0.30, size: 3.0, phase: 0.8, brightness: 0.8),
                    (orbit: 95, speed: 0.30, size: 1.5, phase: 2.5, brightness: 0.35),
                    (orbit: 78, speed: -0.18, size: 2.0, phase: 2.0, brightness: 0.6),
                ]

                for mote in motes {
                    let angle = elapsed * mote.speed + mote.phase
                    let x = center.x + cos(angle) * mote.orbit
                    let y = center.y + sin(angle) * mote.orbit

                    let flicker = 0.6 + 0.4 * sin(elapsed * 2.5 + mote.phase * 3)
                    let alpha = mote.brightness * flicker

                    let glowRect = CGRect(
                        x: x - mote.size * 3,
                        y: y - mote.size * 3,
                        width: mote.size * 6,
                        height: mote.size * 6
                    )
                    let glowShading = GraphicsContext.Shading.radialGradient(
                        Gradient(colors: [
                            .white.opacity(alpha * 0.5),
                            .white.opacity(alpha * 0.15),
                            .clear,
                        ]),
                        center: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: mote.size * 3
                    )
                    context.fill(Circle().path(in: glowRect), with: glowShading)

                    let dotRect = CGRect(
                        x: x - mote.size / 2,
                        y: y - mote.size / 2,
                        width: mote.size,
                        height: mote.size
                    )
                    context.fill(
                        Circle().path(in: dotRect),
                        with: .color(.white.opacity(alpha))
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var arcGauge: some View {
        let progress = min(max((delta + 5) / 10.0, 0), 1.0)

        return ZStack {
            Circle()
                .trim(from: 0.05, to: 0.95)
                .stroke(
                    GlassTheme.textTertiary.opacity(0.06),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(90))

            Circle()
                .trim(from: 0.05, to: 0.05 + 0.9 * progress)
                .stroke(
                    AngularGradient(
                        colors: [orbColor.opacity(0.0), orbColor.opacity(0.6)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(90))

            let endAngle = Angle.degrees(90 + (0.05 + 0.9 * progress) * 360)
            let endX = cos(endAngle.radians) * 130
            let endY = sin(endAngle.radians) * 130

            Circle()
                .fill(orbColor)
                .frame(width: 5, height: 5)
                .shadow(color: orbColor.opacity(0.6), radius: 6)
                .offset(x: endX, y: endY)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: delta)
    }

    private var ageDisplay: some View {
        VStack(spacing: 6) {
            Text(String(format: "%.1f", costlyAge))
                .font(.satoshi(.light, size: 58))
                .foregroundStyle(GlassTheme.textPrimary)
                .contentTransition(.numericText())
                .monospacedDigit()
                .scaleEffect(appeared ? 1.0 : 0.7)
                .opacity(appeared ? 1 : 0)
                .overlay(
                    Text(String(format: "%.1f", costlyAge))
                        .font(.satoshi(.light, size: 58))
                        .foregroundStyle(orbColor.opacity(0.08))
                        .monospacedDigit()
                        .blur(radius: 12)
                        .allowsHitTesting(false)
                )

            Text("COSTLY AGE")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(3)
                .opacity(appeared ? 1 : 0)

            HStack(spacing: 5) {
                if abs(delta) >= 0.1 {
                    Image(systemName: delta >= 0 ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(deltaText)
                    .font(.satoshi(.medium, size: 12))
            }
            .foregroundStyle(orbColor.opacity(0.8))
            .opacity(appeared ? 1 : 0)
            .padding(.top, 2)
        }
    }
}
