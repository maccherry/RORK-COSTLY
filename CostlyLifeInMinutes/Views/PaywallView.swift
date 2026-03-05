import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly
    @State private var trialEnabled: Bool = true
    @State private var appeared: Bool = false

    let store: DataStore
    let allowDismiss: Bool
    var onSubscribe: (() -> Void)?

    init(store: DataStore, allowDismiss: Bool = false, onSubscribe: (() -> Void)? = nil) {
        self.store = store
        self.allowDismiss = allowDismiss
        self.onSubscribe = onSubscribe
    }

    nonisolated enum Plan: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

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
        }
        .interactiveDismissDisabled(!allowDismiss)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(GlassTheme.bgPrimary)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                    )

                Image(systemName: "hourglass")
                    .font(.system(size: 30, weight: .ultraLight))
                    .foregroundStyle(GlassTheme.textSecondary)
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)

            VStack(spacing: 8) {
                Text("Unlock Costly")
                    .font(.satoshi(.light, size: 30))
                    .foregroundStyle(GlassTheme.textPrimary)

                Text("See the true cost of your choices.")
                    .font(.satoshi(.regular, size: 14))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "camera.viewfinder",
                title: "Instant AI Scanning",
                subtitle: "Snap anything you eat, drink, or do — AI reveals the exact minutes it costs your life in real time"
            )
            featureDivider
            featureRow(
                icon: "waveform.path.ecg",
                title: "Your True Biological Age",
                subtitle: "Driven by real-time health intelligence from Apple Health and your connected wearable — precision aging, redefined"
            )
            featureDivider
            featureRow(
                icon: "flame.fill",
                title: "Every Minute Visualized",
                subtitle: "See a live timeline of minutes gained and lost — the accountability system your future self will thank you for"
            )

        }
        .glassCard(cornerRadius: 18)
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(GlassTheme.accent)
                .frame(width: 36, height: 36)
                .background(GlassTheme.accent.opacity(0.06))
                .clipShape(.rect(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.satoshi(.bold, size: 14))
                    .foregroundStyle(GlassTheme.textPrimary)
                Text(subtitle)
                    .font(.satoshi(.regular, size: 12))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var featureDivider: some View {
        Rectangle()
            .fill(GlassTheme.separator.opacity(0.5))
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
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.satoshi(.bold, size: 8))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(GlassTheme.positive)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 14)
                }

                Text(plan.rawValue)
                    .font(.satoshi(.medium, size: 10))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.satoshi(.bold, size: 20))
                        .foregroundStyle(GlassTheme.textPrimary)
                    Text(period)
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                Text(subtitle)
                    .font(.satoshi(.regular, size: 10))
                    .foregroundStyle(GlassTheme.textTertiary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedPlan == plan ? GlassTheme.bgPrimary : .white)
                    .shadow(color: Color.black.opacity(selectedPlan == plan ? 0.06 : 0.02), radius: 12, y: 4)
            )
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedPlan == plan
                            ? GlassTheme.textPrimary.opacity(0.3)
                            : GlassTheme.separator,
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
                    .foregroundStyle(GlassTheme.textPrimary)
                Text("Subscription starts automatically after trial ends")
                    .font(.satoshi(.regular, size: 11))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $trialEnabled)
                .labelsHidden()
                .tint(GlassTheme.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 14)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.2), trigger: trialEnabled)
    }

    private var subscribeButton: some View {
        VStack(spacing: 10) {
            Button {
                store.setSubscriptionActive(true)
                onSubscribe?()
                dismiss()
            } label: {
                Text(trialEnabled ? "Start 3-Day Free Trial" : "Subscribe Now")
                    .font(.satoshi(.bold, size: 17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(GlassTheme.textPrimary)
                    .clipShape(.rect(cornerRadius: 27))
            }
            .buttonStyle(PremiumCTAButtonStyle())
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.6), trigger: store.profile.hasActiveSubscription)

            Text(trialEnabled
                 ? "3-day free trial, then \(selectedPlan == .yearly ? "$39.99/year" : "$9.99/month"). Cancel anytime."
                 : "\(selectedPlan == .yearly ? "$39.99/year" : "$9.99/month"). Cancel anytime."
            )
                .font(.satoshi(.regular, size: 11))
                .foregroundStyle(GlassTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 14) {
            Button("Restore Purchases") {
                store.setSubscriptionActive(true)
                onSubscribe?()
                dismiss()
            }
            .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
            Text("·").foregroundStyle(GlassTheme.separator)
            Button("Terms") { }
                .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
            Text("·").foregroundStyle(GlassTheme.separator)
            Button("Privacy") { }
                .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
        }
        .font(.satoshi(.regular, size: 11))
        .foregroundStyle(GlassTheme.textTertiary)
    }
}
