import SwiftUI

struct ProfileView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var showPaywall: Bool = false
    @State private var appeared: Bool = false

    private var bioAge: Double {
        store.profile.biologicalAge(netMinutes: store.allTimeNetMinutes + healthKit.healthMinutesBalance)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                        .padding(.top, 16)
                        .premiumStagger(appeared: appeared, index: 0)

                    ageCard
                        .premiumStagger(appeared: appeared, index: 1)

                    if healthKit.isAuthorized {
                        healthCard
                            .premiumStagger(appeared: appeared, index: 2)
                    }

                    lifeStatsCard
                        .premiumStagger(appeared: appeared, index: 3)

                    settingsCard
                        .premiumStagger(appeared: appeared, index: 4)

                    footer
                        .premiumStagger(appeared: appeared, index: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(store: store)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
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

                Text(String(store.profile.name.prefix(1)).uppercased())
                    .font(.satoshi(.light, size: 28))
                    .foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 4) {
                Text(store.profile.name)
                    .font(.satoshi(.bold, size: 22))
                    .foregroundStyle(.white)

                Text("Member since \(store.profile.memberSince, format: .dateTime.month(.wide).year())")
                    .font(.satoshi(.regular, size: 12))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
    }

    private var ageCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("CHRONOLOGICAL")
                    .font(.satoshi(.bold, size: 8))
                    .foregroundStyle(.white.opacity(0.2))
                    .tracking(1)
                Text(String(format: "%.1f", store.profile.preciseAge))
                    .font(.satoshi(.light, size: 30))
                    .foregroundStyle(.white.opacity(0.45))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(.white.opacity(0.04))
                .frame(width: 0.5, height: 48)

            VStack(spacing: 6) {
                Text("BIOLOGICAL")
                    .font(.satoshi(.bold, size: 8))
                    .foregroundStyle(.white.opacity(0.2))
                    .tracking(1)
                Text(String(format: "%.1f", bioAge))
                    .font(.satoshi(.light, size: 30))
                    .foregroundStyle(bioAge <= store.profile.preciseAge ? GlassTheme.positive : GlassTheme.negative)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 22)
        .premiumCardStyle(cornerRadius: 18)
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("HEALTH DATA")

            VStack(spacing: 0) {
                infoRow(icon: "figure.walk", label: "Steps Today", value: "\(healthKit.stepCount)", color: .white.opacity(0.5))
                divider
                infoRow(icon: "flame.fill", label: "Active Minutes", value: "\(healthKit.activeMinutes) min", color: GlassTheme.positive)
                if healthKit.sleepHours > 0 {
                    divider
                    infoRow(icon: "bed.double.fill", label: "Sleep", value: String(format: "%.1f hrs", healthKit.sleepHours), color: healthKit.sleepHours >= 7 ? GlassTheme.positive : GlassTheme.negative)
                }
                if healthKit.heartRate > 0 {
                    divider
                    infoRow(icon: "heart.fill", label: "Heart Rate", value: "\(Int(healthKit.heartRate)) bpm", color: .white.opacity(0.5))
                }
                divider
                infoRow(icon: "plus.circle.fill", label: "Health Bonus", value: GlassTheme.formatMinutes(healthKit.healthMinutesBalance) + " min", color: GlassTheme.minuteColor(healthKit.healthMinutesBalance))
            }
            .premiumCardStyle(cornerRadius: 14)
        }
    }

    private var lifeStatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("LIFE STATS")

            VStack(spacing: 0) {
                infoRow(icon: "arrow.up", label: "Minutes Gained", value: "+\(store.totalMinutesGained)", color: GlassTheme.positive)
                divider
                infoRow(icon: "arrow.down", label: "Minutes Lost", value: "\(store.totalMinutesLost)", color: GlassTheme.negative)
                divider
                infoRow(icon: "equal", label: "Net Balance", value: formatSigned(store.allTimeNetMinutes), color: GlassTheme.minuteColor(store.allTimeNetMinutes))
                divider

                let days = Double(store.allTimeNetMinutes) / 1440.0
                infoRow(
                    icon: "calendar",
                    label: days >= 0 ? "Days Added" : "Days Removed",
                    value: String(format: "%+.1f", days),
                    color: GlassTheme.minuteColor(store.allTimeNetMinutes)
                )
                divider

                let remaining = store.profile.estimatedLifeMinutesRemaining
                infoRow(icon: "hourglass", label: "Est. Life Remaining", value: formatLargeMinutes(remaining), color: .white.opacity(0.4))
            }
            .premiumCardStyle(cornerRadius: 14)
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SETTINGS")

            VStack(spacing: 0) {
                settingsRow(icon: "crown", label: "Subscription", detail: store.profile.hasActiveSubscription ? "Active" : "Free") {
                    showPaywall = true
                }
                divider
                settingsRow(icon: "arrow.clockwise", label: "Restore Purchases", detail: nil) {
                    store.setSubscriptionActive(true)
                }
                divider
                settingsRow(icon: "heart.text.clipboard", label: "Health Access", detail: healthKit.isAuthorized ? "Connected" : "Off") {
                    Task { await healthKit.requestAuthorization() }
                }
                divider
                settingsRow(icon: "doc.text", label: "Terms of Service", detail: nil) { }
                divider
                settingsRow(icon: "hand.raised", label: "Privacy Policy", detail: nil) { }
            }
            .premiumCardStyle(cornerRadius: 14)
        }
    }

    private func settingsRow(icon: String, label: String, detail: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 24)

                Text(label)
                    .font(.satoshi(.regular, size: 14))
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()

                if let detail {
                    Text(detail)
                        .font(.satoshi(.regular, size: 12))
                        .foregroundStyle(.white.opacity(0.2))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.12))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(PremiumButtonStyle(scale: 0.98, opacity: 0.8))
        .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: showPaywall)
    }

    private func infoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.satoshi(.regular, size: 13))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.satoshi(.medium, size: 14))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.03))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.satoshi(.bold, size: 9))
            .foregroundStyle(.white.opacity(0.2))
            .tracking(1.5)
    }

    private var footer: some View {
        VStack(spacing: 3) {
            Text("Costly")
                .font(.satoshi(.light, size: 13))
                .foregroundStyle(.white.opacity(0.12))
            Text("Version 1.0.0")
                .font(.satoshi(.regular, size: 10))
                .foregroundStyle(.white.opacity(0.06))
        }
        .padding(.top, 8)
    }

    private func formatSigned(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func formatLargeMinutes(_ minutes: Int) -> String {
        let years = minutes / 525960
        let remainingMonths = (minutes % 525960) / 43830
        return "\(years)y \(remainingMonths)m"
    }
}
