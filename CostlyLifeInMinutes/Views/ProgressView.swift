import SwiftUI

struct LifeProgressView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var appeared: Bool = false
    @State private var animateProgress: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareImage: UIImage?
    @State private var ringPhase: CGFloat = 0

    private var totalGained: Int { store.totalMinutesGained }
    private var totalLost: Int { abs(store.totalMinutesLost) }
    private var netMinutes: Int { store.allTimeNetMinutes }
    private var todayNet: Int { store.todayNetMinutes + healthKit.healthMinutesBalance }

    private var costlyAge: Double {
        if healthKit.isAuthorized {
            return store.profile.costlyAge(
                netMinutes: store.allTimeNetMinutes,
                healthMinutes: healthKit.healthMinutesBalance,
                steps: healthKit.stepCount,
                sleepHours: healthKit.sleepHours,
                activeMinutes: healthKit.activeMinutes
            )
        }
        return store.profile.baselineCostlyAge
    }

    private var streakDays: Int {
        var count = 0
        let calendar = Calendar.current
        var checkDate = Date.now
        for _ in 0..<365 {
            let dayEntries = store.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            let dayNet = dayEntries.reduce(0) { $0 + $1.minutesDelta }
            if dayNet > 0 {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return count
    }

    private var weeklyData: [(day: String, net: Int)] {
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today) ?? today
        let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? today
            let dayEntries = store.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let net = dayEntries.reduce(0) { $0 + $1.minutesDelta }
            return (dayLetters[offset], net)
        }
    }

    private var progressFraction: Double {
        let total = Double(totalGained + totalLost)
        guard total > 0 else { return 0.5 }
        return Double(totalGained) / total
    }

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                        .padding(.top, 8)
                        .premiumStagger(appeared: appeared, index: 0)

                    heroRing
                        .premiumStagger(appeared: appeared, index: 1)

                    todayBalance
                        .premiumStagger(appeared: appeared, index: 2)

                    if healthKit.isAuthorized {
                        healthMetrics
                            .premiumStagger(appeared: appeared, index: 3)
                    }

                    weeklyActivity
                        .premiumStagger(appeared: appeared, index: 4)

                    lifeStats
                        .premiumStagger(appeared: appeared, index: 5)

                    milestones
                        .premiumStagger(appeared: appeared, index: 6)

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.spring(response: 1.4, dampingFraction: 0.7).delay(0.3)) { animateProgress = true }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Progress")
                    .font(.satoshi(.bold, size: 28))
                    .foregroundStyle(GlassTheme.textPrimary)
                Text(store.profile.name.isEmpty ? "Your journey" : "\(store.profile.name)'s journey")
                    .font(.satoshi(.regular, size: 13))
                    .foregroundStyle(GlassTheme.textTertiary)
            }
            Spacer()
            if streakDays > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.2))
                    Text("\(streakDays)")
                        .font(.satoshi(.bold, size: 13))
                        .foregroundStyle(GlassTheme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 4)
    }

    private var heroRing: some View {
        let ringSize: CGFloat = 200

        return VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(GlassTheme.separator.opacity(0.4), lineWidth: 1)
                    .frame(width: ringSize + 40, height: ringSize + 40)

                Circle()
                    .stroke(GlassTheme.separator.opacity(0.2), lineWidth: 0.5)
                    .frame(width: ringSize + 64, height: ringSize + 64)

                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(GlassTheme.separator.opacity(0.5), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: 0, to: animateProgress ? progressFraction : 0)
                    .stroke(
                        LinearGradient(
                            colors: [GlassTheme.accent.opacity(0.4), GlassTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))

                let endAngle = Angle.degrees(-90 + progressFraction * 360)
                Circle()
                    .fill(GlassTheme.accent)
                    .frame(width: 8, height: 8)
                    .shadow(color: GlassTheme.accent.opacity(0.4), radius: 6)
                    .offset(
                        x: cos(endAngle.radians) * (ringSize / 2),
                        y: sin(endAngle.radians) * (ringSize / 2)
                    )
                    .opacity(animateProgress ? 1 : 0)

                VStack(spacing: 6) {
                    Text(formatNet(netMinutes))
                        .font(.satoshi(.light, size: 48))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .contentTransition(.numericText())
                        .monospacedDigit()

                    Text("NET MINUTES")
                        .font(.satoshi(.medium, size: 9))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .tracking(3)
                }
            }

            HStack(spacing: 32) {
                VStack(spacing: 3) {
                    Text("+\(totalGained)")
                        .font(.satoshi(.medium, size: 18))
                        .foregroundStyle(GlassTheme.positive)
                        .monospacedDigit()
                    Text("gained")
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                Rectangle()
                    .fill(GlassTheme.separator)
                    .frame(width: 0.5, height: 28)

                VStack(spacing: 3) {
                    Text("−\(totalLost)")
                        .font(.satoshi(.medium, size: 18))
                        .foregroundStyle(GlassTheme.negative)
                        .monospacedDigit()
                    Text("lost")
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
            }
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
    }

    private var todayBalance: some View {
        VStack(spacing: 14) {
            HStack {
                Text("TODAY")
                    .font(.satoshi(.medium, size: 9))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(2)
                Spacer()
                Text(formatNet(todayNet))
                    .font(.satoshi(.bold, size: 20))
                    .foregroundStyle(GlassTheme.minuteColor(todayNet))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            GeometryReader { geometry in
                let width = geometry.size.width
                let todayGained = store.todayEntries.filter { $0.minutesDelta > 0 }.reduce(0) { $0 + $1.minutesDelta }
                let todayLostAbs = abs(store.todayEntries.filter { $0.minutesDelta < 0 }.reduce(0) { $0 + $1.minutesDelta })
                let healthBonus = max(healthKit.healthMinutesBalance, 0)
                let effectiveGained = todayGained + healthBonus
                let total = max(effectiveGained + todayLostAbs, 1)
                let gainedWidth = CGFloat(effectiveGained) / CGFloat(total) * width

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(GlassTheme.separator.opacity(0.5))
                        .frame(height: 4)

                    Capsule()
                        .fill(GlassTheme.accent.opacity(animateProgress ? 0.7 : 0))
                        .frame(width: animateProgress ? max(gainedWidth, 4) : 0, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(18)
        .glassCard(cornerRadius: 18)
    }

    private var healthMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEALTH")
                .font(.satoshi(.medium, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(2)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                metricRow(icon: "figure.walk", label: "Steps", value: "\(healthKit.stepCount)")
                metricDivider
                metricRow(icon: "flame", label: "Active Minutes", value: "\(healthKit.activeMinutes) min")
                if healthKit.sleepHours > 0 {
                    metricDivider
                    metricRow(icon: "moon.fill", label: "Sleep", value: String(format: "%.1f hrs", healthKit.sleepHours))
                }
                if healthKit.heartRate > 0 {
                    metricDivider
                    metricRow(icon: "heart.fill", label: "Heart Rate", value: "\(Int(healthKit.heartRate)) bpm")
                }
                if healthKit.distanceKm > 0 {
                    metricDivider
                    metricRow(icon: "point.bottomleft.forward.to.point.topright.scurvepath", label: "Distance", value: String(format: "%.1f km", healthKit.distanceKm))
                }
                if healthKit.caloriesBurned > 0 {
                    metricDivider
                    metricRow(icon: "bolt", label: "Calories", value: "\(healthKit.caloriesBurned) kcal")
                }
            }
            .glassCard(cornerRadius: 18)
        }
    }

    private func metricRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(GlassTheme.accent)
                .frame(width: 20)

            Text(label)
                .font(.satoshi(.regular, size: 14))
                .foregroundStyle(GlassTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.satoshi(.medium, size: 14))
                .foregroundStyle(GlassTheme.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(GlassTheme.separator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 50)
    }

    private var weeklyActivity: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("THIS WEEK")
                    .font(.satoshi(.medium, size: 9))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(2)
                Spacer()
                Text(formatNet(store.weekNetMinutes))
                    .font(.satoshi(.medium, size: 14))
                    .foregroundStyle(GlassTheme.minuteColor(store.weekNetMinutes))
                    .monospacedDigit()
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 6) {
                        Spacer()

                        let maxVal = max(weeklyData.map { abs($0.net) }.max() ?? 1, 1)
                        let barHeight = max(CGFloat(abs(data.net)) / CGFloat(maxVal) * 50, 3)
                        let isPositive = data.net >= 0

                        RoundedRectangle(cornerRadius: 3)
                            .fill(isPositive ? GlassTheme.accent : GlassTheme.separator)
                            .frame(height: animateProgress ? barHeight : 3)

                        Text(data.day)
                            .font(.satoshi(.medium, size: 9))
                            .foregroundStyle(GlassTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding(18)
        .glassCard(cornerRadius: 18)
    }

    private var lifeStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFETIME")
                .font(.satoshi(.medium, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(2)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                statRow(label: "Costly Age", value: String(format: "%.1f", costlyAge))
                metricDivider
                statRow(label: "Chronological Age", value: String(format: "%.1f", store.profile.preciseAge))
                metricDivider

                let days = Double(store.allTimeNetMinutes) / 1440.0
                statRow(
                    label: days >= 0 ? "Days Added" : "Days Removed",
                    value: String(format: "%+.1f", days)
                )
                metricDivider

                let remaining = store.profile.estimatedLifeMinutesRemaining
                statRow(label: "Est. Life Remaining", value: formatLargeMinutes(remaining))
            }
            .glassCard(cornerRadius: 18)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.satoshi(.regular, size: 14))
                .foregroundStyle(GlassTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.satoshi(.medium, size: 14))
                .foregroundStyle(GlassTheme.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MILESTONES")
                .font(.satoshi(.medium, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(2)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                milestoneRow(title: "First Log", detail: "Log your first activity", achieved: !store.entries.isEmpty, isLast: false)
                milestoneRow(title: "3-Day Streak", detail: "3 consecutive positive days", achieved: streakDays >= 3, isLast: false)
                milestoneRow(title: "100 Minutes", detail: "Accumulate 100+ positive minutes", achieved: totalGained >= 100, isLast: false)
                milestoneRow(title: "Week Warrior", detail: "7 consecutive positive days", achieved: streakDays >= 7, isLast: true)
            }
            .glassCard(cornerRadius: 18)
        }
    }

    private func milestoneRow(title: String, detail: String, achieved: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Circle()
                    .fill(achieved ? GlassTheme.accent : GlassTheme.separator)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.satoshi(.medium, size: 14))
                        .foregroundStyle(achieved ? GlassTheme.textPrimary : GlassTheme.textTertiary)
                    Text(detail)
                        .font(.satoshi(.regular, size: 11))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                Spacer()

                if achieved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GlassTheme.accent)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            if !isLast {
                Rectangle()
                    .fill(GlassTheme.separator.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 40)
            }
        }
    }

    private func formatNet(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\(value)" }
        return "0"
    }

    private func formatLargeMinutes(_ minutes: Int) -> String {
        let years = minutes / 525960
        let remainingMonths = (minutes % 525960) / 43830
        return "\(years)y \(remainingMonths)m"
    }
}
