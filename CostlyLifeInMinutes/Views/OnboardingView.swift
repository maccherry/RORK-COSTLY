import SwiftUI

struct OnboardingView: View {
    @State private var currentPage: Int = 0
    @State private var userName: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now
    @State private var showPaywall: Bool = false
    @State private var tickingMinutes: Int = 42_075_360
    @State private var pageAppeared: [Bool] = [false, false, false, false]
    let store: DataStore
    var onComplete: () -> Void

    private let totalPages = 4

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            TabView(selection: $currentPage) {
                hookPage.tag(0)
                impactPage.tag(1)
                proofPage.tag(2)
                personalizationPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentPage)

            if currentPage < 3 {
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        progressDots

                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.satoshi(.bold, size: 17))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(GlassTheme.textPrimary)
                                .clipShape(.rect(cornerRadius: 27))
                        }
                        .buttonStyle(PremiumCTAButtonStyle())
                        .sensoryFeedback(.impact(weight: .medium, intensity: 0.5), trigger: currentPage)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 44)
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            if store.profile.hasCompletedOnboarding {
                onComplete()
            }
        }) {
            PaywallView(store: store)
        }
        .onChange(of: currentPage) { _, newPage in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                if newPage < pageAppeared.count {
                    pageAppeared[newPage] = true
                }
            }
        }
        .onAppear {
            pageAppeared[0] = true
        }
    }

    private var progressDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? GlassTheme.textPrimary : GlassTheme.separator)
                    .frame(width: index == currentPage ? 24 : 5, height: 5)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    private var hookPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 6) {
                    Text("\(tickingMinutes)")
                        .font(.satoshi(.light, size: 48))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(tickingMinutes)))
                    Text("minutes remaining")
                        .font(.satoshi(.medium, size: 13))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .tracking(0.5)
                }

                VStack(spacing: 10) {
                    Text("Every choice\nhas a price.")
                        .font(.satoshi(.light, size: 32))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("We measure it in minutes.")
                        .font(.satoshi(.regular, size: 15))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
            }
            .opacity(pageAppeared[0] ? 1 : 0)
            .offset(y: pageAppeared[0] ? 0 : 20)

            Spacer()
            Spacer().frame(height: 130)
        }
        .padding(.horizontal, 24)
        .onAppear { startCountdown() }
    }

    private var impactPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                VStack(spacing: 10) {
                    Text("Your habits\nshape your time.")
                        .font(.satoshi(.light, size: 32))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Every habit adds or subtracts\nfrom your life.")
                        .font(.satoshi(.regular, size: 14))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                HStack(spacing: 10) {
                    impactCard(icon: "figure.run", label: "30-min run", delta: "+26", isPositive: true)
                    impactCard(icon: "smoke", label: "Cigarette", delta: "-11", isPositive: false)
                }
            }
            .opacity(pageAppeared.count > 1 && pageAppeared[1] ? 1 : 0)
            .offset(y: pageAppeared.count > 1 && pageAppeared[1] ? 0 : 20)

            Spacer()
            Spacer().frame(height: 130)
        }
        .padding(.horizontal, 24)
    }

    private func impactCard(icon: String, label: String, delta: String, isPositive: Bool) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(GlassTheme.textTertiary)

            Text(delta)
                .font(.satoshi(.light, size: 36))
                .foregroundStyle(isPositive ? GlassTheme.positive : GlassTheme.negative)

            Text(label)
                .font(.satoshi(.medium, size: 12))
                .foregroundStyle(GlassTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .glassCard()
    }

    private var proofPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("See what your\nhabits really cost.")
                        .font(.satoshi(.light, size: 32))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Track. Measure. Reveal.")
                        .font(.satoshi(.regular, size: 14))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                VStack(spacing: 0) {
                    exampleRow(icon: "smoke", name: "Cigarette", delta: -11)
                    rowDivider
                    exampleRow(icon: "figure.run", name: "Morning Run", delta: +26)
                    rowDivider
                    exampleRow(icon: "wineglass", name: "Glass of Wine", delta: -5)
                    rowDivider
                    exampleRow(icon: "brain.head.profile", name: "Meditation", delta: +12)
                    rowDivider
                    exampleRow(icon: "cup.and.saucer", name: "Coffee", delta: -2)
                }
                .glassCard()
            }
            .opacity(pageAppeared.count > 2 && pageAppeared[2] ? 1 : 0)
            .offset(y: pageAppeared.count > 2 && pageAppeared[2] ? 0 : 20)

            Spacer()
            Spacer().frame(height: 130)
        }
        .padding(.horizontal, 24)
    }

    private var personalizationPage: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                VStack(spacing: 32) {
                    VStack(spacing: 10) {
                        Text("Let's set up\nyour clock.")
                            .font(.satoshi(.light, size: 32))
                            .foregroundStyle(GlassTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        Text("We'll calculate your biological age\nand time remaining.")
                            .font(.satoshi(.regular, size: 14))
                            .foregroundStyle(GlassTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("YOUR NAME")
                                .font(.satoshi(.bold, size: 9))
                                .foregroundStyle(GlassTheme.textTertiary)
                                .tracking(1.5)

                            TextField("", text: $userName, prompt: Text("Enter your name").foregroundStyle(GlassTheme.textTertiary))
                                .font(.satoshi(.regular, size: 16))
                                .foregroundStyle(GlassTheme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .glassCard(cornerRadius: 14)
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            Text("DATE OF BIRTH")
                                .font(.satoshi(.bold, size: 9))
                                .foregroundStyle(GlassTheme.textTertiary)
                                .tracking(1.5)

                            DatePicker("", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .glassCard(cornerRadius: 14)
                        }
                    }

                    progressDots
                        .padding(.top, 4)

                    Button {
                        store.completeOnboarding(name: userName.isEmpty ? "You" : userName, birthDate: birthDate)
                        showPaywall = true
                    } label: {
                        Text("See My Time")
                            .font(.satoshi(.bold, size: 17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(GlassTheme.textPrimary)
                            .clipShape(.rect(cornerRadius: 27))
                    }
                    .buttonStyle(PremiumCTAButtonStyle())
                    .sensoryFeedback(.impact(weight: .heavy, intensity: 0.6), trigger: showPaywall)
                }
                .opacity(pageAppeared.count > 3 && pageAppeared[3] ? 1 : 0)
                .offset(y: pageAppeared.count > 3 && pageAppeared[3] ? 0 : 20)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
    }

    private func exampleRow(icon: String, name: String, delta: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(GlassTheme.textTertiary)
                .frame(width: 30)
            Text(name)
                .font(.satoshi(.regular, size: 14))
                .foregroundStyle(GlassTheme.textPrimary)
            Spacer()
            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                .font(.satoshi(.medium, size: 16))
                .foregroundStyle(delta >= 0 ? GlassTheme.positive : GlassTheme.negative)
            Text("min")
                .font(.satoshi(.regular, size: 11))
                .foregroundStyle(GlassTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(GlassTheme.separator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 58)
    }

    private func startCountdown() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.smooth(duration: 0.8)) {
                    tickingMinutes -= 1
                }
            }
        }
    }
}
