import SwiftUI

struct TimeBankView: View {
    let store: DataStore
    @State private var appeared: Bool = false
    @State private var showOKXAlert: Bool = false
    @State private var pulseGlow: Bool = false

    private var redeemableMinutes: Int {
        max(store.allTimeNetMinutes, 0)
    }

    private var usdcValue: Double {
        store.usdcBalance
    }

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                        .padding(.top, 12)
                        .premiumStagger(appeared: appeared, index: 0)

                    if store.profile.okxRedeemed {
                        unlockedContent
                    } else {
                        lockedContent
                    }

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { pulseGlow = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Time Bank")
                    .font(.satoshi(.bold, size: 28))
                    .foregroundStyle(GlassTheme.textPrimary)
                Text("Earn rewards for healthy choices")
                    .font(.satoshi(.regular, size: 13))
                    .foregroundStyle(GlassTheme.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var unlockedContent: some View {
        VStack(spacing: 16) {
            balanceHero
                .premiumStagger(appeared: appeared, index: 1)
            howItWorksCard
                .premiumStagger(appeared: appeared, index: 2)
            rewardsBreakdown
                .premiumStagger(appeared: appeared, index: 3)
            redemptionCard
                .premiumStagger(appeared: appeared, index: 4)
            transactionHistory
                .premiumStagger(appeared: appeared, index: 5)
        }
    }

    private var balanceHero: some View {
        VStack(spacing: 6) {
            Text("\(redeemableMinutes)")
                .font(.satoshi(.light, size: 64))
                .foregroundStyle(GlassTheme.textPrimary)
                .contentTransition(.numericText())
                .monospacedDigit()

            Text("Redeemable minutes")
                .font(.satoshi(.regular, size: 13))
                .foregroundStyle(GlassTheme.textTertiary)

            HStack(spacing: 0) {
                let gained = store.totalMinutesGained
                let lost = abs(store.totalMinutesLost)
                let total = max(gained + lost, 1)

                Rectangle()
                    .fill(GlassTheme.positive.opacity(0.5))
                    .frame(width: CGFloat(gained) / CGFloat(total) * (UIScreen.main.bounds.width - 64), height: 4)
                Rectangle()
                    .fill(GlassTheme.negative.opacity(0.5))
                    .frame(height: 4)
            }
            .clipShape(Capsule())
            .padding(.top, 10)

            HStack {
                HStack(spacing: 4) {
                    Circle().fill(GlassTheme.positive.opacity(0.5)).frame(width: 6, height: 6)
                    Text("+\(store.totalMinutesGained) gained")
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(GlassTheme.negative.opacity(0.5)).frame(width: 6, height: 6)
                    Text("\(store.totalMinutesLost) lost")
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
            }
        }
        .padding(20)
        .glassCard()
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HOW IT WORKS")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(1.5)

            VStack(spacing: 0) {
                stepRow(number: "1", title: "Log healthy activities", detail: "Exercise, meditate, eat well. Gain minutes.", isLast: false)
                stepRow(number: "2", title: "Accumulate positive minutes", detail: "Your net balance grows as you make better choices.", isLast: false)
                stepRow(number: "3", title: "Redeem once per month", detail: "Convert your positive minutes to USDC rewards.", isLast: true)
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private func stepRow(number: String, title: String, detail: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(number)
                    .font(.satoshi(.bold, size: 13))
                    .foregroundStyle(GlassTheme.accent)
                    .frame(width: 24, height: 24)
                    .background(GlassTheme.accent.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.satoshi(.medium, size: 14))
                        .foregroundStyle(GlassTheme.textPrimary)
                    Text(detail)
                        .font(.satoshi(.regular, size: 11))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)

            if !isLast {
                Rectangle()
                    .fill(GlassTheme.separator.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 50)
            }
        }
    }

    private var rewardsBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR REWARDS")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(1.5)

            HStack(spacing: 10) {
                rewardTile(
                    value: String(format: "$%.2f", usdcValue),
                    label: "USDC Value",
                    sublabel: "1 min = $0.01",
                    color: GlassTheme.positive
                )
                rewardTile(
                    value: "FREE",
                    label: "Yearly Plan",
                    sublabel: "via OKX",
                    color: GlassTheme.accent
                )
            }
        }
    }

    private func rewardTile(value: String, label: String, sublabel: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.satoshi(.bold, size: 22))
                .foregroundStyle(color)
                .monospacedDigit()

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.satoshi(.medium, size: 12))
                    .foregroundStyle(GlassTheme.textSecondary)
                Text(sublabel)
                    .font(.satoshi(.regular, size: 10))
                    .foregroundStyle(GlassTheme.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }

    private var redemptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("REDEMPTION")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(1.5)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Monthly Payout")
                            .font(.satoshi(.medium, size: 14))
                            .foregroundStyle(GlassTheme.textPrimary)
                        Text("Redeem your positive minutes for USDC on the 1st of every month.")
                            .font(.satoshi(.regular, size: 12))
                            .foregroundStyle(GlassTheme.textTertiary)
                            .lineSpacing(2)
                    }
                    Spacer()
                }

                Button { } label: {
                    HStack(spacing: 6) {
                        Text("Redeem \(redeemableMinutes) min")
                            .font(.satoshi(.bold, size: 14))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(redeemableMinutes > 0 ? GlassTheme.textPrimary : GlassTheme.separator)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .buttonStyle(PremiumCTAButtonStyle())
                .sensoryFeedback(.impact(weight: .medium), trigger: redeemableMinutes)
                .disabled(redeemableMinutes == 0)

                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 9))
                    Text("Minimum 100 minutes required. Payouts arrive within 24 hours.")
                        .font(.satoshi(.regular, size: 10))
                }
                .foregroundStyle(GlassTheme.textTertiary)
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
    }

    private var transactionHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HISTORY")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(1.5)

            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(GlassTheme.textTertiary.opacity(0.4))

                Text("No redemptions yet")
                    .font(.satoshi(.regular, size: 13))
                    .foregroundStyle(GlassTheme.textTertiary)

                Text("Your transaction history will appear here after your first payout.")
                    .font(.satoshi(.regular, size: 11))
                    .foregroundStyle(GlassTheme.textTertiary.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .glassCard(cornerRadius: 16)
        }
    }

    private var lockedContent: some View {
        VStack(spacing: 20) {
            lockedHero
                .premiumStagger(appeared: appeared, index: 1)
            benefitsSection
                .premiumStagger(appeared: appeared, index: 2)
            okxCTA
                .premiumStagger(appeared: appeared, index: 3)
            faqSection
                .premiumStagger(appeared: appeared, index: 4)
        }
    }

    private var lockedHero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(GlassTheme.bgPrimary)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [GlassTheme.accent.opacity(pulseGlow ? 0.3 : 0.1), GlassTheme.accent.opacity(pulseGlow ? 0.15 : 0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: GlassTheme.accent.opacity(pulseGlow ? 0.1 : 0), radius: 20)

                Image(systemName: "building.columns")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(GlassTheme.textSecondary)
            }

            VStack(spacing: 8) {
                Text("Your Time Has Value")
                    .font(.satoshi(.bold, size: 22))
                    .foregroundStyle(GlassTheme.textPrimary)

                Text("The Time Bank lets you convert positive minutes into real rewards. Every healthy choice you make earns you closer to your next payout.")
                    .font(.satoshi(.regular, size: 14))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.vertical, 8)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WHAT YOU GET")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(1.5)

            VStack(spacing: 0) {
                benefitRow(icon: "dollarsign.circle", title: "Earn USDC", detail: "Convert positive minutes to USDC every month. 1 minute = $0.01.", isLast: false)
                benefitRow(icon: "crown", title: "1 Year FREE Premium", detail: "Full access to Costly Premium for an entire year, on us.", isLast: false)
                benefitRow(icon: "gift", title: "Exclusive Rewards", detail: "Early access to new features and bonus earning events.", isLast: false)
                benefitRow(icon: "chart.line.uptrend.xyaxis", title: "Track Your Earnings", detail: "Full dashboard with redemption history and payout tracking.", isLast: true)
            }
            .glassCard(cornerRadius: 16)
        }
    }

    private func benefitRow(icon: String, title: String, detail: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(GlassTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(GlassTheme.accent.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.satoshi(.medium, size: 14))
                        .foregroundStyle(GlassTheme.textPrimary)
                    Text(detail)
                        .font(.satoshi(.regular, size: 11))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)

            if !isLast {
                Rectangle()
                    .fill(GlassTheme.separator.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 56)
            }
        }
    }

    private var okxCTA: some View {
        Button {
            showOKXAlert = true
        } label: {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Text("OKX")
                        .font(.satoshi(.black, size: 15))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .frame(width: 46, height: 46)
                        .background(GlassTheme.bgPrimary)
                        .clipShape(.rect(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("UNLOCK THE TIME BANK")
                            .font(.satoshi(.black, size: 15))
                            .foregroundStyle(GlassTheme.textPrimary)
                        Text("Sign up with OKX to start earning")
                            .font(.satoshi(.regular, size: 12))
                            .foregroundStyle(GlassTheme.textTertiary)
                    }
                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Free OKX account")
                            .font(.satoshi(.medium, size: 12))
                            .foregroundStyle(GlassTheme.textSecondary)
                        Text("Takes less than 2 minutes")
                            .font(.satoshi(.regular, size: 10))
                            .foregroundStyle(GlassTheme.textTertiary)
                    }
                    Spacer()

                    HStack(spacing: 6) {
                        Text("Get Started")
                            .font(.satoshi(.bold, size: 14))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(GlassTheme.textPrimary)
                    .clipShape(.rect(cornerRadius: 12))
                }
            }
            .padding(18)
            .glassCard()
            .premiumShimmer()
        }
        .buttonStyle(PremiumCardButtonStyle())
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.6), trigger: showOKXAlert)
        .alert("Open OKX", isPresented: $showOKXAlert) {
            Button("Open OKX") {
                if let url = URL(string: "https://www.okx.com/join") {
                    UIApplication.shared.open(url)
                }
                store.redeemOKX()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll be redirected to OKX to create a free account. After signing up, return to Costly to unlock the Time Bank and your free year of Premium.")
        }
    }

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("FAQ")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(1.5)

            VStack(spacing: 0) {
                faqRow(question: "How do I earn minutes?", answer: "Log healthy activities like exercise, meditation, and nutritious meals. Each adds positive minutes to your balance.")
                faqDivider
                faqRow(question: "When can I redeem?", answer: "Redemptions open on the 1st of every month. Minimum balance of 100 minutes required.")
                faqDivider
                faqRow(question: "How is USDC paid out?", answer: "USDC is sent directly to your connected wallet within 24 hours of redemption.")
                faqDivider
                faqRow(question: "Is the OKX account free?", answer: "Yes. Creating an OKX account is completely free and takes less than 2 minutes.")
            }
            .glassCard(cornerRadius: 16)
        }
    }

    private func faqRow(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.satoshi(.medium, size: 13))
                .foregroundStyle(GlassTheme.textPrimary)
            Text(answer)
                .font(.satoshi(.regular, size: 11))
                .foregroundStyle(GlassTheme.textTertiary)
                .lineSpacing(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private var faqDivider: some View {
        Rectangle()
            .fill(GlassTheme.separator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 14)
    }
}
