import SwiftUI

struct ShareCardView: View {
    let activityName: String
    let activityIcon: String
    let minutesDelta: Int
    let costlyAge: Double

    private var isPositive: Bool { minutesDelta >= 0 }
    private var deltaText: String {
        minutesDelta >= 0 ? "+\(minutesDelta)" : "\(minutesDelta)"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.08),
                    Color(red: 0.03, green: 0.03, blue: 0.05),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 6, height: 6)
                    Text("COSTLY")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .tracking(6)
                        .foregroundStyle(.white.opacity(0.35))
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 6, height: 6)
                }

                Spacer().frame(height: 60)

                ZStack {
                    Circle()
                        .stroke(
                            RadialGradient(
                                colors: [
                                    (isPositive ? Color(red: 0.2, green: 0.75, blue: 0.5) : Color(red: 0.9, green: 0.32, blue: 0.35)).opacity(0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 90
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 180, height: 180)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (isPositive ? Color(red: 0.2, green: 0.75, blue: 0.5) : Color(red: 0.9, green: 0.32, blue: 0.35)).opacity(0.06),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)

                    VStack(spacing: 4) {
                        Image(systemName: activityIcon)
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(deltaText)
                            .font(.system(size: 64, weight: .thin, design: .serif))
                            .foregroundStyle(isPositive ? Color(red: 0.2, green: 0.75, blue: 0.5) : Color(red: 0.9, green: 0.32, blue: 0.35))

                        Text("MINUTES")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(4)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                Spacer().frame(height: 40)

                Text(activityName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer().frame(height: 12)

                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 40, height: 1)

                Spacer().frame(height: 24)

                VStack(spacing: 6) {
                    Text("COSTLY AGE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.25))

                    Text(String(format: "%.1f", costlyAge))
                        .font(.system(size: 32, weight: .thin, design: .serif))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("costly.app")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .padding(.bottom, 60)
            }

            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (isPositive ? Color(red: 0.2, green: 0.75, blue: 0.5) : Color(red: 0.9, green: 0.32, blue: 0.35)).opacity(0.04),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(x: 120, y: -120)
                }
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .frame(width: 1080 / 3, height: 1920 / 3)
    }
}

struct ShareCardGenerator {
    @MainActor
    static func renderImage(activityName: String, activityIcon: String, minutesDelta: Int, costlyAge: Double) -> UIImage? {
        let card = ShareCardView(
            activityName: activityName,
            activityIcon: activityIcon,
            minutesDelta: minutesDelta,
            costlyAge: costlyAge
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
