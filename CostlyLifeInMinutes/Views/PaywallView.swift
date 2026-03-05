import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly
    @State private var trialEnabled: Bool = true
    @State private var appeared: Bool = false
    @State private var showOKXOffer: Bool = false
    @State private var dismissAttempted: Bool = false
    let store: DataStore

    nonisolated enum Plan: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 48)

                    heroSection
                        .premiumStagger(appeared: appeared, index: 0)

                    featuresSection
                        .premiumStagger(appeared: appeared, index: 1)

                    plansSection
                        .premiumStagger(appeared: appeared, index: 2)

                    trialToggle
                        .premiumStagger(appeared: appeared, index: 3)

                    subscribeButton
                        .premiumStagger(appeared: appeared, index: 4)

                    footerLinks
                        .premiumStagger(appeared: appeared, index: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        handleDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PremiumButtonStyle(scale: 0.85, opacity: 0.6))
                    .padding(.trailing, 20)
                    .padding(.top, 14)
                }
                Spacer()
            }

            if showOKXOffer {
                okxOfferOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func handleDismiss() {
        if !dismissAttempted {
            dismissAttempted = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showOKXOffer = true
            }
        } else {
            dismiss()
        }
    }

    private var heroSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.06))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )

                Image(systemName: "hourglass")
                    .font(.system(size: 30, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)

            VStack(spacing: 8) {
                Text("Unlock Costly")
                    .font(.satoshi(.light, size: 30))
                    .foregroundStyle(.white)

                Text("Track every minute gained and lost.\nSee the true cost of your choices.")
                    .font(.satoshi(.regular, size: 14))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(icon: "camera.fill", title: "AI Scan & Log", subtitle: "Point your camera at any food or drink")
            featureDivider
            featureRow(icon: "heart.text.clipboard", title: "Biological Age", subtitle: "Track your real age based on habits")
            featureDivider
            featureRow(icon: "heart.fill", title: "Apple Health", subtitle: "Sync steps, sleep, and workouts")
            featureDivider
            featureRow(icon: "chart.bar.fill", title: "Life Stats", subtitle: "Deep insights into your daily habits")
        }
        .premiumCardStyle(cornerRadius: 18)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.03))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.satoshi(.medium, size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                Text(subtitle)
                    .font(.satoshi(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.25))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var featureDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.03))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }

    private var plansSection: some View {
        HStack(spacing: 10) {
            planCard(
                plan: .monthly,
                price: "$9.99",
                period: "/mo",
                subtitle: "$119.88/year",
                badge: nil
            )
            planCard(
                plan: .yearly,
                price: "$39.99",
                period: "/yr",
                subtitle: "Just $3.33/mo",
                badge: "BEST VALUE"
            )
        }
    }

    private func planCard(plan: Plan, price: String, period: String, subtitle: String, badge: String?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { selectedPlan = plan }
        } label: {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.satoshi(.bold, size: 8))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(GlassTheme.positive.opacity(0.7))
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 14)
                }

                Text(plan.rawValue)
                    .font(.satoshi(.medium, size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(1)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.satoshi(.bold, size: 22))
                        .foregroundStyle(.white)
                    Text(period)
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Text(subtitle)
                    .font(.satoshi(.regular, size: 10))
                    .foregroundStyle(.white.opacity(0.2))

                Spacer().frame(height: 2)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(white: selectedPlan == plan ? 0.09 : 0.04))
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedPlan == plan
                            ? LinearGradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: selectedPlan == plan ? 1.5 : 0.5
                    )
            )
            .scaleEffect(selectedPlan == plan ? 1.0 : 0.97)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selectedPlan)
        }
        .buttonStyle(PremiumCardButtonStyle())
        .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: selectedPlan)
    }

    private var trialToggle: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("3-Day Free Trial")
                    .font(.satoshi(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.85))
                Text("Subscription starts automatically after trial ends")
                    .font(.satoshi(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.25))
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $trialEnabled)
                .labelsHidden()
                .tint(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .premiumCardStyle(cornerRadius: 14)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.2), trigger: trialEnabled)
    }

    private var subscribeButton: some View {
        VStack(spacing: 10) {
            Button {
                store.setSubscriptionActive(true)
                dismiss()
            } label: {
                Text(trialEnabled ? "Start 3-Day Free Trial" : "Subscribe Now")
                    .font(.satoshi(.bold, size: 17))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.white)
                    .clipShape(.rect(cornerRadius: 27))
            }
            .buttonStyle(PremiumCTAButtonStyle())
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.6), trigger: store.profile.hasActiveSubscription)

            Text(trialEnabled
                 ? "3-day free trial, then \(selectedPlan == .yearly ? "$39.99/year" : "$9.99/month"). Cancel anytime."
                 : "\(selectedPlan == .yearly ? "$39.99/year" : "$9.99/month"). Cancel anytime."
            )
                .font(.satoshi(.regular, size: 11))
                .foregroundStyle(.white.opacity(0.2))
                .multilineTextAlignment(.center)
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 14) {
            Button("Restore Purchases") {
                store.setSubscriptionActive(true)
                dismiss()
            }
            .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
            Text("·").foregroundStyle(.white.opacity(0.12))
            Button("Terms") { }
                .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
            Text("·").foregroundStyle(.white.opacity(0.12))
            Button("Privacy") { }
                .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
        }
        .font(.satoshi(.regular, size: 11))
        .foregroundStyle(.white.opacity(0.2))
    }

    // MARK: - OKX Popup Offer

    private var okxOfferOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showOKXOffer = false
                    }
                }

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    Spacer().frame(height: 4)

                    ZStack {
                        Circle()
                            .fill(Color(white: 0.08))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )

                        Text("OKX")
                            .font(.satoshi(.black, size: 16))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    VStack(spacing: 8) {
                        Text("Wait -- get 1 year free")
                            .font(.satoshi(.bold, size: 22))
                            .foregroundStyle(.white)

                        Text("Sign up with OKX and unlock Costly Premium for an entire year, completely free.")
                            .font(.satoshi(.regular, size: 14))
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    VStack(spacing: 0) {
                        okxPerk(icon: "crown.fill", text: "Full Premium access for 12 months")
                        perkDivider
                        okxPerk(icon: "banknote.fill", text: "Unlock the Time Bank")
                        perkDivider
                        okxPerk(icon: "arrow.triangle.2.circlepath", text: "Redeem minutes to USDC monthly")
                    }
                    .premiumCardStyle(cornerRadius: 14)

                    Button {
                        if let url = URL(string: "https://www.okx.com/join") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Claim Free Year")
                                .font(.satoshi(.bold, size: 16))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white)
                        .clipShape(.rect(cornerRadius: 26))
                    }
                    .buttonStyle(PremiumCTAButtonStyle())
                    .sensoryFeedback(.impact(weight: .heavy, intensity: 0.6), trigger: showOKXOffer)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showOKXOffer = false
                        }
                    } label: {
                        Text("No thanks")
                            .font(.satoshi(.regular, size: 13))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.6))

                    Spacer().frame(height: 4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(Color(white: 0.06))
                .clipShape(.rect(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .premiumShimmer()
            }
            .padding(.horizontal, 28)
        }
    }

    private func okxPerk(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.04))
                .clipShape(.rect(cornerRadius: 7))

            Text(text)
                .font(.satoshi(.medium, size: 13))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var perkDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.03))
            .frame(height: 0.5)
            .padding(.leading, 54)
    }
}
