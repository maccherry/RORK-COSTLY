import SwiftUI

struct SplashView: View {
    @State private var showTitle: Bool = false
    @State private var showTagline: Bool = false
    @State private var showLine: Bool = false
    @State private var dismissSplash: Bool = false
    @State private var titleScale: CGFloat = 0.92
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Costly")
                    .font(.satoshi(.light, size: 52))
                    .foregroundStyle(.white)
                    .opacity(showTitle ? 1 : 0)
                    .scaleEffect(showTitle ? 1 : titleScale)
                    .blur(radius: showTitle ? 0 : 6)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0), Color.white.opacity(0.2), Color.white.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: showLine ? 60 : 0, height: 1)
                    .padding(.vertical, 14)

                Text("The cost of living.")
                    .font(.satoshi(.regular, size: 15))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(1)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 10)
            }
        }
        .opacity(dismissSplash ? 0 : 1)
        .scaleEffect(dismissSplash ? 1.05 : 1)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.75).delay(0.4)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(1.2)) {
                showLine = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.6)) {
                showTagline = true
            }
            Task {
                try? await Task.sleep(for: .seconds(3.2))
                withAnimation(.easeOut(duration: 0.5)) {
                    dismissSplash = true
                }
                try? await Task.sleep(for: .seconds(0.5))
                onComplete()
            }
        }
    }
}
